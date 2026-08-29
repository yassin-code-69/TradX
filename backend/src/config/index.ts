import { z } from 'zod';
import dotenv from 'dotenv';

// Load .env file if present
dotenv.config();

const envSchema = z.object({
  // Server
  PORT: z.coerce.number().default(4000),
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  API_PREFIX: z.string().default('/api/v1'),
  CORS_ORIGIN: z.string().default('*'),

  // Supabase
  SUPABASE_URL: z.string().default('https://mqrtqldebapvllidkcgs.supabase.co'),
  SUPABASE_ANON_KEY: z.string().default('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1xcnRxbGRlYmFwdmxsaWRrY2dzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc1OTM0MzIsImV4cCI6MjEwMzE2OTQzMn0.IbAeuC_rdcAjgdL5-0WlfuBEPKzK6bRmP4peh9JMp8A'),
  SUPABASE_SERVICE_ROLE_KEY: z.string().default('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1xcnRxbGRlYmFwdmxsaWRrY2dzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc1OTM0MzIsImV4cCI6MjEwMzE2OTQzMn0.IbAeuC_rdcAjgdL5-0WlfuBEPKzK6bRmP4peh9JMp8A'),
  SUPABASE_JWT_SECRET: z.string().default('tradex-super-secret-jwt-key-for-development-change-in-prod'),

  // PostgreSQL Database
  DATABASE_URL: z.string().default('postgresql://postgres:postgres@127.0.0.1:54322/postgres'),
  DATABASE_MAX_CONNECTIONS: z.coerce.number().default(20),
  DATABASE_IDLE_TIMEOUT_MS: z.coerce.number().default(30000),
  DATABASE_CONNECTION_TIMEOUT_MS: z.coerce.number().default(process.env.NODE_ENV === 'test' ? 300 : 2000),

  // Business Defaults
  DEFAULT_CURRENCY: z.string().default('BDT'),
});

const parsedEnv = envSchema.parse({
  PORT: process.env.PORT,
  NODE_ENV: process.env.NODE_ENV,
  API_PREFIX: process.env.API_PREFIX,
  CORS_ORIGIN: process.env.CORS_ORIGIN,
  SUPABASE_URL: process.env.SUPABASE_URL || process.env.VITE_SUPABASE_URL,
  SUPABASE_ANON_KEY: process.env.SUPABASE_ANON_KEY || process.env.VITE_SUPABASE_ANON_KEY,
  SUPABASE_SERVICE_ROLE_KEY: process.env.SUPABASE_SERVICE_ROLE_KEY,
  SUPABASE_JWT_SECRET: process.env.SUPABASE_JWT_SECRET || process.env.JWT_SECRET,
  DATABASE_URL: process.env.DATABASE_URL || process.env.SUPABASE_DB_URL,
  DATABASE_MAX_CONNECTIONS: process.env.DATABASE_MAX_CONNECTIONS,
  DATABASE_IDLE_TIMEOUT_MS: process.env.DATABASE_IDLE_TIMEOUT_MS,
  DATABASE_CONNECTION_TIMEOUT_MS: process.env.DATABASE_CONNECTION_TIMEOUT_MS,
  DEFAULT_CURRENCY: process.env.DEFAULT_CURRENCY,
});

export const config = {
  // Uppercase props
  PORT: parsedEnv.PORT,
  NODE_ENV: parsedEnv.NODE_ENV,
  API_PREFIX: parsedEnv.API_PREFIX,
  CORS_ORIGIN: parsedEnv.CORS_ORIGIN,
  SUPABASE_URL: parsedEnv.SUPABASE_URL,
  SUPABASE_ANON_KEY: parsedEnv.SUPABASE_ANON_KEY,
  SUPABASE_SERVICE_ROLE_KEY: parsedEnv.SUPABASE_SERVICE_ROLE_KEY,
  SUPABASE_JWT_SECRET: parsedEnv.SUPABASE_JWT_SECRET,
  DATABASE_URL: parsedEnv.DATABASE_URL,
  DATABASE_MAX_CONNECTIONS: parsedEnv.DATABASE_MAX_CONNECTIONS,
  DATABASE_IDLE_TIMEOUT_MS: parsedEnv.DATABASE_IDLE_TIMEOUT_MS,
  DATABASE_CONNECTION_TIMEOUT_MS: parsedEnv.DATABASE_CONNECTION_TIMEOUT_MS,
  DEFAULT_CURRENCY: parsedEnv.DEFAULT_CURRENCY,

  // camelCase compatibility aliases
  port: parsedEnv.PORT,
  nodeEnv: parsedEnv.NODE_ENV,
  apiPrefix: parsedEnv.API_PREFIX,
  corsOrigin: parsedEnv.CORS_ORIGIN,
  supabaseUrl: parsedEnv.SUPABASE_URL,
  supabaseAnonKey: parsedEnv.SUPABASE_ANON_KEY,
  supabaseServiceRoleKey: parsedEnv.SUPABASE_SERVICE_ROLE_KEY,
  jwtSecret: parsedEnv.SUPABASE_JWT_SECRET,
  databaseUrl: parsedEnv.DATABASE_URL,
  defaultCurrency: parsedEnv.DEFAULT_CURRENCY,
  isDev: parsedEnv.NODE_ENV === 'development',
  isProd: parsedEnv.NODE_ENV === 'production',
  isTest: parsedEnv.NODE_ENV === 'test',
};
