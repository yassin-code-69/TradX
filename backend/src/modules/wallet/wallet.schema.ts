import { z } from 'zod';

export const walletTransactionQuerySchema = z.object({
  type: z.string().optional(),
  fromDate: z.string().datetime().optional().or(z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional()),
  toDate: z.string().datetime().optional().or(z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional()),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

export const adminAdjustBalanceSchema = z.object({
  userId: z.string().uuid({ message: 'Valid User UUID is required' }),
  amountMinor: z.union([z.number().int().positive(), z.string().regex(/^[1-9]\d*$/)]),
  type: z.enum(['CREDIT', 'DEBIT'] as const),
  reason: z.string().min(3, { message: 'Reason must be at least 3 characters' }).max(255),
  note: z.string().max(1000).optional(),
});
