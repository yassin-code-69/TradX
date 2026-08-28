import { query, withTransaction } from '../../db/client.ts';
import { checkIdempotency, saveIdempotency } from '../../middleware/idempotency.ts';
import {
  BadRequestError,
  ForbiddenError,
  InsufficientBalanceError,
  NotFoundError,
} from '../../utils/errors.ts';
import { calculateBasisPoints, formatMoney, toMinorUnits } from '../../utils/money.ts';
import { walletService } from '../wallet/wallet.service.ts';
import type {
  ApproveWithdrawalInput,
  CreateWithdrawalInput,
  RejectWithdrawalInput,
  WithdrawalItem,
  WithdrawalQueryFilters,
} from './withdrawals.types.ts';

export class WithdrawalsService {
  /**
   * Request withdrawal: locks available balance -> locked balance with double-entry ledger.
   */
  async createWithdrawalRequest(
    userId: string,
    input: CreateWithdrawalInput,
    idempotencyKey?: string,
    reqMeta?: { ip?: string; userAgent?: string; requestId?: string }
  ) {
    const key = idempotencyKey || input.idempotencyKey;
    const amountMinor = toMinorUnits(input.amountMinor);
    const methodCodeOrId = input.paymentMethodId || input.paymentMethodCode;

    // Check Idempotency if key supplied
    if (key) {
      const existing = await checkIdempotency(
        userId,
        'WITHDRAWAL_REQUEST',
        key,
        { method: methodCodeOrId, amountMinor: amountMinor.toString(), receiverAccount: input.receiverAccount }
      );
      if (existing) {
        return existing.responseBody;
      }
    }

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

    if (!paymentMethod.withdraw_enabled || paymentMethod.status !== 'ACTIVE') {
      throw new BadRequestError(
        'PAYMENT_METHOD_DISABLED',
        `Withdrawals via ${paymentMethod.name} are currently disabled`
      );
    }

    // 3. Validate withdrawal limits
    const minMinor = BigInt(paymentMethod.minimum_withdraw_minor);
    const maxMinor = BigInt(paymentMethod.maximum_withdraw_minor);

    if (amountMinor < minMinor || amountMinor > maxMinor) {
      throw new BadRequestError(
        'WITHDRAWAL_AMOUNT_OUT_OF_RANGE',
        `Withdrawal amount must be between ${formatMoney(minMinor, 'BDT')} and ${formatMoney(maxMinor, 'BDT')}`
      );
    }

    // 4. Calculate fee & net amount
    const percentFee = calculateBasisPoints(
      amountMinor,
      paymentMethod.withdraw_fee_percentage_basis_points || 0
    );
    const fixedFee = BigInt(paymentMethod.withdraw_fee_fixed_minor || 0);
    const feeMinor = percentFee + fixedFee;
    const netAmountMinor = amountMinor - feeMinor;

    if (netAmountMinor <= 0n) {
      throw new BadRequestError(
        'VALIDATION_ERROR',
        'Withdrawal amount is insufficient to cover the processing fee'
      );
    }

    // 5. Execute withdrawal locking inside DB transaction
    const result = await withTransaction(async (client) => {
      // Ensure user wallet exists and lock it
      await walletService.getOrCreateWallet(userId, client);

      const walletRes = await client.query(
        `SELECT id, available_balance_minor, locked_balance_minor, currency
         FROM wallets
         WHERE user_id = $1
         FOR UPDATE`,
        [userId]
      );

      const wallet = walletRes.rows[0];
      const availableBalance = BigInt(wallet.available_balance_minor);

      if (availableBalance < amountMinor) {
        throw new InsufficientBalanceError(
          `Insufficient available balance. Available: ${formatMoney(availableBalance, 'BDT')}, Requested: ${formatMoney(amountMinor, 'BDT')}`
        );
      }

      // Ledger Accounts: USER_AVAILABLE and USER_LOCKED
      const userAvailableAcc = await walletService.getOrCreateLedgerAccount(
        'USER',
        userId,
        'USER_AVAILABLE',
        'BDT',
        client
      );

      const userLockedAcc = await walletService.getOrCreateLedgerAccount(
        'USER',
        userId,
        'USER_LOCKED',
        'BDT',
        client
      );

      // Record lock ledger transaction
      const ledgerTx = await walletService.recordLedgerTransaction(client, {
        transactionType: 'WITHDRAWAL_LOCK',
        referenceType: 'withdrawal_requests',
        idempotencyKey: key,
        createdBy: userId,
        metadata: {
          paymentMethodCode: paymentMethod.code,
          receiverAccount: input.receiverAccount,
          amountMinor: amountMinor.toString(),
          feeMinor: feeMinor.toString(),
          netAmountMinor: netAmountMinor.toString(),
        },
        entries: [
          { accountId: userAvailableAcc.id, amountMinor: -amountMinor },
          { accountId: userLockedAcc.id, amountMinor: amountMinor },
        ],
      });

      // Update wallet balance: move amount from available to locked
      const updatedWalletRes = await client.query(
        `UPDATE wallets
         SET available_balance_minor = available_balance_minor - $1,
             locked_balance_minor = locked_balance_minor + $1,
             version = version + 1,
             updated_at = now()
         WHERE user_id = $2
         RETURNING available_balance_minor, locked_balance_minor`,
        [amountMinor.toString(), userId]
      );

      // Insert withdrawal request
      const insertRes = await client.query(
        `INSERT INTO withdrawal_requests (
           user_id, payment_method_id, receiver_account, amount_minor, fee_minor, net_amount_minor, status
         ) VALUES ($1, $2, $3, $4, $5, $6, 'PENDING')
         RETURNING id, public_id, created_at, status`,
        [
          userId,
          paymentMethod.id,
          input.receiverAccount.trim(),
          amountMinor.toString(),
          feeMinor.toString(),
          netAmountMinor.toString(),
        ]
      );

      const withdrawal = insertRes.rows[0];

      // Audit Log
      await client.query(
        `INSERT INTO audit_logs (
           actor_user_id, action, entity_type, entity_id, new_values, ip_address, user_agent, request_id
         ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
        [
          userId,
          'WITHDRAWAL_REQUEST_CREATE',
          'withdrawal_requests',
          withdrawal.id.toString(),
          JSON.stringify({
            publicId: withdrawal.public_id,
            paymentMethodCode: paymentMethod.code,
            amountMinor: amountMinor.toString(),
            feeMinor: feeMinor.toString(),
            netAmountMinor: netAmountMinor.toString(),
            receiverAccount: input.receiverAccount,
            ledgerTransactionId: ledgerTx.id,
          }),
          reqMeta?.ip || null,
          reqMeta?.userAgent || null,
          reqMeta?.requestId || null,
        ]
      );

      const responsePayload = {
        withdrawalId: withdrawal.public_id,
        paymentMethod: {
          id: paymentMethod.id,
          code: paymentMethod.code,
          name: paymentMethod.name,
        },
        receiverAccount: input.receiverAccount,
        amountMinor: amountMinor.toString(),
        feeMinor: feeMinor.toString(),
        netAmountMinor: netAmountMinor.toString(),
        formattedAmount: formatMoney(amountMinor, 'BDT'),
        formattedFee: formatMoney(feeMinor, 'BDT'),
        formattedNetAmount: formatMoney(netAmountMinor, 'BDT'),
        status: withdrawal.status,
        createdAt: withdrawal.created_at,
        updatedWallet: {
          availableMinor: updatedWalletRes.rows[0].available_balance_minor,
          lockedMinor: updatedWalletRes.rows[0].locked_balance_minor,
          formattedAvailable: formatMoney(updatedWalletRes.rows[0].available_balance_minor, 'BDT'),
          formattedLocked: formatMoney(updatedWalletRes.rows[0].locked_balance_minor, 'BDT'),
        },
      };

      if (key) {
        await saveIdempotency(
          userId,
          'WITHDRAWAL_REQUEST',
          key,
          { method: methodCodeOrId, amountMinor: amountMinor.toString(), receiverAccount: input.receiverAccount },
          201,
          responsePayload,
          client
        );
      }

      return responsePayload;
    });

    return result;
  }

  /**
   * List withdrawal requests for a user.
   */
  async getUserWithdrawals(
    userId: string,
    filters: WithdrawalQueryFilters
  ): Promise<{ withdrawals: WithdrawalItem[]; total: number; page: number; limit: number }> {
    const page = Math.max(1, filters.page || 1);
    const limit = Math.min(100, Math.max(1, filters.limit || 20));
    const offset = (page - 1) * limit;

    const conditions: string[] = ['wr.user_id = $1'];
    const params: any[] = [userId];

    if (filters.status) {
      params.push(filters.status);
      conditions.push(`wr.status = $${params.length}`);
    }

    if (filters.paymentMethodId) {
      params.push(filters.paymentMethodId);
      conditions.push(`wr.payment_method_id = $${params.length}`);
    }

    if (filters.fromDate) {
      params.push(new Date(filters.fromDate));
      conditions.push(`wr.created_at >= $${params.length}`);
    }

    if (filters.toDate) {
      params.push(new Date(filters.toDate));
      conditions.push(`wr.created_at <= $${params.length}`);
    }

    const whereClause = `WHERE ${conditions.join(' AND ')}`;

    const countRes = await query(
      `SELECT count(*) as total FROM withdrawal_requests wr ${whereClause}`,
      params
    );
    const total = parseInt(countRes.rows[0]?.total || '0', 10);

    const listParams = [...params, limit, offset];
    const listRes = await query(
      `SELECT 
         wr.id,
         wr.public_id,
         wr.user_id,
         p.username,
         wr.payment_method_id,
         pm.code as payment_method_code,
         pm.name as payment_method_name,
         wr.receiver_account,
         wr.amount_minor,
         wr.fee_minor,
         wr.net_amount_minor,
         wr.status,
         wr.reviewed_by,
         wr.reviewed_at,
         wr.completed_at,
         wr.reject_reason,
         wr.created_at,
         wr.updated_at
       FROM withdrawal_requests wr
       JOIN profiles p ON wr.user_id = p.user_id
       JOIN payment_methods pm ON wr.payment_method_id = pm.id
       ${whereClause}
       ORDER BY wr.created_at DESC
       LIMIT $${listParams.length - 1} OFFSET $${listParams.length}`,
      listParams
    );

    const withdrawals: WithdrawalItem[] = listRes.rows.map((row) => ({
      id: row.id,
      publicId: row.public_id,
      userId: row.user_id,
      username: row.username,
      paymentMethodId: row.payment_method_id,
      paymentMethodCode: row.payment_method_code,
      paymentMethodName: row.payment_method_name,
      receiverAccount: row.receiver_account,
      amountMinor: row.amount_minor,
      feeMinor: row.fee_minor,
      netAmountMinor: row.net_amount_minor,
      formattedAmount: formatMoney(row.amount_minor, 'BDT'),
      formattedFee: formatMoney(row.fee_minor, 'BDT'),
      formattedNetAmount: formatMoney(row.net_amount_minor, 'BDT'),
      status: row.status,
      reviewedBy: row.reviewed_by,
      reviewedAt: row.reviewed_at,
      completedAt: row.completed_at,
      rejectReason: row.reject_reason,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
    }));

    return { withdrawals, total, page, limit };
  }

  /**
   * Admin list all withdrawal requests.
   */
  async getAdminWithdrawals(
    filters: WithdrawalQueryFilters
  ): Promise<{ withdrawals: WithdrawalItem[]; total: number; page: number; limit: number }> {
    const page = Math.max(1, filters.page || 1);
    const limit = Math.min(100, Math.max(1, filters.limit || 20));
    const offset = (page - 1) * limit;

    const conditions: string[] = [];
    const params: any[] = [];

    if (filters.status) {
      params.push(filters.status);
      conditions.push(`wr.status = $${params.length}`);
    }

    if (filters.paymentMethodId) {
      params.push(filters.paymentMethodId);
      conditions.push(`wr.payment_method_id = $${params.length}`);
    }

    if (filters.fromDate) {
      params.push(new Date(filters.fromDate));
      conditions.push(`wr.created_at >= $${params.length}`);
    }

    if (filters.toDate) {
      params.push(new Date(filters.toDate));
      conditions.push(`wr.created_at <= $${params.length}`);
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

    const countRes = await query(
      `SELECT count(*) as total FROM withdrawal_requests wr ${whereClause}`,
      params
    );
    const total = parseInt(countRes.rows[0]?.total || '0', 10);

    const listParams = [...params, limit, offset];
    const listRes = await query(
      `SELECT 
         wr.id,
         wr.public_id,
         wr.user_id,
         p.username,
         wr.payment_method_id,
         pm.code as payment_method_code,
         pm.name as payment_method_name,
         wr.receiver_account,
         wr.amount_minor,
         wr.fee_minor,
         wr.net_amount_minor,
         wr.status,
         wr.reviewed_by,
         wr.reviewed_at,
         wr.completed_at,
         wr.reject_reason,
         wr.created_at,
         wr.updated_at
       FROM withdrawal_requests wr
       JOIN profiles p ON wr.user_id = p.user_id
       JOIN payment_methods pm ON wr.payment_method_id = pm.id
       ${whereClause}
       ORDER BY wr.created_at DESC
       LIMIT $${listParams.length - 1} OFFSET $${listParams.length}`,
      listParams
    );

    const withdrawals: WithdrawalItem[] = listRes.rows.map((row) => ({
      id: row.id,
      publicId: row.public_id,
      userId: row.user_id,
      username: row.username,
      paymentMethodId: row.payment_method_id,
      paymentMethodCode: row.payment_method_code,
      paymentMethodName: row.payment_method_name,
      receiverAccount: row.receiver_account,
      amountMinor: row.amount_minor,
      feeMinor: row.fee_minor,
      netAmountMinor: row.net_amount_minor,
      formattedAmount: formatMoney(row.amount_minor, 'BDT'),
      formattedFee: formatMoney(row.fee_minor, 'BDT'),
      formattedNetAmount: formatMoney(row.net_amount_minor, 'BDT'),
      status: row.status,
      reviewedBy: row.reviewed_by,
      reviewedAt: row.reviewed_at,
      completedAt: row.completed_at,
      rejectReason: row.reject_reason,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
    }));

    return { withdrawals, total, page, limit };
  }

  /**
   * Admin approve & complete withdrawal: debits locked balance and credits clearing ledger.
   */
  async approveWithdrawal(
    adminUserId: string,
    withdrawalIdOrPublicId: string,
    input?: ApproveWithdrawalInput,
    reqMeta?: { ip?: string; userAgent?: string; requestId?: string }
  ) {
    return await withTransaction(async (client) => {
      const isUUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(
        withdrawalIdOrPublicId
      );

      const findQuery = isUUID
        ? `SELECT * FROM withdrawal_requests WHERE public_id = $1 FOR UPDATE`
        : `SELECT * FROM withdrawal_requests WHERE id = $1 FOR UPDATE`;

      const withdrawalRes = await client.query(findQuery, [withdrawalIdOrPublicId]);

      if (withdrawalRes.rows.length === 0) {
        throw new NotFoundError(`Withdrawal request '${withdrawalIdOrPublicId}' not found`);
      }

      const withdrawal = withdrawalRes.rows[0];

      if (withdrawal.status !== 'PENDING') {
        throw new BadRequestError(
          'WITHDRAWAL_ALREADY_PROCESSED',
          `Withdrawal request has already been ${withdrawal.status.toLowerCase()}`
        );
      }

      const amountMinor = BigInt(withdrawal.amount_minor);
      const feeMinor = BigInt(withdrawal.fee_minor);
      const netAmountMinor = BigInt(withdrawal.net_amount_minor);

      // Lock user wallet and check locked balance
      await walletService.getOrCreateWallet(withdrawal.user_id, client);
      const walletRes = await client.query(
        `SELECT id, locked_balance_minor FROM wallets WHERE user_id = $1 FOR UPDATE`,
        [withdrawal.user_id]
      );
      const currentLocked = BigInt(walletRes.rows[0].locked_balance_minor);

      if (currentLocked < amountMinor) {
        throw new InsufficientBalanceError(
          `User locked balance (${formatMoney(currentLocked, 'BDT')}) is less than withdrawal amount (${formatMoney(amountMinor, 'BDT')})`
        );
      }

      // Ledger Accounts: USER_LOCKED, WITHDRAWAL_CLEARING, and PLATFORM_REVENUE (if fee)
      const userLockedAcc = await walletService.getOrCreateLedgerAccount(
        'USER',
        withdrawal.user_id,
        'USER_LOCKED',
        'BDT',
        client
      );

      const withdrawalClearingAcc = await walletService.getOrCreateLedgerAccount(
        'SYSTEM',
        'SYSTEM',
        'WITHDRAWAL_CLEARING',
        'BDT',
        client
      );

      const ledgerEntries = [
        { accountId: userLockedAcc.id, amountMinor: -amountMinor },
        { accountId: withdrawalClearingAcc.id, amountMinor: netAmountMinor },
      ];

      if (feeMinor > 0n) {
        const platformRevenueAcc = await walletService.getOrCreateLedgerAccount(
          'SYSTEM',
          'SYSTEM',
          'PLATFORM_REVENUE',
          'BDT',
          client
        );
        ledgerEntries.push({ accountId: platformRevenueAcc.id, amountMinor: feeMinor });
      }

      // Record double-entry ledger transaction
      const ledgerTx = await walletService.recordLedgerTransaction(client, {
        transactionType: 'WITHDRAWAL',
        referenceType: 'withdrawal_requests',
        referenceId: withdrawal.id.toString(),
        createdBy: adminUserId,
        metadata: {
          withdrawalRequestId: withdrawal.id.toString(),
          withdrawalPublicId: withdrawal.public_id,
          receiverAccount: withdrawal.receiver_account,
          transactionReference: input?.transactionReference,
          adminNote: input?.note,
        },
        entries: ledgerEntries,
      });

      // Update user wallet balance: deduct amount from locked balance
      const updatedWalletRes = await client.query(
        `UPDATE wallets
         SET locked_balance_minor = locked_balance_minor - $1,
             version = version + 1,
             updated_at = now()
         WHERE user_id = $2
         RETURNING available_balance_minor, locked_balance_minor`,
        [amountMinor.toString(), withdrawal.user_id]
      );

      // Update withdrawal request
      const updatedWithdrawalRes = await client.query(
        `UPDATE withdrawal_requests
         SET status = 'APPROVED',
             reviewed_by = $1,
             reviewed_at = now(),
             completed_at = now(),
             ledger_transaction_id = $2,
             updated_at = now()
         WHERE id = $3
         RETURNING id, public_id, status, reviewed_at, completed_at, ledger_transaction_id`,
        [adminUserId, ledgerTx.id, withdrawal.id]
      );

      const updatedWithdrawal = updatedWithdrawalRes.rows[0];

      // Audit Log
      await client.query(
        `INSERT INTO audit_logs (
           actor_user_id, action, entity_type, entity_id, old_values, new_values, ip_address, user_agent, request_id
         ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
        [
          adminUserId,
          'WITHDRAWAL_APPROVE',
          'withdrawal_requests',
          withdrawal.id.toString(),
          JSON.stringify({ status: 'PENDING' }),
          JSON.stringify({
            status: 'APPROVED',
            amountMinor: amountMinor.toString(),
            feeMinor: feeMinor.toString(),
            netAmountMinor: netAmountMinor.toString(),
            transactionReference: input?.transactionReference,
            ledgerTransactionId: ledgerTx.id,
            adminNote: input?.note,
          }),
          reqMeta?.ip || null,
          reqMeta?.userAgent || null,
          reqMeta?.requestId || null,
        ]
      );

      return {
        withdrawalId: updatedWithdrawal.public_id,
        status: updatedWithdrawal.status,
        amountMinor: amountMinor.toString(),
        netAmountMinor: netAmountMinor.toString(),
        formattedAmount: formatMoney(amountMinor, 'BDT'),
        formattedNetAmount: formatMoney(netAmountMinor, 'BDT'),
        completedAt: updatedWithdrawal.completed_at,
        ledgerTransactionId: ledgerTx.public_id,
        userWallet: {
          availableMinor: updatedWalletRes.rows[0].available_balance_minor,
          lockedMinor: updatedWalletRes.rows[0].locked_balance_minor,
        },
      };
    });
  }

  /**
   * Admin reject withdrawal request: releases locked balance back to available balance.
   */
  async rejectWithdrawal(
    adminUserId: string,
    withdrawalIdOrPublicId: string,
    input: RejectWithdrawalInput,
    reqMeta?: { ip?: string; userAgent?: string; requestId?: string }
  ) {
    return await withTransaction(async (client) => {
      const isUUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(
        withdrawalIdOrPublicId
      );

      const findQuery = isUUID
        ? `SELECT * FROM withdrawal_requests WHERE public_id = $1 FOR UPDATE`
        : `SELECT * FROM withdrawal_requests WHERE id = $1 FOR UPDATE`;

      const withdrawalRes = await client.query(findQuery, [withdrawalIdOrPublicId]);

      if (withdrawalRes.rows.length === 0) {
        throw new NotFoundError(`Withdrawal request '${withdrawalIdOrPublicId}' not found`);
      }

      const withdrawal = withdrawalRes.rows[0];

      if (withdrawal.status !== 'PENDING') {
        throw new BadRequestError(
          'WITHDRAWAL_ALREADY_PROCESSED',
          `Withdrawal request has already been ${withdrawal.status.toLowerCase()}`
        );
      }

      const amountMinor = BigInt(withdrawal.amount_minor);

      // Lock user wallet
      await walletService.getOrCreateWallet(withdrawal.user_id, client);
      const walletRes = await client.query(
        `SELECT id, locked_balance_minor FROM wallets WHERE user_id = $1 FOR UPDATE`,
        [withdrawal.user_id]
      );
      const currentLocked = BigInt(walletRes.rows[0].locked_balance_minor);

      if (currentLocked < amountMinor) {
        throw new InsufficientBalanceError(
          `User locked balance (${formatMoney(currentLocked, 'BDT')}) is less than withdrawal amount (${formatMoney(amountMinor, 'BDT')})`
        );
      }

      // Ledger Accounts: USER_LOCKED to USER_AVAILABLE
      const userLockedAcc = await walletService.getOrCreateLedgerAccount(
        'USER',
        withdrawal.user_id,
        'USER_LOCKED',
        'BDT',
        client
      );

      const userAvailableAcc = await walletService.getOrCreateLedgerAccount(
        'USER',
        withdrawal.user_id,
        'USER_AVAILABLE',
        'BDT',
        client
      );

      // Record double-entry reversal ledger transaction
      const ledgerTx = await walletService.recordLedgerTransaction(client, {
        transactionType: 'WITHDRAWAL_REJECT',
        referenceType: 'withdrawal_requests',
        referenceId: withdrawal.id.toString(),
        createdBy: adminUserId,
        metadata: {
          withdrawalRequestId: withdrawal.id.toString(),
          withdrawalPublicId: withdrawal.public_id,
          rejectReason: input.reason,
        },
        entries: [
          { accountId: userLockedAcc.id, amountMinor: -amountMinor },
          { accountId: userAvailableAcc.id, amountMinor: amountMinor },
        ],
      });

      // Release locked balance back into available balance
      const updatedWalletRes = await client.query(
        `UPDATE wallets
         SET locked_balance_minor = locked_balance_minor - $1,
             available_balance_minor = available_balance_minor + $1,
             version = version + 1,
             updated_at = now()
         WHERE user_id = $2
         RETURNING available_balance_minor, locked_balance_minor`,
        [amountMinor.toString(), withdrawal.user_id]
      );

      // Update withdrawal request
      const updatedWithdrawalRes = await client.query(
        `UPDATE withdrawal_requests
         SET status = 'REJECTED',
             reviewed_by = $1,
             reviewed_at = now(),
             reject_reason = $2,
             ledger_transaction_id = $3,
             updated_at = now()
         WHERE id = $4
         RETURNING id, public_id, status, reviewed_at, reject_reason`,
        [adminUserId, input.reason.trim(), ledgerTx.id, withdrawal.id]
      );

      const updatedWithdrawal = updatedWithdrawalRes.rows[0];

      // Audit Log
      await client.query(
        `INSERT INTO audit_logs (
           actor_user_id, action, entity_type, entity_id, old_values, new_values, ip_address, user_agent, request_id
         ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
        [
          adminUserId,
          'WITHDRAWAL_REJECT',
          'withdrawal_requests',
          withdrawal.id.toString(),
          JSON.stringify({ status: 'PENDING' }),
          JSON.stringify({
            status: 'REJECTED',
            rejectReason: input.reason,
            releasedAmountMinor: amountMinor.toString(),
            ledgerTransactionId: ledgerTx.id,
          }),
          reqMeta?.ip || null,
          reqMeta?.userAgent || null,
          reqMeta?.requestId || null,
        ]
      );

      return {
        withdrawalId: updatedWithdrawal.public_id,
        status: updatedWithdrawal.status,
        rejectReason: updatedWithdrawal.reject_reason,
        reviewedAt: updatedWithdrawal.reviewed_at,
        userWallet: {
          availableMinor: updatedWalletRes.rows[0].available_balance_minor,
          lockedMinor: updatedWalletRes.rows[0].locked_balance_minor,
          formattedAvailable: formatMoney(updatedWalletRes.rows[0].available_balance_minor, 'BDT'),
        },
      };
    });
  }
}

export const withdrawalsService = new WithdrawalsService();
