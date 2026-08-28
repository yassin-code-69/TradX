import { describe, expect, it } from 'bun:test';
import {
  approveDepositSchema,
  createDepositSchema,
  rejectDepositSchema,
} from '../src/modules/deposits/deposits.schema.ts';
import {
  createPaymentMethodSchema,
  updatePaymentMethodSchema,
} from '../src/modules/settings/payment-methods.schema.ts';
import { sendTransferSchema } from '../src/modules/transfers/transfers.schema.ts';
import { adminAdjustBalanceSchema } from '../src/modules/wallet/wallet.schema.ts';
import {
  approveWithdrawalSchema,
  createWithdrawalSchema,
  rejectWithdrawalSchema,
} from '../src/modules/withdrawals/withdrawals.schema.ts';

describe('Zod Validation Schemas', () => {
  describe('Wallet Schemas', () => {
    it('validates admin adjust balance schema correctly', () => {
      const valid = {
        userId: '11111111-1111-4111-8111-111111111111',
        amountMinor: 50000,
        type: 'CREDIT',
        reason: 'Bonus deposit for competition',
      };
      const result = adminAdjustBalanceSchema.safeParse(valid);
      expect(result.success).toBe(true);

      const invalidType = { ...valid, type: 'UNKNOWN' };
      expect(adminAdjustBalanceSchema.safeParse(invalidType).success).toBe(false);

      const invalidUserId = { ...valid, userId: 'not-a-uuid' };
      expect(adminAdjustBalanceSchema.safeParse(invalidUserId).success).toBe(false);
    });
  });

  describe('Transfers Schemas', () => {
    it('validates transfer payload', () => {
      const valid = {
        recipient: 'john_doe',
        amountMinor: 10000,
        note: 'Dinner payment',
      };
      expect(sendTransferSchema.safeParse(valid).success).toBe(true);

      const invalidAmount = { recipient: 'john_doe', amountMinor: -50 };
      expect(sendTransferSchema.safeParse(invalidAmount).success).toBe(false);
    });
  });

  describe('Deposits Schemas', () => {
    it('validates deposit request submission', () => {
      const valid = {
        paymentMethodCode: 'BKASH',
        amountMinor: 50000,
        senderAccount: '01712345678',
        providerTransactionId: 'TRX987654321',
      };
      expect(createDepositSchema.safeParse(valid).success).toBe(true);

      const missingTrx = {
        paymentMethodCode: 'BKASH',
        amountMinor: 50000,
        senderAccount: '01712345678',
      };
      expect(createDepositSchema.safeParse(missingTrx).success).toBe(false);
    });

    it('validates deposit reject schema', () => {
      expect(rejectDepositSchema.safeParse({ reason: 'Invalid Trx ID' }).success).toBe(true);
      expect(rejectDepositSchema.safeParse({ reason: 'no' }).success).toBe(false);
    });
  });

  describe('Withdrawals Schemas', () => {
    it('validates withdrawal request payload', () => {
      const valid = {
        paymentMethodCode: 'NAGAD',
        receiverAccount: '01812345678',
        amountMinor: 20000,
      };
      expect(createWithdrawalSchema.safeParse(valid).success).toBe(true);

      const missingAccount = {
        paymentMethodCode: 'NAGAD',
        amountMinor: 20000,
      };
      expect(createWithdrawalSchema.safeParse(missingAccount).success).toBe(false);
    });

    it('validates withdrawal approve and reject schema', () => {
      expect(approveWithdrawalSchema.safeParse({ transactionReference: 'BANK-REF-99' }).success).toBe(true);
      expect(rejectWithdrawalSchema.safeParse({ reason: 'Account number does not exist' }).success).toBe(true);
    });
  });

  describe('Payment Methods Schemas', () => {
    it('validates payment method creation and updates', () => {
      const valid = {
        code: 'ROCKET',
        name: 'Rocket',
        type: 'MOBILE_BANKING',
        accountNumber: '01912345678-9',
        accountName: 'TRADEX Merchant',
        instructions: 'Send money to our Rocket account',
        minimumDepositMinor: 10000,
        maximumDepositMinor: 2500000,
      };
      expect(createPaymentMethodSchema.safeParse(valid).success).toBe(true);

      const update = {
        accountNumber: '01999999999-9',
        depositEnabled: false,
      };
      expect(updatePaymentMethodSchema.safeParse(update).success).toBe(true);
    });
  });
});
