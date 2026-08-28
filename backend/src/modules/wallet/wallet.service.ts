import type pg from 'pg';
import { query, withTransaction, type DbClient } from '../../db/client.ts';
import {
  AppError,
  BadRequestError,
  InsufficientBalanceError,
  NotFoundError,
} from '../../utils/errors.ts';
import { formatMoney, toMinorUnits } from '../../utils/money.ts';
import type {
  AdminAdjustBalanceInput,
  LedgerTransactionType,
  TransactionHistoryQuery,
  WalletBalance,
  WalletTransactionItem,
} from './wallet.types.ts';

export class WalletService {
  /**
   * Retrieves or creates a user's wallet and required ledger accounts.
   */
  async getOrCreateWallet(userId: string, client?: DbClient) {
    const runner = client ? client.query.bind(client) : query;

    // Check if user profile exists
    const userRes = await runner(`SELECT user_id FROM profiles WHERE user_id = $1`, [userId]);
    if (userRes.rows.length === 0) {
      throw new NotFoundError(`User with ID ${userId} not found`);
    }

    // Try fetching existing wallet
    let walletRes = await runner(
      `SELECT id, public_id, user_id, currency, available_balance_minor, locked_balance_minor, version
       FROM wallets WHERE user_id = $1`,
      [userId]
    );

    if (walletRes.rows.length === 0) {
      walletRes = await runner(
        `INSERT INTO wallets (user_id, currency, available_balance_minor, locked_balance_minor, version)
         VALUES ($1, 'BDT', 0, 0, 0)
         ON CONFLICT (user_id) DO UPDATE SET updated_at = now()
         RETURNING id, public_id, user_id, currency, available_balance_minor, locked_balance_minor, version`,
        [userId]
      );
    }

    // Ensure USER_AVAILABLE and USER_LOCKED ledger accounts exist
    await this.getOrCreateLedgerAccount('USER', userId, 'USER_AVAILABLE', 'BDT', client);
    await this.getOrCreateLedgerAccount('USER', userId, 'USER_LOCKED', 'BDT', client);

    return walletRes.rows[0];
  }

  /**
   * Gets or creates a specific ledger account.
   */
  async getOrCreateLedgerAccount(
    ownerType: string,
    ownerId: string,
    accountType: string,
    currency: string = 'BDT',
    client?: DbClient
  ) {
    const runner = client ? client.query.bind(client) : query;
    let accRes = await runner(
      `SELECT id, public_id, owner_type, owner_id, account_type, currency, status
       FROM ledger_accounts
       WHERE owner_type = $1 AND owner_id = $2 AND account_type = $3 AND currency = $4`,
      [ownerType, ownerId, accountType, currency]
    );

    if (accRes.rows.length === 0) {
      accRes = await runner(
        `INSERT INTO ledger_accounts (owner_type, owner_id, account_type, currency, status)
         VALUES ($1, $2, $3, $4, 'ACTIVE')
         ON CONFLICT (owner_type, owner_id, account_type, currency) DO UPDATE SET status = 'ACTIVE'
         RETURNING id, public_id, owner_type, owner_id, account_type, currency, status`,
        [ownerType, ownerId, accountType, currency]
      );
    }

    return accRes.rows[0];
  }

  /**
   * Returns current user wallet balances (available, locked, total).
   */
  async getWalletBalance(userId: string): Promise<WalletBalance> {
    const wallet = await this.getOrCreateWallet(userId);
    const available = BigInt(wallet.available_balance_minor);
    const locked = BigInt(wallet.locked_balance_minor);
    const total = available + locked;
    const currency = wallet.currency || 'BDT';

    return {
      availableBalanceMinor: available.toString(),
      lockedBalanceMinor: locked.toString(),
      totalBalanceMinor: total.toString(),
      currency,
      formatted: {
        available: formatMoney(available, currency),
        locked: formatMoney(locked, currency),
        total: formatMoney(total, currency),
      },
    };
  }

  /**
   * Executes a balanced double-entry ledger transaction.
   * Invariant: Sum of entry amounts MUST be 0.
   */
  async recordLedgerTransaction(
    client: pg.PoolClient,
    params: {
      transactionType: LedgerTransactionType;
      referenceType?: string;
      referenceId?: string;
      idempotencyKey?: string;
      createdBy?: string;
      metadata?: Record<string, unknown>;
      entries: Array<{
        accountId: string | number;
        amountMinor: bigint;
      }>;
    }
  ) {
    // 1. Invariant check: SUM(amount_minor) == 0
    let totalSum = 0n;
    for (const e of params.entries) {
      totalSum += e.amountMinor;
    }

    if (totalSum !== 0n) {
      throw new AppError(
        'LEDGER_IMBALANCE',
        `Ledger transaction entries must balance to zero. Current sum: ${totalSum}`,
        500
      );
    }

    // 2. Insert ledger transaction
    const txRes = await client.query(
      `INSERT INTO ledger_transactions (
         transaction_type, reference_type, reference_id, idempotency_key, status, created_by, metadata
       ) VALUES ($1, $2, $3, $4, 'COMPLETED', $5, $6)
       RETURNING id, public_id, transaction_type, created_at`,
      [
        params.transactionType,
        params.referenceType || null,
        params.referenceId || null,
        params.idempotencyKey || null,
        params.createdBy || null,
        JSON.stringify(params.metadata || {}),
      ]
    );

    const transactionId = txRes.rows[0].id;

    // 3. Insert all ledger entries
    for (const entry of params.entries) {
      await client.query(
        `INSERT INTO ledger_entries (transaction_id, account_id, amount_minor)
         VALUES ($1, $2, $3)`,
        [transactionId, entry.accountId, entry.amountMinor.toString()]
      );
    }

    return txRes.rows[0];
  }

  /**
   * Admin adjust user balance with audit log and full ledger tracking.
   */
  async adminAdjustBalance(
    adminUserId: string,
    input: AdminAdjustBalanceInput,
    reqMeta?: { ip?: string; userAgent?: string; requestId?: string }
  ) {
    const amountMinor = toMinorUnits(input.amountMinor);
    if (amountMinor <= 0n) {
      throw new BadRequestError('VALIDATION_ERROR', 'Adjustment amount must be greater than 0');
    }

    return await withTransaction(async (client) => {
      // Ensure user and wallet exist and lock wallet row
      await this.getOrCreateWallet(input.userId, client);

      const walletRes = await client.query(
        `SELECT id, user_id, available_balance_minor, locked_balance_minor, version, currency
         FROM wallets
         WHERE user_id = $1
         FOR UPDATE`,
        [input.userId]
      );

      if (walletRes.rows.length === 0) {
        throw new NotFoundError(`Wallet for user ${input.userId} not found`);
      }

      const wallet = walletRes.rows[0];
      const currentAvailable = BigInt(wallet.available_balance_minor);
      const currency = wallet.currency || 'BDT';

      let newAvailable: bigint;
      let userEntryAmount: bigint;
      let systemEntryAmount: bigint;

      if (input.type === 'CREDIT') {
        newAvailable = currentAvailable + amountMinor;
        userEntryAmount = amountMinor; // User account credited (+amount)
        systemEntryAmount = -amountMinor; // System adjustment debited (-amount)
      } else {
        // DEBIT
        if (currentAvailable < amountMinor) {
          throw new InsufficientBalanceError(
            `User available balance (${formatMoney(currentAvailable, currency)}) is less than debit amount (${formatMoney(amountMinor, currency)})`
          );
        }
        newAvailable = currentAvailable - amountMinor;
        userEntryAmount = -amountMinor; // User account debited (-amount)
        systemEntryAmount = amountMinor; // System adjustment credited (+amount)
      }

      // Accounts
      const userAvailableAcc = await this.getOrCreateLedgerAccount(
        'USER',
        input.userId,
        'USER_AVAILABLE',
        currency,
        client
      );

      const systemAdjustmentAcc = await this.getOrCreateLedgerAccount(
        'SYSTEM',
        'SYSTEM',
        'SYSTEM_ADJUSTMENT',
        currency,
        client
      );

      // Record double entry ledger
      const ledgerTx = await this.recordLedgerTransaction(client, {
        transactionType: 'ADMIN_ADJUSTMENT',
        referenceType: 'admin_adjustments',
        referenceId: adminUserId,
        createdBy: adminUserId,
        metadata: {
          type: input.type,
          reason: input.reason,
          note: input.note,
          adminUserId,
          previousAvailableMinor: currentAvailable.toString(),
          newAvailableMinor: newAvailable.toString(),
        },
        entries: [
          { accountId: userAvailableAcc.id, amountMinor: userEntryAmount },
          { accountId: systemAdjustmentAcc.id, amountMinor: systemEntryAmount },
        ],
      });

      // Update wallet balance snapshot
      const updatedWalletRes = await client.query(
        `UPDATE wallets
         SET available_balance_minor = $1,
             version = version + 1,
             updated_at = now()
         WHERE user_id = $2
         RETURNING id, public_id, user_id, currency, available_balance_minor, locked_balance_minor, version`,
        [newAvailable.toString(), input.userId]
      );

      const updatedWallet = updatedWalletRes.rows[0];

      // Record audit log
      await client.query(
        `INSERT INTO audit_logs (
           actor_user_id, action, entity_type, entity_id, old_values, new_values, ip_address, user_agent, request_id
         ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
        [
          adminUserId,
          'ADMIN_WALLET_ADJUST',
          'wallets',
          wallet.id.toString(),
          JSON.stringify({
            availableBalanceMinor: currentAvailable.toString(),
            version: wallet.version,
          }),
          JSON.stringify({
            adjustmentType: input.type,
            amountMinor: amountMinor.toString(),
            reason: input.reason,
            note: input.note,
            newAvailableMinor: newAvailable.toString(),
            ledgerTransactionId: ledgerTx.id,
          }),
          reqMeta?.ip || null,
          reqMeta?.userAgent || null,
          reqMeta?.requestId || null,
        ]
      );

      return {
        success: true,
        adjustmentType: input.type,
        amountMinor: amountMinor.toString(),
        formattedAmount: formatMoney(amountMinor, currency),
        previousBalanceMinor: currentAvailable.toString(),
        newBalanceMinor: newAvailable.toString(),
        wallet: {
          availableBalanceMinor: updatedWallet.available_balance_minor,
          lockedBalanceMinor: updatedWallet.locked_balance_minor,
          currency: updatedWallet.currency,
          formatted: {
            available: formatMoney(updatedWallet.available_balance_minor, updatedWallet.currency),
            locked: formatMoney(updatedWallet.locked_balance_minor, updatedWallet.currency),
          },
        },
        ledgerTransactionId: ledgerTx.public_id,
      };
    });
  }

  /**
   * Retrieves transaction history for user with filters and pagination.
   */
  async getTransactionHistory(
    userId: string,
    queryFilters: TransactionHistoryQuery
  ): Promise<{ transactions: WalletTransactionItem[]; total: number; page: number; limit: number }> {
    const page = Math.max(1, queryFilters.page || 1);
    const limit = Math.min(100, Math.max(1, queryFilters.limit || 20));
    const offset = (page - 1) * limit;

    // Get user's available and locked accounts
    const userAccsRes = await query(
      `SELECT id FROM ledger_accounts WHERE owner_type = 'USER' AND owner_id = $1`,
      [userId]
    );

    if (userAccsRes.rows.length === 0) {
      return { transactions: [], total: 0, page, limit };
    }

    const accountIds = userAccsRes.rows.map((r) => r.id);

    const conditions: string[] = [`le.account_id = ANY($1)`];
    const params: any[] = [accountIds];

    if (queryFilters.type) {
      params.push(queryFilters.type);
      conditions.push(`lt.transaction_type = $${params.length}`);
    }

    if (queryFilters.fromDate) {
      params.push(new Date(queryFilters.fromDate));
      conditions.push(`lt.created_at >= $${params.length}`);
    }

    if (queryFilters.toDate) {
      params.push(new Date(queryFilters.toDate));
      conditions.push(`lt.created_at <= $${params.length}`);
    }

    const whereClause = conditions.join(' AND ');

    // Total count
    const countRes = await query(
      `SELECT count(DISTINCT lt.id) as total
       FROM ledger_transactions lt
       JOIN ledger_entries le ON lt.id = le.transaction_id
       WHERE ${whereClause}`,
      params
    );

    const total = parseInt(countRes.rows[0]?.total || '0', 10);

    // Paginated results with net change from user perspective
    const listParams = [...params, limit, offset];
    const listRes = await query(
      `SELECT 
         lt.id,
         lt.public_id,
         lt.transaction_type,
         lt.reference_type,
         lt.reference_id,
         lt.status,
         lt.metadata,
         lt.created_at,
         SUM(le.amount_minor) as net_amount_minor
       FROM ledger_transactions lt
       JOIN ledger_entries le ON lt.id = le.transaction_id
       WHERE ${whereClause}
       GROUP BY lt.id, lt.public_id, lt.transaction_type, lt.reference_type, lt.reference_id, lt.status, lt.metadata, lt.created_at
       ORDER BY lt.created_at DESC
       LIMIT $${listParams.length - 1} OFFSET $${listParams.length}`,
      listParams
    );

    const transactions: WalletTransactionItem[] = listRes.rows.map((row) => {
      const netMinor = BigInt(row.net_amount_minor || 0);
      const absAmount = netMinor < 0n ? -netMinor : netMinor;
      return {
        id: row.id,
        publicId: row.public_id,
        transactionType: row.transaction_type as LedgerTransactionType,
        amountMinor: absAmount.toString(),
        netChangeMinor: netMinor.toString(),
        currency: 'BDT',
        referenceType: row.reference_type,
        referenceId: row.reference_id,
        status: row.status,
        metadata: row.metadata || {},
        createdAt: row.created_at,
        formattedAmount: (netMinor >= 0n ? '+' : '-') + formatMoney(absAmount, 'BDT'),
      };
    });

    return { transactions, total, page, limit };
  }
}

export const walletService = new WalletService();
