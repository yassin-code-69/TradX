import { query, withTransaction } from '../../db/index.ts';
import { drawsService, type Draw } from '../draws/draws.service.ts';

export interface TicketOrder {
  id: number;
  public_id: string;
  user_id: string;
  draw_id: number;
  quantity: number;
  unit_price_minor: string | number;
  subtotal_minor: string | number;
  discount_minor: string | number;
  total_minor: string | number;
  status: string;
  ledger_transaction_id?: number | null;
  idempotency_key?: string | null;
  created_at: string;
}

export interface Ticket {
  id: number;
  public_id: string;
  order_id: number;
  user_id: string;
  draw_id: number;
  selected_number: string;
  ticket_price_minor: string | number;
  status: string;
  is_winner: boolean;
  created_at: string;
  updated_at: string;
  draw_type_code?: string;
  draw_sequence_number?: string;
  draw_status?: string;
  winning_number?: string | null;
}

export interface PurchaseTicketsInput {
  draw_id: number | string;
  selected_number: string;
  quantity: number;
  payment_method?: 'WALLET' | string;
  idempotency_key?: string;
}

export interface PurchaseTicketsResult {
  order: TicketOrder;
  tickets: Ticket[];
  wallet: {
    available_balance_minor: string | number;
  };
}

export class TicketsService {
  /**
   * Purchase tickets atomically
   */
  async purchaseTickets(userId: string, input: PurchaseTicketsInput): Promise<PurchaseTicketsResult> {
    const { draw_id, selected_number, quantity, idempotency_key } = input;

    if (!quantity || quantity < 1) {
      throw new Error('Quantity must be at least 1');
    }
    if (quantity > 100) {
      throw new Error('Maximum 100 tickets per single purchase');
    }

    // 1. Fetch and validate draw
    const draw = await drawsService.getDrawById(draw_id);
    if (!draw) {
      throw new Error('Draw not found');
    }

    const now = new Date();
    const saleOpen = new Date(draw.sale_open_at);
    const saleClose = new Date(draw.sale_close_at);

    if (draw.status !== 'OPEN') {
      throw new Error(`Draw is not open for ticket sales (Current status: ${draw.status})`);
    }

    if (now < saleOpen) {
      throw new Error('Draw ticket sales have not opened yet');
    }

    if (now >= saleClose) {
      throw new Error('Draw ticket sales have closed');
    }

    // 2. Validate selected_number preserving leading zeros
    const expectedDigitLength = draw.digit_length || (draw.draw_type_code === 'MEGA' ? 7 : 3);
    const cleanNumber = String(selected_number).trim();

    if (!/^\d+$/.test(cleanNumber)) {
      throw new Error('Selected number must contain digits only');
    }

    if (cleanNumber.length !== expectedDigitLength) {
      throw new Error(`Selected number must be exactly ${expectedDigitLength} digits (e.g. "${'0'.repeat(expectedDigitLength - 1)}1")`);
    }

    // 3. Calculate authoritative price
    const unitPriceMinor = BigInt(draw.ticket_price_minor);
    const totalMinor = unitPriceMinor * BigInt(quantity);

    // 4. Atomic transaction: lock wallet, check balance, debit, order, tickets, ledger
    return await withTransaction(async (client) => {
      // Check idempotency if key provided
      if (idempotency_key) {
        const existingOrderRes = await client.query<TicketOrder>(
          'SELECT * FROM ticket_orders WHERE idempotency_key = $1 AND user_id = $2',
          [idempotency_key, userId]
        );
        if (existingOrderRes.rows[0]) {
          const existingOrder = existingOrderRes.rows[0];
          const ticketsRes = await client.query<Ticket>(
            'SELECT * FROM tickets WHERE order_id = $1 ORDER BY id ASC',
            [existingOrder.id]
          );
          const walletRes = await client.query<{ available_balance_minor: string }>(
            'SELECT available_balance_minor FROM wallets WHERE user_id = $1',
            [userId]
          );
          return {
            order: existingOrder,
            tickets: ticketsRes.rows,
            wallet: {
              available_balance_minor: walletRes.rows[0]?.available_balance_minor || '0',
            },
          };
        }
      }

      // Check and lock wallet
      let walletRes = await client.query<{
        id: number;
        available_balance_minor: string;
        locked_balance_minor: string;
        version: number;
      }>('SELECT id, available_balance_minor, locked_balance_minor, version FROM wallets WHERE user_id = $1 FOR UPDATE', [userId]);

      if (!walletRes.rows[0]) {
        // Create initial wallet if none exists
        const createWalletRes = await client.query<{
          id: number;
          available_balance_minor: string;
          locked_balance_minor: string;
          version: number;
        }>(
          `INSERT INTO wallets (public_id, user_id, currency, available_balance_minor, locked_balance_minor, version, created_at, updated_at)
           VALUES (gen_random_uuid(), $1, 'BDT', 0, 0, 0, NOW(), NOW())
           RETURNING id, available_balance_minor, locked_balance_minor, version`,
          [userId]
        );
        walletRes = createWalletRes;
      }

      const wallet = walletRes.rows[0]!;
      const currentBalance = BigInt(wallet.available_balance_minor);

      if (currentBalance < totalMinor) {
        throw new Error(
          `Insufficient wallet balance. Required: ৳${(Number(totalMinor) / 100).toFixed(2)}, Available: ৳${(Number(currentBalance) / 100).toFixed(2)}`
        );
      }

      // Debit wallet
      const newBalance = currentBalance - totalMinor;
      const updatedWalletRes = await client.query<{ available_balance_minor: string }>(
        `UPDATE wallets 
         SET available_balance_minor = $1, version = version + 1, updated_at = NOW() 
         WHERE id = $2 
         RETURNING available_balance_minor`,
        [newBalance.toString(), wallet.id]
      );

      // Ledger Transaction
      const ledgerTxRes = await client.query<{ id: number }>(
        `INSERT INTO ledger_transactions (
           public_id, transaction_type, reference_type, reference_id,
           idempotency_key, status, created_by, metadata, created_at
         ) VALUES (
           gen_random_uuid(), 'TICKET_PURCHASE', 'draw', $1,
           $2, 'COMPLETED', $3, $4, NOW()
         ) RETURNING id`,
        [
          draw.id.toString(),
          idempotency_key || null,
          userId,
          JSON.stringify({
            draw_id: draw.id,
            sequence_number: draw.sequence_number,
            quantity,
            selected_number: cleanNumber,
            unit_price_minor: unitPriceMinor.toString(),
            total_minor: totalMinor.toString(),
          }),
        ]
      );
      const ledgerTxId = ledgerTxRes.rows[0]?.id;

      // Ledger Accounts & Entries
      // Find or create user available account
      let userAccountRes = await client.query<{ id: number }>(
        "SELECT id FROM ledger_accounts WHERE owner_id = $1 AND account_type = 'USER_AVAILABLE'",
        [userId]
      );
      let userAccountId = userAccountRes.rows[0]?.id;
      if (!userAccountId) {
        const createAccRes = await client.query<{ id: number }>(
          `INSERT INTO ledger_accounts (public_id, owner_type, owner_id, account_type, currency, status, created_at)
           VALUES (gen_random_uuid(), 'USER', $1, 'USER_AVAILABLE', 'BDT', 'ACTIVE', NOW()) RETURNING id`,
          [userId]
        );
        userAccountId = createAccRes.rows[0]!.id;
      }

      // Find or create platform revenue account
      let revenueAccountRes = await client.query<{ id: number }>(
        "SELECT id FROM ledger_accounts WHERE account_type = 'PLATFORM_REVENUE' LIMIT 1"
      );
      let revenueAccountId = revenueAccountRes.rows[0]?.id;
      if (!revenueAccountId) {
        const createRevRes = await client.query<{ id: number }>(
          `INSERT INTO ledger_accounts (public_id, owner_type, owner_id, account_type, currency, status, created_at)
           VALUES (gen_random_uuid(), 'SYSTEM', 'SYSTEM', 'PLATFORM_REVENUE', 'BDT', 'ACTIVE', NOW()) RETURNING id`,
        );
        revenueAccountId = createRevRes.rows[0]!.id;
      }

      if (ledgerTxId && userAccountId && revenueAccountId) {
        // User available debit (-amount)
        await client.query(
          'INSERT INTO ledger_entries (transaction_id, account_id, amount_minor, created_at) VALUES ($1, $2, $3, NOW())',
          [ledgerTxId, userAccountId, (-totalMinor).toString()]
        );
        // Revenue credit (+amount)
        await client.query(
          'INSERT INTO ledger_entries (transaction_id, account_id, amount_minor, created_at) VALUES ($1, $2, $3, NOW())',
          [ledgerTxId, revenueAccountId, totalMinor.toString()]
        );
      }

      // Create Ticket Order
      const orderRes = await client.query<TicketOrder>(
        `INSERT INTO ticket_orders (
           public_id, user_id, draw_id, quantity, unit_price_minor,
           subtotal_minor, discount_minor, total_minor, status,
           ledger_transaction_id, idempotency_key, created_at
         ) VALUES (
           gen_random_uuid(), $1, $2, $3, $4, $5, 0, $5, 'PAID', $6, $7, NOW()
         ) RETURNING *`,
        [
          userId,
          draw.id,
          quantity,
          unitPriceMinor.toString(),
          totalMinor.toString(),
          ledgerTxId || null,
          idempotency_key || null,
        ]
      );
      const order = orderRes.rows[0]!;

      // Create Tickets (one for each in quantity)
      const createdTickets: Ticket[] = [];
      for (let i = 0; i < quantity; i++) {
        const ticketRes = await client.query<Ticket>(
          `INSERT INTO tickets (
             public_id, order_id, user_id, draw_id, selected_number,
             ticket_price_minor, status, is_winner, created_at, updated_at
           ) VALUES (
             gen_random_uuid(), $1, $2, $3, $4, $5, 'ACTIVE', false, NOW(), NOW()
           ) RETURNING *`,
          [order.id, userId, draw.id, cleanNumber, unitPriceMinor.toString()]
        );
        if (ticketRes.rows[0]) {
          createdTickets.push(ticketRes.rows[0]);
        }
      }

      // Update Draw stats
      await client.query(
        `UPDATE draws 
         SET total_tickets = total_tickets + $1, total_sales_minor = total_sales_minor + $2, updated_at = NOW() 
         WHERE id = $3`,
        [quantity, totalMinor.toString(), draw.id]
      );

      return {
        order,
        tickets: createdTickets,
        wallet: {
          available_balance_minor: updatedWalletRes.rows[0]?.available_balance_minor || newBalance.toString(),
        },
      };
    });
  }

  /**
   * Get user tickets with filters (draw type, status, pagination)
   */
  async getUserTickets(
    userId: string,
    filters?: {
      draw_type?: string;
      status?: string;
      limit?: number;
      offset?: number;
    }
  ): Promise<{ tickets: Ticket[]; total: number }> {
    const params: unknown[] = [userId];
    const conditions: string[] = ['t.user_id = $1'];

    if (filters?.draw_type) {
      params.push(filters.draw_type.toUpperCase());
      conditions.push(`dt.code = $${params.length}`);
    }

    if (filters?.status) {
      params.push(filters.status.toUpperCase());
      conditions.push(`t.status = $${params.length}`);
    }

    const whereClause = `WHERE ${conditions.join(' AND ')}`;
    const limit = Math.min(filters?.limit ?? 20, 100);
    const offset = filters?.offset ?? 0;

    const countSql = `
      SELECT COUNT(*) as count
      FROM tickets t
      JOIN draws d ON t.draw_id = d.id
      JOIN draw_types dt ON d.draw_type_id = dt.id
      ${whereClause}
    `;
    const countRes = await query<{ count: string }>(countSql, params);
    const total = parseInt(countRes.rows[0]?.count || '0', 10);

    const listSql = `
      SELECT 
        t.id,
        t.public_id,
        t.order_id,
        t.user_id,
        t.draw_id,
        t.selected_number,
        t.ticket_price_minor,
        t.status,
        t.is_winner,
        t.created_at,
        t.updated_at,
        dt.code AS draw_type_code,
        d.sequence_number AS draw_sequence_number,
        d.status AS draw_status,
        dr.winning_number
      FROM tickets t
      JOIN draws d ON t.draw_id = d.id
      JOIN draw_types dt ON d.draw_type_id = dt.id
      LEFT JOIN draw_results dr ON d.id = dr.draw_id
      ${whereClause}
      ORDER BY t.created_at DESC
      LIMIT $${params.length + 1} OFFSET $${params.length + 2}
    `;

    const ticketsRes = await query<Ticket>(listSql, [...params, limit, offset]);

    return {
      tickets: ticketsRes.rows,
      total,
    };
  }

  /**
   * Get single ticket by ID
   */
  async getTicketById(ticketIdOrPublicId: string | number, userId?: string, isAdmin = false): Promise<Ticket | null> {
    const isNumeric = !isNaN(Number(ticketIdOrPublicId)) && !String(ticketIdOrPublicId).includes('-');
    const condition = isNumeric ? 't.id = $1' : 't.public_id = $1';

    const sql = `
      SELECT 
        t.id,
        t.public_id,
        t.order_id,
        t.user_id,
        t.draw_id,
        t.selected_number,
        t.ticket_price_minor,
        t.status,
        t.is_winner,
        t.created_at,
        t.updated_at,
        dt.code AS draw_type_code,
        d.sequence_number AS draw_sequence_number,
        d.status AS draw_status,
        dr.winning_number
      FROM tickets t
      JOIN draws d ON t.draw_id = d.id
      JOIN draw_types dt ON d.draw_type_id = dt.id
      LEFT JOIN draw_results dr ON d.id = dr.draw_id
      WHERE ${condition}
    `;

    const res = await query<Ticket>(sql, [ticketIdOrPublicId]);
    const ticket = res.rows[0];
    if (!ticket) return null;

    if (!isAdmin && userId && ticket.user_id !== userId) {
      return null;
    }

    return ticket;
  }

  /**
   * Admin view all tickets with advanced filters
   */
  async getAdminTickets(filters?: {
    draw_id?: string | number;
    user_id?: string;
    status?: string;
    is_winner?: boolean;
    selected_number?: string;
    limit?: number;
    offset?: number;
  }): Promise<{ tickets: Ticket[]; total: number }> {
    const params: unknown[] = [];
    const conditions: string[] = [];

    if (filters?.draw_id) {
      params.push(filters.draw_id);
      conditions.push(`(t.draw_id::text = $${params.length} OR d.public_id::text = $${params.length})`);
    }

    if (filters?.user_id) {
      params.push(filters.user_id);
      conditions.push(`t.user_id = $${params.length}`);
    }

    if (filters?.status) {
      params.push(filters.status.toUpperCase());
      conditions.push(`t.status = $${params.length}`);
    }

    if (filters?.is_winner !== undefined) {
      params.push(filters.is_winner);
      conditions.push(`t.is_winner = $${params.length}`);
    }

    if (filters?.selected_number) {
      params.push(filters.selected_number);
      conditions.push(`t.selected_number = $${params.length}`);
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';
    const limit = Math.min(filters?.limit ?? 50, 100);
    const offset = filters?.offset ?? 0;

    const countSql = `
      SELECT COUNT(*) as count
      FROM tickets t
      JOIN draws d ON t.draw_id = d.id
      JOIN draw_types dt ON d.draw_type_id = dt.id
      ${whereClause}
    `;
    const countRes = await query<{ count: string }>(countSql, params);
    const total = parseInt(countRes.rows[0]?.count || '0', 10);

    const listSql = `
      SELECT 
        t.id,
        t.public_id,
        t.order_id,
        t.user_id,
        t.draw_id,
        t.selected_number,
        t.ticket_price_minor,
        t.status,
        t.is_winner,
        t.created_at,
        t.updated_at,
        dt.code AS draw_type_code,
        d.sequence_number AS draw_sequence_number,
        d.status AS draw_status,
        dr.winning_number
      FROM tickets t
      JOIN draws d ON t.draw_id = d.id
      JOIN draw_types dt ON d.draw_type_id = dt.id
      LEFT JOIN draw_results dr ON d.id = dr.draw_id
      ${whereClause}
      ORDER BY t.created_at DESC
      LIMIT $${params.length + 1} OFFSET $${params.length + 2}
    `;

    const ticketsRes = await query<Ticket>(listSql, [...params, limit, offset]);

    return {
      tickets: ticketsRes.rows,
      total,
    };
  }
}

export const ticketsService = new TicketsService();
