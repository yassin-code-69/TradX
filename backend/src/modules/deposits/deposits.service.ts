import { query, withTransaction } from '../../db/client.ts';
import {
  BadRequestError,
  ConflictError,
  ForbiddenError,
  NotFoundError,
} from '../../utils/errors.ts';
import { formatMoney, toMinorUnits } from '../../utils/money.ts';
import { walletService } from '../wallet/wallet.service.ts';
import type {
  ApproveDepositInput,
  CreateDepositInput,
  DepositItem,
  DepositQueryFilters,
  RejectDepositInput,
} from './deposits.types.ts';

export class DepositsService {
  /**
   * Submit manual deposit request.
   */
  async createDepositRequest(
    userId: string,
    input: CreateDepositInput,
    reqMeta?: { ip?: string; userAgent?: string; requestId?: string }
  ) {
    const amountMinor = toMinorUnits(input.amountMinor);
    const trxId = (input.providerTransactionId || input.trxId || '').trim();
    const methodCodeOrId = input.paymentMethodId || input.paymentMethodCode || input.method;

    // 1. Verify user profile
    const userRes = await query(
      `SELECT user_id, username, status FROM profiles WHERE user_id = $1`,
      [userId]
    );
    if (userRes.rows.length === 0) {
      throw new NotFoundError('User profile not found');
    }
    if (userRes.rows[0].status !== 'ACTIVE') {
      throw new ForbiddenError('User account is not active');
    }

    // 2. Fetch payment method
    let pmRes;
    if (typeof methodCodeOrId === 'number' || /^\d+$/.test(String(methodCodeOrId))) {
      pmRes = await query(`SELECT * FROM payment_methods WHERE id = $1`, [methodCodeOrId]);
    } else {
      pmRes = await query(`SELECT * FROM payment_methods WHERE upper(code) = upper($1)`, [
        String(methodCodeOrId),
      ]);
    }

    if (pmRes.rows.length === 0) {
      throw new NotFoundError(`Payment method '${methodCodeOrId}' not found`);
    }

    const paymentMethod = pmRes.rows[0];

    if (!paymentMethod.deposit_enabled || paymentMethod.status !== 'ACTIVE') {
      throw new BadRequestError(
        'PAYMENT_METHOD_DISABLED',
        `Deposits via ${paymentMethod.name} are currently disabled`
      );
    }

    // 3. Validate deposit amount limits
    const minMinor = BigInt(paymentMethod.minimum_deposit_minor);
    const maxMinor = BigInt(paymentMethod.maximum_deposit_minor);

    if (amountMinor < minMinor || amountMinor > maxMinor) {
      throw new BadRequestError(
        'DEPOSIT_AMOUNT_OUT_OF_RANGE',
        `Deposit amount must be between ${formatMoney(minMinor, 'BDT')} and ${formatMoney(maxMinor, 'BDT')}`
      );
    }

    // 4. Duplicate transaction ID check
    const dupRes = await query(
      `SELECT id FROM deposit_requests
       WHERE payment_method_id = $1 AND lower(provider_transaction_id) = lower($2)
         AND status IN ('PENDING', 'APPROVED')`,
      [paymentMethod.id, trxId]
    );

    if (dupRes.rows.length > 0) {
      throw new ConflictError(
        'DUPLICATE_TRANSACTION_ID',
        `A deposit with transaction ID '${trxId}' has already been submitted`
      );
    }

    // 5. Insert deposit request
    const insertRes = await query(
      `INSERT INTO deposit_requests (
         user_id, payment_method_id, amount_minor, sender_account, provider_transaction_id, proof_asset_id, status
       ) VALUES ($1, $2, $3, $4, $5, $6, 'PENDING')
       RETURNING id, public_id, created_at, status`,
      [
        userId,
        paymentMethod.id,
        amountMinor.toString(),
        input.senderAccount.trim(),
        trxId,
        input.proofAssetId ? String(input.proofAssetId) : null,
      ]
    );

    const deposit = insertRes.rows[0];

    // Audit log
    await query(
      `INSERT INTO audit_logs (
         actor_user_id, action, entity_type, entity_id, new_values, ip_address, user_agent, request_id
       ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [
        userId,
        'DEPOSIT_REQUEST_CREATE',
        'deposit_requests',
        deposit.id.toString(),
        JSON.stringify({
          publicId: deposit.public_id,
          paymentMethodCode: paymentMethod.code,
          amountMinor: amountMinor.toString(),
          senderAccount: input.senderAccount,
          providerTransactionId: trxId,
        }),
        reqMeta?.ip || null,
        reqMeta?.userAgent || null,
        reqMeta?.requestId || null,
      ]
    );

    return {
      depositId: deposit.public_id,
      paymentMethod: {
        id: paymentMethod.id,
        code: paymentMethod.code,
        name: paymentMethod.name,
      },
      amountMinor: amountMinor.toString(),
      formattedAmount: formatMoney(amountMinor, 'BDT'),
      senderAccount: input.senderAccount,
      providerTransactionId: trxId,
      status: deposit.status,
      createdAt: deposit.created_at,
    };
  }

  /**
   * List deposit requests for a specific user.
   */
  async getUserDeposits(
    userId: string,
    filters: DepositQueryFilters
  ): Promise<{ deposits: DepositItem[]; total: number; page: number; limit: number }> {
    const page = Math.max(1, filters.page || 1);
    const limit = Math.min(100, Math.max(1, filters.limit || 20));
    const offset = (page - 1) * limit;

    const conditions: string[] = ['dr.user_id = $1'];
    const params: any[] = [userId];

    if (filters.status) {
      params.push(filters.status);
      conditions.push(`dr.status = $${params.length}`);
    }

    if (filters.paymentMethodId) {
      params.push(filters.paymentMethodId);
      conditions.push(`dr.payment_method_id = $${params.length}`);
    }

    if (filters.fromDate) {
      params.push(new Date(filters.fromDate));
      conditions.push(`dr.created_at >= $${params.length}`);
    }

    if (filters.toDate) {
      params.push(new Date(filters.toDate));
      conditions.push(`dr.created_at <= $${params.length}`);
    }

    const whereClause = `WHERE ${conditions.join(' AND ')}`;

    const countRes = await query(
      `SELECT count(*) as total FROM deposit_requests dr ${whereClause}`,
      params
    );
    const total = parseInt(countRes.rows[0]?.total || '0', 10);

    const listParams = [...params, limit, offset];
    const listRes = await query(
      `SELECT 
         dr.id,
         dr.public_id,
         dr.user_id,
         p.username,
         dr.payment_method_id,
         pm.code as payment_method_code,
         pm.name as payment_method_name,
         dr.amount_minor,
         dr.sender_account,
         dr.provider_transaction_id,
         dr.proof_asset_id,
         dr.status,
         dr.reviewed_by,
         dr.reviewed_at,
         dr.reject_reason,
         dr.created_at,
         dr.updated_at
       FROM deposit_requests dr
       JOIN profiles p ON dr.user_id = p.user_id
       JOIN payment_methods pm ON dr.payment_method_id = pm.id
       ${whereClause}
       ORDER BY dr.created_at DESC
       LIMIT $${listParams.length - 1} OFFSET $${listParams.length}`,
      listParams
    );

    const deposits: DepositItem[] = listRes.rows.map((row) => ({
      id: row.id,
      publicId: row.public_id,
      userId: row.user_id,
      username: row.username,
      paymentMethodId: row.payment_method_id,
      paymentMethodCode: row.payment_method_code,
      paymentMethodName: row.payment_method_name,
      amountMinor: row.amount_minor,
      formattedAmount: formatMoney(row.amount_minor, 'BDT'),
      senderAccount: row.sender_account,
      providerTransactionId: row.provider_transaction_id,
      proofAssetId: row.proof_asset_id,
      status: row.status,
      reviewedBy: row.reviewed_by,
      reviewedAt: row.reviewed_at,
      rejectReason: row.reject_reason,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
    }));

    return { deposits, total, page, limit };
  }

  /**
   * Admin list all deposit requests.
   */
  async getAdminDeposits(
    filters: DepositQueryFilters
  ): Promise<{ deposits: DepositItem[]; total: number; page: number; limit: number }> {
    const page = Math.max(1, filters.page || 1);
    const limit = Math.min(100, Math.max(1, filters.limit || 20));
    const offset = (page - 1) * limit;

    const conditions: string[] = [];
    const params: any[] = [];

    if (filters.status) {
      params.push(filters.status);
      conditions.push(`dr.status = $${params.length}`);
    }

    if (filters.paymentMethodId) {
      params.push(filters.paymentMethodId);
      conditions.push(`dr.payment_method_id = $${params.length}`);
    }

    if (filters.fromDate) {
      params.push(new Date(filters.fromDate));
      conditions.push(`dr.created_at >= $${params.length}`);
    }

    if (filters.toDate) {
      params.push(new Date(filters.toDate));
      conditions.push(`dr.created_at <= $${params.length}`);
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

    const countRes = await query(
      `SELECT count(*) as total FROM deposit_requests dr ${whereClause}`,
      params
    );
    const total = parseInt(countRes.rows[0]?.total || '0', 10);

    const listParams = [...params, limit, offset];
    const listRes = await query(
      `SELECT 
         dr.id,
         dr.public_id,
         dr.user_id,
         p.username,
         dr.payment_method_id,
         pm.code as payment_method_code,
         pm.name as payment_method_name,
         dr.amount_minor,
         dr.sender_account,
         dr.provider_transaction_id,
         dr.proof_asset_id,
         dr.status,
         dr.reviewed_by,
         dr.reviewed_at,
         dr.reject_reason,
         dr.created_at,
         dr.updated_at
       FROM deposit_requests dr
       JOIN profiles p ON dr.user_id = p.user_id
       JOIN payment_methods pm ON dr.payment_method_id = pm.id
       ${whereClause}
       ORDER BY dr.created_at DESC
       LIMIT $${listParams.length - 1} OFFSET $${listParams.length}`,
      listParams
    );

    const deposits: DepositItem[] = listRes.rows.map((row) => ({
      id: row.id,
      publicId: row.public_id,
      userId: row.user_id,
      username: row.username,
      paymentMethodId: row.payment_method_id,
      paymentMethodCode: row.payment_method_code,
      paymentMethodName: row.payment_method_name,
      amountMinor: row.amount_minor,
      formattedAmount: formatMoney(row.amount_minor, 'BDT'),
      senderAccount: row.sender_account,
      providerTransactionId: row.provider_transaction_id,
      proofAssetId: row.proof_asset_id,
      status: row.status,
      reviewedBy: row.reviewed_by,
      reviewedAt: row.reviewed_at,
      rejectReason: row.reject_reason,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
    }));

    return { deposits, total, page, limit };
  }

  /**
   * Admin approve deposit request: atomically credits user wallet and creates ledger entries.
   */
  async approveDeposit(
    adminUserId: string,
    depositIdOrPublicId: string,
    input?: ApproveDepositInput,
    reqMeta?: { ip?: string; userAgent?: string; requestId?: string }
  ) {
    return await withTransaction(async (client) => {
      // Find and lock deposit request
      const isUUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(
        depositIdOrPublicId
      );

      const findQuery = isUUID
        ? `SELECT * FROM deposit_requests WHERE public_id = $1 FOR UPDATE`
        : `SELECT * FROM deposit_requests WHERE id = $1 FOR UPDATE`;

      const depositRes = await client.query(findQuery, [depositIdOrPublicId]);

      if (depositRes.rows.length === 0) {
        throw new NotFoundError(`Deposit request '${depositIdOrPublicId}' not found`);
      }

      const deposit = depositRes.rows[0];

      if (deposit.status !== 'PENDING') {
        throw new BadRequestError(
          'DEPOSIT_ALREADY_PROCESSED',
          `Deposit request has already been ${deposit.status.toLowerCase()}`
        );
      }

      const amountMinor = BigInt(deposit.amount_minor);

      // Ensure user wallet exists and lock it
      await walletService.getOrCreateWallet(deposit.user_id, client);
      const walletRes = await client.query(
        `SELECT id, available_balance_minor FROM wallets WHERE user_id = $1 FOR UPDATE`,
        [deposit.user_id]
      );
      const previousBalance = BigInt(walletRes.rows[0].available_balance_minor);

      // Ledger Accounts: DEPOSIT_CLEARING (System) and USER_AVAILABLE (User)
      const depositClearingAcc = await walletService.getOrCreateLedgerAccount(
        'SYSTEM',
        'SYSTEM',
        'DEPOSIT_CLEARING',
        'BDT',
        client
      );

      const userAvailableAcc = await walletService.getOrCreateLedgerAccount(
        'USER',
        deposit.user_id,
        'USER_AVAILABLE',
        'BDT',
        client
      );

      // Create double-entry ledger transaction
      const ledgerTx = await walletService.recordLedgerTransaction(client, {
        transactionType: 'DEPOSIT',
        referenceType: 'deposit_requests',
        referenceId: deposit.id.toString(),
        createdBy: adminUserId,
        metadata: {
          depositRequestId: deposit.id.toString(),
          depositPublicId: deposit.public_id,
          providerTransactionId: deposit.provider_transaction_id,
          senderAccount: deposit.sender_account,
          adminNote: input?.note,
        },
        entries: [
          { accountId: depositClearingAcc.id, amountMinor: -amountMinor },
          { accountId: userAvailableAcc.id, amountMinor: amountMinor },
        ],
      });

      // Update user wallet balance
      const updatedWalletRes = await client.query(
        `UPDATE wallets
         SET available_balance_minor = available_balance_minor + $1,
             version = version + 1,
             updated_at = now()
         WHERE user_id = $2
         RETURNING available_balance_minor, currency`,
        [amountMinor.toString(), deposit.user_id]
      );

      // Update deposit request status
      const updatedDepositRes = await client.query(
        `UPDATE deposit_requests
         SET status = 'APPROVED',
             reviewed_by = $1,
             reviewed_at = now(),
             ledger_transaction_id = $2,
             updated_at = now()
         WHERE id = $3
         RETURNING id, public_id, status, reviewed_at, ledger_transaction_id`,
        [adminUserId, ledgerTx.id, deposit.id]
      );

      const updatedDeposit = updatedDepositRes.rows[0];

      // Record Audit Log
      await client.query(
        `INSERT INTO audit_logs (
           actor_user_id, action, entity_type, entity_id, old_values, new_values, ip_address, user_agent, request_id
         ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
        [
          adminUserId,
          'DEPOSIT_APPROVE',
          'deposit_requests',
          deposit.id.toString(),
          JSON.stringify({ status: 'PENDING' }),
          JSON.stringify({
            status: 'APPROVED',
            amountMinor: amountMinor.toString(),
            ledgerTransactionId: ledgerTx.id,
            previousUserBalance: previousBalance.toString(),
            newUserBalance: updatedWalletRes.rows[0].available_balance_minor,
            adminNote: input?.note,
          }),
          reqMeta?.ip || null,
          reqMeta?.userAgent || null,
          reqMeta?.requestId || null,
        ]
      );

      return {
        depositId: updatedDeposit.public_id,
        status: updatedDeposit.status,
        amountMinor: amountMinor.toString(),
        formattedAmount: formatMoney(amountMinor, 'BDT'),
        reviewedAt: updatedDeposit.reviewed_at,
        ledgerTransactionId: ledgerTx.public_id,
        userNewBalance: {
          availableMinor: updatedWalletRes.rows[0].available_balance_minor,
          formatted: formatMoney(updatedWalletRes.rows[0].available_balance_minor, 'BDT'),
        },
      };
    });
  }

  /**
   * Admin reject deposit request with reason.
   */
  async rejectDeposit(
    adminUserId: string,
    depositIdOrPublicId: string,
    input: RejectDepositInput,
    reqMeta?: { ip?: string; userAgent?: string; requestId?: string }
  ) {
    return await withTransaction(async (client) => {
      const isUUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(
        depositIdOrPublicId
      );

      const findQuery = isUUID
        ? `SELECT * FROM deposit_requests WHERE public_id = $1 FOR UPDATE`
        : `SELECT * FROM deposit_requests WHERE id = $1 FOR UPDATE`;

      const depositRes = await client.query(findQuery, [depositIdOrPublicId]);

      if (depositRes.rows.length === 0) {
        throw new NotFoundError(`Deposit request '${depositIdOrPublicId}' not found`);
      }

      const deposit = depositRes.rows[0];

      if (deposit.status !== 'PENDING') {
        throw new BadRequestError(
          'DEPOSIT_ALREADY_PROCESSED',
          `Deposit request has already been ${deposit.status.toLowerCase()}`
        );
      }

      const updatedDepositRes = await client.query(
        `UPDATE deposit_requests
         SET status = 'REJECTED',
             reviewed_by = $1,
             reviewed_at = now(),
             reject_reason = $2,
             updated_at = now()
         WHERE id = $3
         RETURNING id, public_id, status, reviewed_at, reject_reason`,
        [adminUserId, input.reason.trim(), deposit.id]
      );

      const updatedDeposit = updatedDepositRes.rows[0];

      // Audit Log
      await client.query(
        `INSERT INTO audit_logs (
           actor_user_id, action, entity_type, entity_id, old_values, new_values, ip_address, user_agent, request_id
         ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
        [
          adminUserId,
          'DEPOSIT_REJECT',
          'deposit_requests',
          deposit.id.toString(),
          JSON.stringify({ status: 'PENDING' }),
          JSON.stringify({
            status: 'REJECTED',
            rejectReason: input.reason,
          }),
          reqMeta?.ip || null,
          reqMeta?.userAgent || null,
          reqMeta?.requestId || null,
        ]
      );

      return {
        depositId: updatedDeposit.public_id,
        status: updatedDeposit.status,
        rejectReason: updatedDeposit.reject_reason,
        reviewedAt: updatedDeposit.reviewed_at,
      };
    });
  }
}

export const depositsService = new DepositsService();
