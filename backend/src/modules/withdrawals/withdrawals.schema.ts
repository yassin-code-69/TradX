import { z } from 'zod';

export const createWithdrawalSchema = z.object({
  paymentMethodId: z.union([z.number().int().positive(), z.string()]).optional(),
  paymentMethodCode: z.string().optional(),
  receiverAccount: z
    .string()
    .min(3, { message: 'Receiver account number/address is required' })
    .max(128),
  amountMinor: z.union([z.number().int().positive(), z.string().regex(/^[1-9]\d*$/)]),
  idempotencyKey: z.string().max(255).optional(),
}).refine((data) => data.paymentMethodId || data.paymentMethodCode, {
  message: 'Payment method ID or code is required',
  path: ['paymentMethodId'],
});

export const approveWithdrawalSchema = z.object({
  transactionReference: z.string().max(255).optional(),
  note: z.string().max(500).optional(),
});

export const rejectWithdrawalSchema = z.object({
  reason: z.string().min(3, { message: 'Rejection reason is required (min 3 characters)' }).max(500),
});

export const withdrawalQuerySchema = z.object({
  status: z.enum(['PENDING', 'APPROVED', 'REJECTED', 'CANCELLED']).optional(),
  paymentMethodId: z.string().optional(),
  fromDate: z.string().datetime().optional().or(z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional()),
  toDate: z.string().datetime().optional().or(z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional()),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});
