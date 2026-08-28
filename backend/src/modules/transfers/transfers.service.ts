import { query, withTransaction } from '../../db/client.ts';
import { checkIdempotency, saveIdempotency } from '../../middleware/idempotency.ts';
import {
  BadRequestError,
  ForbiddenError,
  InsufficientBalanceError,
  NotFoundError,
} from '../../utils/errors.ts';
import { formatMoney, toMinorUnits } from '../../utils/money.ts';
import { walletService } from '../wallet/wallet.service.ts';
import type {
  SendTransferInput,
  TransferItem,
  TransferQueryFilters,
} from './transfers.types.ts';

export class TransfersService {
  /**
   * Send money from user A to user B by username or phone with idempotency and double-entry ledger.
   */
  async sendTransfer(
    senderUserId: string,
    input: SendTransferInput,
    idempotencyKey?: string,
    reqMeta?: { ip?: string; userAgent?: string; requestId?: string }
  ) {
    const key = idempotencyKey || input.idempotencyKey;
    const amountMinor = toMinorUnits(input.amountMinor);

    if (amountMinor <= 0n) {
      throw new BadRequestError('VALIDATION_ERROR', 'Transfer amount must be greater than zero');
    }

    // Minimum transfer limit (e.g. 10 BDT = 1000 minor units)
    if (amountMinor < 1000n) {
      throw new BadRequestError(
        'VALIDATION_ERROR',
        `Minimum transfer amount is ${formatMoney(1000n, 'BDT')}`
      );
    }

    // Check Idempotency if key supplied
    if (key) {
      const existing = await checkIdempotency(
        senderUserId,
        'WALLET_TRANSFER',
        key,
        { recipient: input.recipient, amountMinor: amountMinor.toString(), note: input.note }
      );
      if (existing) {
        return existing.responseBody;
      }
    }

    // 1. Verify sender profile and status
    const senderRes = await query(
      `SELECT user_id, username, phone, status FROM profiles WHERE user_id = $1`,
      [senderUserId]
    );

    if (senderRes.rows.length === 0) {
      throw new NotFoundError('Sender user profile not found');
    }

    const sender = senderRes.rows[0];
    if (sender.status !== 'ACTIVE') {
      throw new ForbiddenError(`Sender account is ${sender.status.toLowerCase()}`);
    }

    // 2. Resolve recipient by username or phone
    const cleanRecipient = input.recipient.trim();
    const recipientRes = await query(
      `SELECT user_id, username, phone, status
       FROM profiles
       WHERE lower(username) = lower($1) OR phone = $1`,
      [cleanRecipient]
    );

    if (recipientRes.rows.length === 0) {
      throw new NotFoundError(`Recipient '${cleanRecipient}' not found`);
    }

    const recipient = recipientRes.rows[0];

    // 3. Self-transfer validation
    if (recipient.user_id === senderUserId) {
      throw new BadRequestError('SELF_TRANSFER_PROHIBITED', 'Cannot transfer money to yourself');
    }

    // 4. Recipient status check
    if (recipient.status !== 'ACTIVE') {
      throw new ForbiddenError(`Recipient account is ${recipient.status.toLowerCase()}`);
    }

    // Transfer fee configuration (Default: 0 for internal transfers)
    const feeMinor = 0n;
    const totalDeduction = amountMinor + feeMinor;

    // 5. Execute transfer atomically inside DB transaction
    const result = await withTransaction(async (client) => {
      // Ensure wallets exist
      await walletService.getOrCreateWallet(senderUserId, client);
      await walletService.getOrCreateWallet(recipient.user_id, client);

      // Lock sender and receiver wallets in consistent deterministic order to avoid deadlocks
      const [firstUserId, secondUserId] =
        senderUserId < recipient.user_id
          ? [senderUserId, recipient.user_id]
          : [recipient.user_id, senderUserId];

      await client.query(`SELECT id FROM wallets WHERE user_id = $1 FOR UPDATE`, [firstUserId]);
      await client.query(`SELECT id FROM wallets WHERE user_id = $2 FOR UPDATE`, [secondUserId]);

      // Read sender wallet balance
      const senderWalletRes = await client.query(
        `SELECT id, available_balance_minor, currency FROM wallets WHERE user_id = $1`,
        [senderUserId]
      );
      const senderWallet = senderWalletRes.rows[0];
      const senderAvailable = BigInt(senderWallet.available_balance_minor);

      if (senderAvailable < totalDeduction) {
        throw new InsufficientBalanceError(
          `Insufficient balance. Available: ${formatMoney(senderAvailable, 'BDT')}, Required: ${formatMoney(totalDeduction, 'BDT')}`
        );
      }

      // Ledger Accounts
      const senderAvailableAcc = await walletService.getOrCreateLedgerAccount(
        'USER',
        senderUserId,
        'USER_AVAILABLE',
        'BDT',
        client
      );

      const receiverAvailableAcc = await walletService.getOrCreateLedgerAccount(
        'USER',
        recipient.user_id,
        'USER_AVAILABLE',
        'BDT',
        client
      );

      const ledgerEntries = [
        { accountId: senderAvailableAcc.id, amountMinor: -totalDeduction },
        { accountId: receiverAvailableAcc.id, amountMinor: amountMinor },
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
        transactionType: 'USER_TRANSFER',
        referenceType: 'wallet_transfers',
        idempotencyKey: key,
        createdBy: senderUserId,
        metadata: {
          senderUserId,
          senderUsername: sender.username,
          receiverUserId: recipient.user_id,
          receiverUsername: recipient.username,
          amountMinor: amountMinor.toString(),
          feeMinor: feeMinor.toString(),
          note: input.note,
        },
        entries: ledgerEntries,
      });

      // Update sender wallet available balance
      const updatedSenderWallet = await client.query(
        `UPDATE wallets
         SET available_balance_minor = available_balance_minor - $1,
             version = version + 1,
             updated_at = now()
         WHERE user_id = $2
         RETURNING available_balance_minor`,
        [totalDeduction.toString(), senderUserId]
      );

      // Update receiver wallet available balance
      await client.query(
        `UPDATE wallets
         SET available_balance_minor = available_balance_minor + $1,
             version = version + 1,
             updated_at = now()
         WHERE user_id = $2`,
        [amountMinor.toString(), recipient.user_id]
      );

      // Insert wallet_transfers record
      const transferRes = await client.query(
        `INSERT INTO wallet_transfers (
           sender_user_id, receiver_user_id, amount_minor, fee_minor, status, ledger_transaction_id, idempotency_key, note, completed_at
         ) VALUES ($1, $2, $3, $4, 'COMPLETED', $5, $6, $7, now())
         RETURNING id, public_id, created_at, completed_at`,
        [
          senderUserId,
          recipient.user_id,
          amountMinor.toString(),
          feeMinor.toString(),
          ledgerTx.id,
          key || null,
          input.note || null,
        ]
      );

      const transfer = transferRes.rows[0];

      // Insert audit log
      await client.query(
        `INSERT INTO audit_logs (
           actor_user_id, action, entity_type, entity_id, new_values, ip_address, user_agent, request_id
         ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
        [
          senderUserId,
          'WALLET_TRANSFER',
          'wallet_transfers',
          transfer.id.toString(),
          JSON.stringify({
            publicId: transfer.public_id,
            receiverUserId: recipient.user_id,
            receiverUsername: recipient.username,
            amountMinor: amountMinor.toString(),
            feeMinor: feeMinor.toString(),
            ledgerTransactionId: ledgerTx.id,
          }),
          reqMeta?.ip || null,
          reqMeta?.userAgent || null,
          reqMeta?.requestId || null,
        ]
      );

      const responsePayload = {
        transferId: transfer.public_id,
        sender: {
          userId: senderUserId,
          username: sender.username,
        },
        recipient: {
          userId: recipient.user_id,
          username: recipient.username,
        },
        amountMinor: amountMinor.toString(),
        feeMinor: feeMinor.toString(),
        formattedAmount: formatMoney(amountMinor, 'BDT'),
        formattedFee: formatMoney(feeMinor, 'BDT'),
        note: input.note || null,
        status: 'COMPLETED',
        createdAt: transfer.created_at,
        completedAt: transfer.completed_at,
        newAvailableBalance: {
          minor: updatedSenderWallet.rows[0].available_balance_minor,
          formatted: formatMoney(updatedSenderWallet.rows[0].available_balance_minor, 'BDT'),
        },
      };

      if (key) {
        await saveIdempotency(
          senderUserId,
          'WALLET_TRANSFER',
          key,
          { recipient: input.recipient, amountMinor: amountMinor.toString(), note: input.note },
          200,
          responsePayload,
          client
        );
      }

      return responsePayload;
    });

    return result;
  }

  /**
   * Retrieves user's sent and received transfers with pagination.
   */
  async getUserTransfers(
    userId: string,
    filters: TransferQueryFilters
  ): Promise<{ transfers: TransferItem[]; total: number; page: number; limit: number }> {
    const page = Math.max(1, filters.page || 1);
    const limit = Math.min(100, Math.max(1, filters.limit || 20));
    const offset = (page - 1) * limit;

    const conditions: string[] = [];
    const params: any[] = [];

    if (filters.direction === 'SENT') {
      params.push(userId);
      conditions.push(`wt.sender_user_id = $${params.length}`);
    } else if (filters.direction === 'RECEIVED') {
      params.push(userId);
      conditions.push(`wt.receiver_user_id = $${params.length}`);
    } else {
      params.push(userId);
      conditions.push(`(wt.sender_user_id = $${params.length} OR wt.receiver_user_id = $${params.length})`);
    }

    if (filters.status) {
      params.push(filters.status);
      conditions.push(`wt.status = $${params.length}`);
    }

    if (filters.fromDate) {
      params.push(new Date(filters.fromDate));
      conditions.push(`wt.created_at >= $${params.length}`);
    }

    if (filters.toDate) {
      params.push(new Date(filters.toDate));
      conditions.push(`wt.created_at <= $${params.length}`);
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

    const countRes = await query(
      `SELECT count(*) as total FROM wallet_transfers wt ${whereClause}`,
      params
    );
    const total = parseInt(countRes.rows[0]?.total || '0', 10);

    const listParams = [...params, limit, offset];
    const listRes = await query(
      `SELECT 
         wt.id,
         wt.public_id,
         wt.sender_user_id,
         sp.username as sender_username,
         wt.receiver_user_id,
         rp.username as receiver_username,
         wt.amount_minor,
         wt.fee_minor,
         wt.status,
         wt.note,
         wt.created_at,
         wt.completed_at
       FROM wallet_transfers wt
       JOIN profiles sp ON wt.sender_user_id = sp.user_id
       JOIN profiles rp ON wt.receiver_user_id = rp.user_id
       ${whereClause}
       ORDER BY wt.created_at DESC
       LIMIT $${listParams.length - 1} OFFSET $${listParams.length}`,
      listParams
    );

    const transfers: TransferItem[] = listRes.rows.map((row) => {
      const isSender = row.sender_user_id === userId;
      const amount = BigInt(row.amount_minor);
      const fee = BigInt(row.fee_minor);
      return {
        id: row.id,
        publicId: row.public_id,
        senderUserId: row.sender_user_id,
        senderUsername: row.sender_username,
        receiverUserId: row.receiver_user_id,
        receiverUsername: row.receiver_username,
        amountMinor: amount.toString(),
        feeMinor: fee.toString(),
        netAmountMinor: isSender ? (amount + fee).toString() : amount.toString(),
        status: row.status,
        note: row.note,
        direction: isSender ? 'SENT' : 'RECEIVED',
        formattedAmount: formatMoney(amount, 'BDT'),
        formattedFee: formatMoney(fee, 'BDT'),
        createdAt: row.created_at,
        completedAt: row.completed_at,
      };
    });

    return { transfers, total, page, limit };
  }

  /**
   * Admin list all transfers.
   */
  async getAdminTransfers(filters: TransferQueryFilters) {
    const page = Math.max(1, filters.page || 1);
    const limit = Math.min(100, Math.max(1, filters.limit || 20));
    const offset = (page - 1) * limit;

    const conditions: string[] = [];
    const params: any[] = [];

    if (filters.status) {
      params.push(filters.status);
      conditions.push(`wt.status = $${params.length}`);
    }

    if (filters.fromDate) {
      params.push(new Date(filters.fromDate));
      conditions.push(`wt.created_at >= $${params.length}`);
    }

    if (filters.toDate) {
      params.push(new Date(filters.toDate));
      conditions.push(`wt.created_at <= $${params.length}`);
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

    const countRes = await query(
      `SELECT count(*) as total FROM wallet_transfers wt ${whereClause}`,
      params
    );
    const total = parseInt(countRes.rows[0]?.total || '0', 10);

    const listParams = [...params, limit, offset];
    const listRes = await query(
      `SELECT 
         wt.id,
         wt.public_id,
         wt.sender_user_id,
         sp.username as sender_username,
         wt.receiver_user_id,
         rp.username as receiver_username,
         wt.amount_minor,
         wt.fee_minor,
         wt.status,
         wt.note,
         wt.created_at,
         wt.completed_at
       FROM wallet_transfers wt
       JOIN profiles sp ON wt.sender_user_id = sp.user_id
       JOIN profiles rp ON wt.receiver_user_id = rp.user_id
       ${whereClause}
       ORDER BY wt.created_at DESC
       LIMIT $${listParams.length - 1} OFFSET $${listParams.length}`,
      listParams
    );

    const transfers = listRes.rows.map((row) => ({
      id: row.id,
      publicId: row.public_id,
      senderUserId: row.sender_user_id,
      senderUsername: row.sender_username,
      receiverUserId: row.receiver_user_id,
      receiverUsername: row.receiver_username,
      amountMinor: row.amount_minor,
      feeMinor: row.fee_minor,
      status: row.status,
      note: row.note,
      formattedAmount: formatMoney(row.amount_minor, 'BDT'),
      formattedFee: formatMoney(row.fee_minor, 'BDT'),
      createdAt: row.created_at,
      completedAt: row.completed_at,
    }));

    return { transfers, total, page, limit };
  }
}

export const transfersService = new TransfersService();
