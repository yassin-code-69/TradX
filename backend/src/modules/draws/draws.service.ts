import { query, withTransaction } from '../../db/index.ts';

export type DrawStatusCode = 'DRAFT' | 'SCHEDULED' | 'OPEN' | 'CLOSED' | 'PROCESSING' | 'COMPLETED' | 'CANCELLED';

export interface DrawType {
  id: number;
  code: 'MEGA' | 'DAILY' | 'HOURLY' | string;
  name: string;
  digit_length: number;
  default_ticket_price_minor: string | number;
  status: string;
  created_at: string;
  updated_at: string;
}

export interface PrizeRule {
  id: number;
  draw_type_id: number;
  name: string;
  match_type: string;
  prize_amount_minor: string | number;
  priority: number;
  status: string;
}

export interface Draw {
  id: number;
  public_id: string;
  draw_type_id: number;
  draw_type_code?: string;
  draw_type_name?: string;
  digit_length?: number;
  sequence_number: string;
  ticket_price_minor: string | number;
  sale_open_at: string;
  sale_close_at: string;
  draw_at: string;
  status: DrawStatusCode;
  total_tickets: number;
  total_sales_minor: string | number;
  created_by?: string | null;
  created_at: string;
  updated_at: string;
  winning_number?: string | null;
  prize_rules?: PrizeRule[];
}

export interface CreateDrawDTO {
  draw_type_id?: number;
  draw_type_code?: string;
  sequence_number?: string;
  ticket_price_minor?: number | string;
  sale_open_at: string;
  sale_close_at: string;
  draw_at: string;
  status?: DrawStatusCode;
}

const VALID_TRANSITIONS: Record<DrawStatusCode, DrawStatusCode[]> = {
  DRAFT: ['SCHEDULED', 'OPEN', 'CANCELLED'],
  SCHEDULED: ['OPEN', 'CANCELLED'],
  OPEN: ['CLOSED', 'CANCELLED'],
  CLOSED: ['PROCESSING', 'CANCELLED'],
  PROCESSING: ['COMPLETED', 'CANCELLED'],
  COMPLETED: [],
  CANCELLED: [],
};

export class DrawsService {
  /**
   * List active or upcoming draws (Mega, Daily, Hourly) with optional filters
   */
  async getDraws(filters?: {
    draw_type?: string;
    status?: string;
    limit?: number;
    offset?: number;
  }): Promise<{ draws: Draw[]; total: number }> {
    const params: unknown[] = [];
    const conditions: string[] = [];

    if (filters?.draw_type) {
      params.push(filters.draw_type.toUpperCase());
      conditions.push(`(dt.code = $${params.length} OR d.draw_type_id::text = $${params.length})`);
    }

    if (filters?.status) {
      params.push(filters.status.toUpperCase());
      conditions.push(`d.status = $${params.length}`);
    } else {
      // Default to showing OPEN, SCHEDULED, and recently CLOSED
      conditions.push(`d.status IN ('OPEN', 'SCHEDULED', 'CLOSED', 'PROCESSING')`);
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';
    const limit = Math.min(filters?.limit ?? 50, 100);
    const offset = filters?.offset ?? 0;

    const countSql = `
      SELECT COUNT(*) as count 
      FROM draws d
      LEFT JOIN draw_types dt ON d.draw_type_id = dt.id
      ${whereClause}
    `;
    const countRes = await query<{ count: string }>(countSql, params);
    const total = parseInt(countRes.rows[0]?.count || '0', 10);

    const listSql = `
      SELECT 
        d.id,
        d.public_id,
        d.draw_type_id,
        dt.code AS draw_type_code,
        dt.name AS draw_type_name,
        dt.digit_length,
        d.sequence_number,
        d.ticket_price_minor,
        d.sale_open_at,
        d.sale_close_at,
        d.draw_at,
        d.status,
        d.total_tickets,
        d.total_sales_minor,
        d.created_by,
        d.created_at,
        d.updated_at,
        dr.winning_number
      FROM draws d
      LEFT JOIN draw_types dt ON d.draw_type_id = dt.id
      LEFT JOIN draw_results dr ON d.id = dr.draw_id
      ${whereClause}
      ORDER BY 
        CASE d.status 
          WHEN 'OPEN' THEN 1 
          WHEN 'SCHEDULED' THEN 2 
          WHEN 'CLOSED' THEN 3 
          WHEN 'PROCESSING' THEN 4 
          ELSE 5 
        END,
        d.draw_at ASC
      LIMIT $${params.length + 1} OFFSET $${params.length + 2}
    `;

    const drawsRes = await query<Draw>(listSql, [...params, limit, offset]);

    return {
      draws: drawsRes.rows,
      total,
    };
  }

  /**
   * Get single draw details by ID or public UUID
   */
  async getDrawById(idOrPublicId: string | number): Promise<Draw | null> {
    const isNumeric = !isNaN(Number(idOrPublicId)) && !String(idOrPublicId).includes('-');
    const condition = isNumeric ? 'd.id = $1' : 'd.public_id = $1';

    const drawSql = `
      SELECT 
        d.id,
        d.public_id,
        d.draw_type_id,
        dt.code AS draw_type_code,
        dt.name AS draw_type_name,
        dt.digit_length,
        d.sequence_number,
        d.ticket_price_minor,
        d.sale_open_at,
        d.sale_close_at,
        d.draw_at,
        d.status,
        d.total_tickets,
        d.total_sales_minor,
        d.created_by,
        d.created_at,
        d.updated_at,
        dr.winning_number
      FROM draws d
      LEFT JOIN draw_types dt ON d.draw_type_id = dt.id
      LEFT JOIN draw_results dr ON d.id = dr.draw_id
      WHERE ${condition}
    `;

    const result = await query<Draw>(drawSql, [idOrPublicId]);
    if (!result.rows[0]) return null;

    const draw = result.rows[0];

    // Fetch prize rules for this draw type
    const prizeRulesSql = `
      SELECT id, draw_type_id, name, match_type, prize_amount_minor, priority, status
      FROM prize_rules
      WHERE draw_type_id = $1 AND status = 'ACTIVE'
      ORDER BY priority ASC, prize_amount_minor DESC
    `;
    const prizeRulesRes = await query<PrizeRule>(prizeRulesSql, [draw.draw_type_id]);
    draw.prize_rules = prizeRulesRes.rows;

    return draw;
  }

  /**
   * Create a new draw
   */
  async createDraw(dto: CreateDrawDTO, createdByUserId?: string): Promise<Draw> {
    // Resolve draw type ID
    let drawTypeId = dto.draw_type_id;
    let defaultPrice = 1000; // 10.00 BDT default
    let digitLength = 3;

    if (dto.draw_type_code) {
      const typeRes = await query<DrawType>(
        'SELECT id, code, digit_length, default_ticket_price_minor FROM draw_types WHERE code = $1',
        [dto.draw_type_code.toUpperCase()]
      );
      if (typeRes.rows[0]) {
        drawTypeId = typeRes.rows[0].id;
        defaultPrice = Number(typeRes.rows[0].default_ticket_price_minor);
        digitLength = typeRes.rows[0].digit_length;
      } else {
        throw new Error(`Invalid draw_type_code: ${dto.draw_type_code}`);
      }
    } else if (drawTypeId) {
      const typeRes = await query<DrawType>(
        'SELECT id, code, digit_length, default_ticket_price_minor FROM draw_types WHERE id = $1',
        [drawTypeId]
      );
      if (typeRes.rows[0]) {
        defaultPrice = Number(typeRes.rows[0].default_ticket_price_minor);
        digitLength = typeRes.rows[0].digit_length;
      }
    } else {
      throw new Error('Either draw_type_id or draw_type_code is required');
    }

    const ticketPrice = dto.ticket_price_minor !== undefined ? dto.ticket_price_minor : defaultPrice;
    const openDate = new Date(dto.sale_open_at);
    const closeDate = new Date(dto.sale_close_at);
    const drawDate = new Date(dto.draw_at);

    if (openDate >= closeDate) {
      throw new Error('sale_open_at must be before sale_close_at');
    }
    if (closeDate > drawDate) {
      throw new Error('sale_close_at must be on or before draw_at');
    }

    const seqNumber = dto.sequence_number || `DRW-${Date.now().toString().slice(-6)}`;
    const status: DrawStatusCode = dto.status || (openDate <= new Date() && closeDate > new Date() ? 'OPEN' : 'SCHEDULED');

    const insertSql = `
      INSERT INTO draws (
        public_id,
        draw_type_id,
        sequence_number,
        ticket_price_minor,
        sale_open_at,
        sale_close_at,
        draw_at,
        status,
        created_by,
        created_at,
        updated_at
      ) VALUES (
        gen_random_uuid(),
        $1, $2, $3, $4, $5, $6, $7, $8, NOW(), NOW()
      )
      RETURNING id, public_id, draw_type_id, sequence_number, ticket_price_minor,
                sale_open_at, sale_close_at, draw_at, status, total_tickets,
                total_sales_minor, created_by, created_at, updated_at
    `;

    const res = await query<Draw>(insertSql, [
      drawTypeId,
      seqNumber,
      ticketPrice,
      openDate.toISOString(),
      closeDate.toISOString(),
      drawDate.toISOString(),
      status,
      createdByUserId || null,
    ]);

    const created = res.rows[0];
    if (!created) {
      throw new Error('Failed to create draw');
    }

    return (await this.getDrawById(created.id))!;
  }

  /**
   * Update draw status with state-machine validation
   */
  async updateDrawStatus(idOrPublicId: string | number, newStatus: DrawStatusCode): Promise<Draw> {
    const existing = await this.getDrawById(idOrPublicId);
    if (!existing) {
      throw new Error('Draw not found');
    }

    const currentStatus = existing.status;
    if (currentStatus === newStatus) {
      return existing;
    }

    const allowedTransitions = VALID_TRANSITIONS[currentStatus] || [];
    if (!allowedTransitions.includes(newStatus)) {
      throw new Error(`Invalid status transition from ${currentStatus} to ${newStatus}`);
    }

    const updateSql = `
      UPDATE draws 
      SET status = $1, updated_at = NOW() 
      WHERE id = $2 
      RETURNING id
    `;
    await query(updateSql, [newStatus, existing.id]);

    return (await this.getDrawById(existing.id))!;
  }
}

export const drawsService = new DrawsService();
