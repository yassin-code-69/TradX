import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import pg, { type PoolClient, type QueryResult, type QueryResultRow } from 'pg';
import { config } from '../config/index.ts';

const { Pool } = pg;

export type DbClient = PoolClient | pg.Pool;

// ==========================================
// 1. Supabase Clients
// ==========================================

/**
 * Supabase Admin client with service_role key.
 * Used for backend trusted operations, user management, and bypassing RLS when required.
 */
export const supabaseAdmin: SupabaseClient = createClient(
  config.SUPABASE_URL,
  config.SUPABASE_SERVICE_ROLE_KEY,
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  }
);

/**
 * Supabase Public/Anon client.
 * Used for public verification and operations requiring standard user context.
 */
export const supabaseAnon: SupabaseClient = createClient(
  config.SUPABASE_URL,
  config.SUPABASE_ANON_KEY,
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  }
);

/**
 * Create a scoped Supabase client with the caller's JWT token.
 * Used when executing operations scoped to the user's RLS policies.
 */
export function createUserSupabaseClient(accessToken: string): SupabaseClient {
  return createClient(config.SUPABASE_URL, config.SUPABASE_ANON_KEY, {
    global: {
      headers: {
        Authorization: `Bearer ${accessToken}`,
      },
    },
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  });
}

// ==========================================
// 2. PostgreSQL Connection Pool & Helpers
// ==========================================

export const dbPool = new Pool({
  connectionString: config.DATABASE_URL,
  max: config.DATABASE_MAX_CONNECTIONS,
  idleTimeoutMillis: config.DATABASE_IDLE_TIMEOUT_MS,
  connectionTimeoutMillis: config.DATABASE_CONNECTION_TIMEOUT_MS,
});

dbPool.on('error', (err) => {
  console.error('Unexpected PostgreSQL pool client error:', err);
});

export const pool = dbPool;

/**
 * Helper to get a dedicated pool client.
 */
export async function getClient(): Promise<PoolClient> {
  return dbPool.connect();
}

/**
 * Helper to execute a parameterized SQL query on the pool.
 */
export async function query<T extends QueryResultRow = any>(
  text: string,
  params?: any[]
): Promise<QueryResult<T>> {
  const start = Date.now();
  try {
    const res = await dbPool.query<T>(text, params);
    return res;
  } catch (error) {
    console.error('Database query error:', {
      text,
      params,
      error: error instanceof Error ? error.message : error,
      durationMs: Date.now() - start,
    });
    throw error;
  }
}

/**
 * Transaction helper for ensuring ACID transactional integrity.
 * Executes a callback within a managed transaction (BEGIN, COMMIT, ROLLBACK).
 */
export async function withTransaction<T>(
  callback: (client: PoolClient) => Promise<T>
): Promise<T> {
  const client = await dbPool.connect();
  try {
    await client.query('BEGIN');
    const result = await callback(client);
    await client.query('COMMIT');
    return result;
  } catch (error) {
    try {
      await client.query('ROLLBACK');
    } catch (rollbackError) {
      console.error('Error rolling back transaction:', rollbackError);
    }
    throw error;
  } finally {
    client.release();
  }
}

/**
 * Health check helper for DB connections.
 */
export async function checkDbHealth(): Promise<{
  database: boolean;
  supabase: boolean;
  latencyMs: number;
  error?: string;
}> {
  const start = Date.now();
  let dbOk = false;
  let supabaseOk = false;
  let errorMsg: string | undefined;

  try {
    const res = await dbPool.query('SELECT 1 as alive');
    dbOk = res.rows.length > 0 && (res.rows[0]?.alive === 1 || res.rows[0]?.alive === '1');
  } catch (err: any) {
    errorMsg = `DB error: ${err?.message || err}`;
  }

  try {
    const { error } = await supabaseAdmin.auth.getSession();
    supabaseOk = !error;
  } catch (err: any) {
    errorMsg = errorMsg ? `${errorMsg}; Supabase error: ${err?.message || err}` : `Supabase error: ${err?.message || err}`;
  }

  return {
    database: dbOk,
    supabase: supabaseOk,
    latencyMs: Date.now() - start,
    error: errorMsg,
  };
}

/**
 * Initialize database connectivity and verify connection.
 */
export async function initDb(): Promise<void> {
  const health = await checkDbHealth();
  if (!health.database) {
    console.warn('⚠️ Database connection check failed on startup:', health.error);
  } else {
    console.log(`✅ Database connection pool initialized (latency: ${health.latencyMs}ms)`);
  }
}

/**
 * Close database connection pool gracefully.
 */
export async function closeDb(): Promise<void> {
  await dbPool.end();
}
