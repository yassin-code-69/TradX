import { query, withTransaction } from '../../db/index.ts';
import { winnersService, type Winner } from '../winners/winners.service.ts';
import { drawsService, type Draw } from '../draws/draws.service.ts';

export interface DrawResult {
  id: number;
  public_id: string;
  draw_id: number;
  draw_public_id?: string;
  draw_type_code?: string;
  draw_type_name?: string;
  draw_sequence_number?: string;
  winning_number: string;
  result_hash?: string | null;
  published_by?: string | null;
  published_at: string;
  created_at: string;
  total_tickets?: number;
  total_sales_minor?: string | number;
  winners_count?: number;
  total_prize_paid_minor?: string | number;
}

export interface PublishResultInput {
  draw_id: number | string;
  winning_number: string;
  result_hash?: string;
}

export interface DrawResultDetails extends DrawResult {
  draw: Draw;
  winners: Winner[];
  breakdown: Array<{
    prize_name: string;
    match_type: string;
    prize_amount_minor: string | number;
    count: number;
    total_amount_minor: string | number;
  }>;
}

export class ResultsService {
  /**
   * Get list of published results
   */
  async getResults(filters?: {
    draw_type?: string;
    limit?: number;
    offset?: number;
  }): Promise<{ results: DrawResult[]; total: number }> {
    const params: unknown[] = [];
    const conditions: string[] = [];

    if (filters?.draw_type) {
      params.push(filters.draw_type.toUpperCase());
      conditions.push(`dt.code = $${params.length}`);
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';
    const limit = Math.min(filters?.limit ?? 20, 100);
    const offset = filters?.offset ?? 0;

    const countSql = `
      SELECT COUNT(*) as count
      FROM draw_results dr
      JOIN draws d ON dr.draw_id = d.id
      JOIN draw_types dt ON d.draw_type_id = dt.id
      ${whereClause}
    `;
    const countRes = await query<{ count: string }>(countSql, params);
    const total = parseInt(countRes.rows[0]?.count || '0', 10);

    const listSql = `
      SELECT 
        dr.id,
        dr.public_id,
        dr.draw_id,
        d.public_id AS draw_public_id,
        dt.code AS draw_type_code,
        dt.name AS draw_type_name,
        d.sequence_number AS draw_sequence_number,
        dr.winning_number,
        dr.result_hash,
        dr.published_by,
        dr.published_at,
        dr.created_at,
        d.total_tickets,
        d.total_sales_minor,
        (SELECT COUNT(*) FROM winners w WHERE w.draw_id = dr.draw_id) as winners_count,
        COALESCE((SELECT SUM(w.winning_amount_minor) FROM winners w WHERE w.draw_id = dr.draw_id), 0) as total_prize_paid_minor
      FROM draw_results dr
      JOIN draws d ON dr.draw_id = d.id
      JOIN draw_types dt ON d.draw_type_id = dt.id
      ${whereClause}
      ORDER BY dr.published_at DESC
      LIMIT $${params.length + 1} OFFSET $${params.length + 2}
    `;

    const res = await query<DrawResult>(listSql, [...params, limit, offset]);

    return {
      results: res.rows,
      total,
    };
  }

  /**
   * Get specific draw result with winning breakdown
   */
  async getResultByDrawId(drawIdOrPublicId: string | number): Promise<DrawResultDetails | null> {
    const isNumeric = !isNaN(Number(drawIdOrPublicId)) && !String(drawIdOrPublicId).includes('-');
    const condition = isNumeric ? 'd.id = $1' : 'd.public_id = $1';

    const sql = `
      SELECT 
        dr.id,
        dr.public_id,
        dr.draw_id,
        d.public_id AS draw_public_id,
        dt.code AS draw_type_code,
        dt.name AS draw_type_name,
        d.sequence_number AS draw_sequence_number,
        dr.winning_number,
        dr.result_hash,
        dr.published_by,
        dr.published_at,
        dr.created_at,
        d.total_tickets,
        d.total_sales_minor
      FROM draw_results dr
      JOIN draws d ON dr.draw_id = d.id
      JOIN draw_types dt ON d.draw_type_id = dt.id
      WHERE ${condition}
    `;

    const res = await query<DrawResult>(sql, [drawIdOrPublicId]);
    const result = res.rows[0];
    if (!result) return null;

    const draw = await drawsService.getDrawById(result.draw_id);
    if (!draw) return null;

    // Fetch winners
    const winnersSql = `
      SELECT 
        w.id,
        w.public_id,
        w.draw_id,
        w.ticket_id,
        w.user_id,
        w.prize_rule_id,
        w.winning_amount_minor,
        w.status,
        w.created_at,
        w.paid_at,
        t.selected_number AS ticket_number,
        pr.name AS prize_name,
        pr.match_type
      FROM winners w
      JOIN tickets t ON w.ticket_id = t.id
      LEFT JOIN prize_rules pr ON w.prize_rule_id = pr.id
      WHERE w.draw_id = $1
      ORDER BY w.winning_amount_minor DESC, w.id ASC
    `;
    const winnersRes = await query<Winner>(winnersSql, [result.draw_id]);
    const winners = winnersRes.rows;

    // Aggregate breakdown by prize/match type
    const breakdownMap = new Map<string, {
      prize_name: string;
      match_type: string;
      prize_amount_minor: string | number;
      count: number;
      total_amount_minor: bigint;
    }>();

    for (const w of winners) {
      const key = `${w.prize_name || 'Tier'}-${w.winning_amount_minor}`;
      const existing = breakdownMap.get(key);
      const amount = BigInt(w.winning_amount_minor);
      if (existing) {
        existing.count += 1;
        existing.total_amount_minor += amount;
      } else {
        breakdownMap.set(key, {
          prize_name: w.prize_name || 'Prize Winner',
          match_type: w.match_type || 'MATCH',
          prize_amount_minor: w.winning_amount_minor,
          count: 1,
          total_amount_minor: amount,
        });
      }
    }

    const breakdown = Array.from(breakdownMap.values()).map((b) => ({
      ...b,
      total_amount_minor: b.total_amount_minor.toString(),
    }));

    return {
      ...result,
      draw,
      winners,
      breakdown,
      winners_count: winners.length,
      total_prize_paid_minor: winners.reduce((sum, w) => sum + BigInt(w.winning_amount_minor), 0n).toString(),
    };
  }

  /**
   * Publish result for a draw, trigger winner calculation, and distribute payouts atomically
   */
  async publishResult(adminUserId: string, input: PublishResultInput) {
    const { draw_id, winning_number, result_hash } = input;

    const draw = await drawsService.getDrawById(draw_id);
    if (!draw) {
      throw new Error('Draw not found');
    }

    // Validate winning number format preserving leading zeros
    const expectedDigitLength = draw.digit_length || (draw.draw_type_code === 'MEGA' ? 7 : 3);
    const cleanWinningNumber = String(winning_number).trim();

    if (!/^\d+$/.test(cleanWinningNumber)) {
      throw new Error('Winning number must contain digits only');
    }

    if (cleanWinningNumber.length !== expectedDigitLength) {
      throw new Error(`Winning number must be exactly ${expectedDigitLength} digits (e.g. "${'0'.repeat(expectedDigitLength - 1)}1")`);
    }

    return await withTransaction(async (client) => {
      // Check if result already published
      const existingResult = await client.query<{ id: number }>(
        'SELECT id FROM draw_results WHERE draw_id = $1 FOR UPDATE',
        [draw.id]
      );
      if (existingResult.rows[0]) {
        throw new Error('Result for this draw has already been published');
      }

      // Update draw status to PROCESSING
      await client.query("UPDATE draws SET status = 'PROCESSING', updated_at = NOW() WHERE id = $1", [draw.id]);

      // Record draw result
      const insertResultSql = `
        INSERT INTO draw_results (
          public_id, draw_id, winning_number, result_hash, published_by, published_at, created_at
        ) VALUES (
          gen_random_uuid(), $1, $2, $3, $4, NOW(), NOW()
        ) RETURNING *
      `;
      const resultRes = await client.query<DrawResult>(insertResultSql, [
        draw.id,
        cleanWinningNumber,
        result_hash || null,
        adminUserId,
      ]);

      // Process winners calculation and payout within the same transaction
      const winnerStats = await winnersService.processDrawWinners(draw.id, cleanWinningNumber, adminUserId, client);

      // Complete the draw
      await client.query("UPDATE draws SET status = 'COMPLETED', updated_at = NOW() WHERE id = $1", [draw.id]);

      return {
        result: resultRes.rows[0],
        stats: winnerStats,
      };
    });
  }
}

export const resultsService = new ResultsService();

