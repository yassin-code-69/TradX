import { z } from 'zod';

export const createPaymentMethodSchema = z.object({
  code: z
    .string()
    .min(2, { message: 'Code must be at least 2 characters' })
    .max(64)
    .toUpperCase(),
  name: z.string().min(2, { message: 'Name must be at least 2 characters' }).max(255),
  type: z.enum(['MOBILE_BANKING', 'BANK_TRANSFER', 'CRYPTO']).default('MOBILE_BANKING'),
  accountNumber: z.string().min(3).max(128),
  accountName: z.string().min(2).max(255),
  instructions: z.string().min(5).max(2000),
  minimumDepositMinor: z
    .union([z.number().int().nonnegative(), z.string().regex(/^\d+$/)])
    .default(10000),
  maximumDepositMinor: z
    .union([z.number().int().nonnegative(), z.string().regex(/^\d+$/)])
    .default(2500000),
  minimumWithdrawMinor: z
    .union([z.number().int().nonnegative(), z.string().regex(/^\d+$/)])
    .default(20000),
  maximumWithdrawMinor: z
    .union([z.number().int().nonnegative(), z.string().regex(/^\d+$/)])
    .default(2500000),
  depositFeePercentageBasisPoints: z.number().int().min(0).max(10000).default(0),
  depositFeeFixedMinor: z
    .union([z.number().int().nonnegative(), z.string().regex(/^\d+$/)])
    .default(0),
  withdrawFeePercentageBasisPoints: z.number().int().min(0).max(10000).default(0),
  withdrawFeeFixedMinor: z
    .union([z.number().int().nonnegative(), z.string().regex(/^\d+$/)])
    .default(0),
  depositEnabled: z.boolean().default(true),
  withdrawEnabled: z.boolean().default(true),
  status: z.enum(['ACTIVE', 'INACTIVE']).default('ACTIVE'),
  displayOrder: z.number().int().default(0),
});

export const updatePaymentMethodSchema = createPaymentMethodSchema.partial().omit({ code: true });

export const paymentMethodsQuerySchema = z.object({
  type: z.enum(['deposit', 'withdraw', 'all']).optional(),
  status: z.enum(['ACTIVE', 'INACTIVE']).optional(),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(50),
});
