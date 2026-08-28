import { z } from 'zod';

export const sendTransferSchema = z.object({
  recipient: z
    .string()
    .min(3, { message: 'Recipient identifier (username or phone) is required' })
    .max(100),
  amountMinor: z.union([z.number().int().positive(), z.string().regex(/^[1-9]\d*$/)]),
  note: z.string().max(255).optional(),
  idempotencyKey: z.string().max(255).optional(),
});

export const transferQuerySchema = z.object({
  direction: z.enum(['SENT', 'RECEIVED', 'ALL']).default('ALL'),
  status: z.string().optional(),
  fromDate: z.string().datetime().optional().or(z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional()),
  toDate: z.string().datetime().optional().or(z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional()),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});
