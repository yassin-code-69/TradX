import crypto from 'crypto';
import type { DbClient } from '../db/client.ts';
import { query } from '../db/client.ts';
import { ConflictError } from '../utils/errors.ts';

export interface IdempotencyRecord {
  id: string;
  responseStatus: number;
  responseBody: any;
}

export function computeRequestHash(payload: unknown): string {
  const normalized = JSON.stringify(payload || {});
  return crypto.createHash('sha256').update(normalized).digest('hex');
}

/**
 * Checks if an idempotency key was already used for a given user & operation.
 */
export async function checkIdempotency(
  userId: string,
  operation: string,
  key: string,
  payload: unknown,
  client?: DbClient
): Promise<IdempotencyRecord | null> {
  const runner = client ? client.query.bind(client) : query;
  const hash = computeRequestHash(payload);

  const res = await runner(
    `SELECT id, request_hash, response_status, response_body, expires_at
     FROM idempotency_keys
     WHERE user_id = $1 AND operation = $2 AND key = $3`,
    [userId, operation, key]
  );

  if (res.rows.length > 0) {
    const row = res.rows[0];
    if (row.request_hash !== hash) {
      throw new ConflictError(
        'DUPLICATE_REQUEST',
        'Idempotency key has already been used with a different request payload'
      );
    }
    return {
      id: row.id,
      responseStatus: row.response_status,
      responseBody: row.response_body,
    };
  }

  return null;
}

/**
 * Saves the response against the idempotency key.
 */
export async function saveIdempotency(
  userId: string,
  operation: string,
  key: string,
  payload: unknown,
  responseStatus: number,
  responseBody: unknown,
  client?: DbClient
): Promise<void> {
  const runner = client ? client.query.bind(client) : query;
  const hash = computeRequestHash(payload);

  await runner(
    `INSERT INTO idempotency_keys (user_id, operation, key, request_hash, response_status, response_body)
     VALUES ($1, $2, $3, $4, $5, $6)
     ON CONFLICT (user_id, operation, key) DO UPDATE
     SET response_status = EXCLUDED.response_status,
         response_body = EXCLUDED.response_body`,
    [userId, operation, key, hash, responseStatus, JSON.stringify(responseBody)]
  );
}
