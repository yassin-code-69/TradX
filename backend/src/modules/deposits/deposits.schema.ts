import { z } from 'zod';

export const createDepositSchema = z.object({
  paymentMethodId: z.union([z.number().int().positive(), z.string()]).optional(),
  paymentMethodCode: z.string().optional(),
  method: z.string().optional(),
  amountMinor: z.union([z.number().int().positive(), z.string().regex(/^[1-9]\d*$/)]),
  senderAccount: z
    .string()
    .min(3, { message: 'Sender account/number is required' })
    .max(100),
  providerTransactionId: z.string().min(3, { message: 'Transaction ID is required' }).max(128).optional(),
  trxId: z.string().min(3, { message: 'Transaction ID is required' }).max(128).optional(),
  proofAssetId: z.union([z.number().int().positive(), z.string()]).optional(),
}).refine((data) => data.providerTransactionId || data.trxId, {
  message: 'Transaction ID (providerTransactionId or trxId) is required',
  path: ['providerTransactionId'],
}).refine((data) => data.paymentMethodId || data.paymentMethodCode || data.method, {
  message: 'Payment method is required',
  path: ['paymentMethodId'],
});

export const approveDepositSchema = z.object({
  note: z.string().max(500).optional(),
});

export const rejectDepositSchema = z.object({
  reason: z.string().min(3, { message: 'Rejection reason is required (min 3 characters)' }).max(500),
});

export const depositQuerySchema = z.object({
  status: z.enum(['PENDING', 'APPROVED', 'REJECTED', 'CANCELLED']).optional(),
  paymentMethodId: z.string().optional(),
  fromDate: z.string().datetime().optional().or(z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional()),
  toDate: z.string().datetime().optional().or(z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional()),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});
