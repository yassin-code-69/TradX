import { withTransaction } from '../../db/client.ts';

export interface OutboxEventRow {
  id: number;
  event_id: string;
  event_type: string;
  aggregate_type: string;
  aggregate_id: string;
  payload: Record<string, unknown> | string;
}

export async function processOutboxEvents(): Promise<number> {
  try {
    return await withTransaction(async (client) => {
      const res = await client.query<OutboxEventRow>(
        `SELECT id, event_id, event_type, aggregate_type, aggregate_id, payload
         FROM outbox_events
         WHERE status = 'PENDING' AND available_at <= now()
         ORDER BY id ASC
         LIMIT 10
         FOR UPDATE SKIP LOCKED`
      );

      if (res.rows.length === 0) {
        return 0;
      }

      for (const row of res.rows) {
        // Mark as processed
        await client.query(
          `UPDATE outbox_events SET status = 'PROCESSED', processed_at = now() WHERE id = $1`,
          [row.id]
        );
      }

      return res.rows.length;
    });
  } catch (err) {
    console.error('Failed to process outbox events:', {
      error: err instanceof Error ? err.message : String(err),
      stack: err instanceof Error ? err.stack : undefined,
    });
    return 0;
  }
}

