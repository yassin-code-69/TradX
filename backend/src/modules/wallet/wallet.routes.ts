import { zValidator } from '@hono/zod-validator';
import { Hono } from 'hono';
import { requireAdmin, requireAuth } from '../../middleware/auth.middleware.ts';
import { sendSuccess } from '../../utils/response.ts';
import { adminAdjustBalanceSchema, walletTransactionQuerySchema } from './wallet.schema.ts';
import { walletService } from './wallet.service.ts';

export const walletRoutes = new Hono();

/**
 * GET /api/v1/wallet
 * Returns current user's wallet balance (available, locked, total)
 */
walletRoutes.get('/', requireAuth, async (c) => {
  const user = c.get('user');
  const balance = await walletService.getWalletBalance(user.userId);
  return sendSuccess(c, balance);
});

/**
 * GET /api/v1/wallet/transactions
 * Returns current user's ledger transaction history with pagination and filters
 */
walletRoutes.get(
  '/transactions',
  requireAuth,
  zValidator('query', walletTransactionQuerySchema),
  async (c) => {
    const user = c.get('user');
    const queryParams = c.req.valid('query');
    const result = await walletService.getTransactionHistory(user.userId, queryParams);

    return sendSuccess(c, result.transactions, {
      pagination: {
        total: result.total,
        page: result.page,
        limit: result.limit,
        totalPages: Math.ceil(result.total / result.limit),
      },
    });
  }
);

/**
 * Admin Router for Wallet
 */
export const adminWalletRoutes = new Hono();

/**
 * POST /api/v1/admin/wallet/adjust
 * Admin adjusts user balance with audit log
 */
adminWalletRoutes.post(
  '/adjust',
  requireAdmin,
  zValidator('json', adminAdjustBalanceSchema),
  async (c) => {
    const adminUser = c.get('user');
    const body = c.req.valid('json');

    const reqMeta = {
      ip: c.req.header('x-forwarded-for') || c.req.header('cf-connecting-ip'),
      userAgent: c.req.header('user-agent'),
      requestId: c.req.header('x-request-id'),
    };

    const result = await walletService.adminAdjustBalance(adminUser.userId, body, reqMeta);
    return sendSuccess(c, result, undefined, 200);
  }
);
