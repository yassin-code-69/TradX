import type pg from 'pg';
import { query, withTransaction } from '../../db/index.ts';
import type { PrizeRule } from '../draws/draws.service.ts';

export interface Winner {
  id: number;
  public_id: string;
  draw_id: number;
  ticket_id: number;
  user_id: string;
  prize_rule_id?: number | null;
  winning_amount_minor: string | number;
  status: 'PENDING' | 'PAID' | 'FAILED';
  ledger_transaction_id?: number | null;
  created_at: string;
  paid_at?: string | null;
  ticket_number?: string;
  prize_name?: string;
  match_type?: string;
}

export interface DefaultPrizeTier {
  name: string;
  match_type: string;
  match_length: number;
  prize_amount_minor: bigint;
  priority: number;
}

export class WinnersService {
  /**
   * Determine matching tier for a ticket given winning number and draw type
   */
  evaluateMatch(
    selectedNumber: string,
    winningNumber: string,
    drawTypeCode: string,
    prizeRules: PrizeRule[]
  ): { ruleId?: number; name: string; matchType: string; prizeAmountMinor: bigint } | null {
    const sNum = selectedNumber.trim();
    const wNum = winningNumber.trim();

    // 1. If custom prize rules exist in database, check them in priority order
    if (prizeRules && prizeRules.length > 0) {
      const sortedRules = [...prizeRules].sort((a, b) => a.priority - b.priority);

      for (const rule of sortedRules) {
        const mType = rule.match_type.toUpperCase();
        let matched = false;

        if (mType === 'EXACT' || mType === 'MATCH_ALL' || mType === 'MATCH_7' || mType === 'MATCH_3') {
          matched = sNum === wNum;
        } else if (mType.startsWith('MATCH_LAST_') || mType.startsWith('MATCH_')) {
          const countStr = mType.replace('MATCH_LAST_', '').replace('MATCH_', '');
          const count = parseInt(countStr, 10);
          if (!isNaN(count) && count > 0 && count <= wNum.length && count <= sNum.length) {
            matched = sNum.slice(-count) === wNum.slice(-count);
          }
        } else if (mType.startsWith('MATCH_FIRST_')) {
          const count = parseInt(mType.replace('MATCH_FIRST_', ''), 10);
          if (!isNaN(count) && count > 0 && count <= wNum.length && count <= sNum.length) {
            matched = sNum.slice(0, count) === wNum.slice(0, count);
          }
        }

        if (matched) {
          return {
            ruleId: rule.id,
            name: rule.name,
            matchType: rule.match_type,
            prizeAmountMinor: BigInt(rule.prize_amount_minor),
          };
        }
      }
      return null;
    }

    // 2. Default standard rules based on draw type
    if (drawTypeCode === 'MEGA') {
      // 7 digits: Exact, Last 6, Last 5, Last 4, Last 3, Last 2
      if (sNum === wNum) {
        return { name: '1st Prize (Jackpot - 7 Digits)', matchType: 'MATCH_7', prizeAmountMinor: 1000000000n }; // ৳10,000,000
      }
      if (sNum.slice(-6) === wNum.slice(-6)) {
        return { name: '2nd Prize (Match Last 6 Digits)', matchType: 'MATCH_LAST_6', prizeAmountMinor: 50000000n }; // ৳500,000
      }
      if (sNum.slice(-5) === wNum.slice(-5)) {
        return { name: '3rd Prize (Match Last 5 Digits)', matchType: 'MATCH_LAST_5', prizeAmountMinor: 5000000n }; // ৳50,000
      }
      if (sNum.slice(-4) === wNum.slice(-4)) {
        return { name: '4th Prize (Match Last 4 Digits)', matchType: 'MATCH_LAST_4', prizeAmountMinor: 500000n }; // ৳5,000
      }
      if (sNum.slice(-3) === wNum.slice(-3)) {
        return { name: '5th Prize (Match Last 3 Digits)', matchType: 'MATCH_LAST_3', prizeAmountMinor: 50000n }; // ৳500
      }
      if (sNum.slice(-2) === wNum.slice(-2)) {
        return { name: '6th Prize (Match Last 2 Digits)', matchType: 'MATCH_LAST_2', prizeAmountMinor: 5000n }; // ৳50
      }
    } else if (drawTypeCode === 'DAILY') {
      // 3 digits: Exact, Last 2, Last 1
      if (sNum === wNum) {
        return { name: '1st Prize (Exact 3 Digits)', matchType: 'MATCH_3', prizeAmountMinor: 500000n }; // ৳5,000
      }
      if (sNum.slice(-2) === wNum.slice(-2)) {
        return { name: '2nd Prize (Match Last 2 Digits)', matchType: 'MATCH_LAST_2', prizeAmountMinor: 50000n }; // ৳500
      }
      if (sNum.slice(-1) === wNum.slice(-1)) {
        return { name: '3rd Prize (Match Last 1 Digit)', matchType: 'MATCH_LAST_1', prizeAmountMinor: 5000n }; // ৳50
      }
    } else if (drawTypeCode === 'HOURLY') {
      // 3 digits: Exact, Last 2, Last 1
      if (sNum === wNum) {
        return { name: '1st Prize (Exact 3 Digits)', matchType: 'MATCH_3', prizeAmountMinor: 100000n }; // ৳1,000
      }
      if (sNum.slice(-2) === wNum.slice(-2)) {
        return { name: '2nd Prize (Match Last 2 Digits)', matchType: 'MATCH_LAST_2', prizeAmountMinor: 10000n }; // ৳100
      }
      if (sNum.slice(-1) === wNum.slice(-1)) {
        return { name: '3rd Prize (Match Last 1 Digit)', matchType: 'MATCH_LAST_1', prizeAmountMinor: 1000n }; // ৳10
      }
    }

    return null;
  }

  /**
   * Process all tickets for a draw against the winning number and distribute payouts
   */
  async processDrawWinners(
    drawId: number,
    winningNumber: string,
    adminUserId?: string,
    client?: pg.PoolClient
  ): Promise<{
    totalTicketsEvaluated: number;
    winnersCount: number;
    totalPrizePaidMinor: string;
    winners: Winner[];
  }> {
    if (!client) {
      return await withTransaction((txClient) =>
        this.processDrawWinners(drawId, winningNumber, adminUserId, txClient)
      );
    }

    // 1. Fetch draw and draw type
    const drawRes = await client.query<{
      id: number;
      draw_type_id: number;
      code: string;
      sequence_number: string;
    }>(
      `SELECT d.id, d.draw_type_id, dt.code, d.sequence_number
       FROM draws d
       JOIN draw_types dt ON d.draw_type_id = dt.id
       WHERE d.id = $1`,
      [drawId]
    );

    if (!drawRes.rows[0]) {
      throw new Error(`Draw not found with ID ${drawId}`);
    }

    const draw = drawRes.rows[0];

    // 2. Fetch prize rules for this draw type
    const prizeRulesRes = await client.query<PrizeRule>(
      `SELECT id, draw_type_id, name, match_type, prize_amount_minor, priority, status
       FROM prize_rules
       WHERE draw_type_id = $1 AND status = 'ACTIVE'
       ORDER BY priority ASC`,
      [draw.draw_type_id]
    );
    const prizeRules = prizeRulesRes.rows;

    // 3. Fetch all active tickets for this draw
    const ticketsRes = await client.query<{
      id: number;
      public_id: string;
      user_id: string;
      selected_number: string;
      ticket_price_minor: string;
    }>(
      `SELECT id, public_id, user_id, selected_number, ticket_price_minor
       FROM tickets
       WHERE draw_id = $1 AND status = 'ACTIVE'`,
      [drawId]
    );

    const tickets = ticketsRes.rows;
    let totalPrizePaidMinor = 0n;
    const winnersList: Winner[] = [];

    // 4. Cache PRIZE_POOL ledger account lookup once before iterating over tickets
    let prizePoolAccRes = await client.query<{ id: number }>(
      "SELECT id FROM ledger_accounts WHERE account_type = 'PRIZE_POOL' LIMIT 1"
    );
    let prizePoolAccId = prizePoolAccRes.rows[0]?.id;
    if (!prizePoolAccId) {
      const createPrizeAcc = await client.query<{ id: number }>(
        `INSERT INTO ledger_accounts (public_id, owner_type, owner_id, account_type, currency, status, created_at)
         VALUES (gen_random_uuid(), 'SYSTEM', 'SYSTEM', 'PRIZE_POOL', 'BDT', 'ACTIVE', NOW()) RETURNING id`
      );
      prizePoolAccId = createPrizeAcc.rows[0]!.id;
    }

    const userAccountCache = new Map<string, number>();

    // 5. Process each ticket within the transaction
    for (const ticket of tickets) {
      const match = this.evaluateMatch(ticket.selected_number, winningNumber, draw.code, prizeRules);
      if (!match) continue;

      const winningAmount = match.prizeAmountMinor;
      totalPrizePaidMinor += winningAmount;

      // Prevent duplicate winner record
      const existingWinner = await client.query<{ id: number }>(
        'SELECT id FROM winners WHERE ticket_id = $1',
        [ticket.id]
      );
      if (existingWinner.rows[0]) {
        continue;
      }

      // Lock & credit user wallet
      let walletRes = await client.query<{ id: number; available_balance_minor: string }>(
        'SELECT id, available_balance_minor FROM wallets WHERE user_id = $1 FOR UPDATE',
        [ticket.user_id]
      );

      if (!walletRes.rows[0]) {
        const createWalletRes = await client.query<{ id: number; available_balance_minor: string }>(
          `INSERT INTO wallets (public_id, user_id, currency, available_balance_minor, locked_balance_minor, version, created_at, updated_at)
           VALUES (gen_random_uuid(), $1, 'BDT', 0, 0, 0, NOW(), NOW())
           RETURNING id, available_balance_minor`,
          [ticket.user_id]
        );
        walletRes = createWalletRes;
      }

      const wallet = walletRes.rows[0]!;
      const newBalance = BigInt(wallet.available_balance_minor) + winningAmount;

      await client.query(
        'UPDATE wallets SET available_balance_minor = $1, version = version + 1, updated_at = NOW() WHERE id = $2',
        [newBalance.toString(), wallet.id]
      );

      // Create Ledger Transaction
      const ledgerTxRes = await client.query<{ id: number }>(
        `INSERT INTO ledger_transactions (
           public_id, transaction_type, reference_type, reference_id,
           status, created_by, metadata, created_at
         ) VALUES (
           gen_random_uuid(), 'WINNING', 'ticket', $1,
           'COMPLETED', $2, $3, NOW()
         ) RETURNING id`,
        [
          ticket.id.toString(),
          adminUserId || null,
          JSON.stringify({
            draw_id: drawId,
            ticket_id: ticket.id,
            selected_number: ticket.selected_number,
            winning_number: winningNumber,
            prize_name: match.name,
            match_type: match.matchType,
            winning_amount_minor: winningAmount.toString(),
          }),
        ]
      );
      const ledgerTxId = ledgerTxRes.rows[0]?.id;

      // Ledger accounts: PRIZE_POOL -> USER_AVAILABLE
      let userAccountId = userAccountCache.get(ticket.user_id);
      if (!userAccountId) {
        const userAccountRes = await client.query<{ id: number }>(
          "SELECT id FROM ledger_accounts WHERE owner_id = $1 AND account_type = 'USER_AVAILABLE'",
          [ticket.user_id]
        );
        userAccountId = userAccountRes.rows[0]?.id;
        if (!userAccountId) {
          const createAcc = await client.query<{ id: number }>(
            `INSERT INTO ledger_accounts (public_id, owner_type, owner_id, account_type, currency, status, created_at)
             VALUES (gen_random_uuid(), 'USER', $1, 'USER_AVAILABLE', 'BDT', 'ACTIVE', NOW()) RETURNING id`,
            [ticket.user_id]
          );
          userAccountId = createAcc.rows[0]!.id;
        }
        userAccountCache.set(ticket.user_id, userAccountId);
      }

      if (ledgerTxId && userAccountId && prizePoolAccId) {
        // Debit PRIZE_POOL (-amount)
        await client.query(
          'INSERT INTO ledger_entries (transaction_id, account_id, amount_minor, created_at) VALUES ($1, $2, $3, NOW())',
          [ledgerTxId, prizePoolAccId, (-winningAmount).toString()]
        );
        // Credit USER_AVAILABLE (+amount)
        await client.query(
          'INSERT INTO ledger_entries (transaction_id, account_id, amount_minor, created_at) VALUES ($1, $2, $3, NOW())',
          [ledgerTxId, userAccountId, winningAmount.toString()]
        );
      }

      // Mark ticket as winner
      await client.query('UPDATE tickets SET is_winner = true, updated_at = NOW() WHERE id = $1', [ticket.id]);

      // Insert winner record
      const winnerRes = await client.query<Winner>(
        `INSERT INTO winners (
           public_id, draw_id, ticket_id, user_id, prize_rule_id,
           winning_amount_minor, status, ledger_transaction_id, created_at, paid_at
         ) VALUES (
           gen_random_uuid(), $1, $2, $3, $4, $5, 'PAID', $6, NOW(), NOW()
         ) RETURNING *`,
        [
          drawId,
          ticket.id,
          ticket.user_id,
          match.ruleId || null,
          winningAmount.toString(),
          ledgerTxId || null,
        ]
      );

      // Create Notification for user
      const prizeBDT = (Number(winningAmount) / 100).toFixed(2);
      await client.query(
        `INSERT INTO notifications (
           public_id, user_id, type, title, body, data, created_at
         ) VALUES (
           gen_random_uuid(), $1, 'WINNER', $2, $3, $4, NOW()
         )`,
        [
          ticket.user_id,
          '🎉 Congratulations! You Won!',
          `Your ticket #${ticket.selected_number} won ৳${prizeBDT} in ${draw.code} Draw (${draw.sequence_number})!`,
          JSON.stringify({
            draw_id: drawId,
            ticket_id: ticket.id,
            winning_amount_minor: winningAmount.toString(),
            prize_name: match.name,
          }),
        ]
      );

      const wRecord = winnerRes.rows[0]!;
      wRecord.ticket_number = ticket.selected_number;
      wRecord.prize_name = match.name;
      wRecord.match_type = match.matchType;
      winnersList.push(wRecord);
    }

    return {
      totalTicketsEvaluated: tickets.length,
      winnersCount: winnersList.length,
      totalPrizePaidMinor: totalPrizePaidMinor.toString(),
      winners: winnersList,
    };
  }
}

export const winnersService = new WinnersService();

