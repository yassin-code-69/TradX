import { zValidator } from '@hono/zod-validator';
import { Hono } from 'hono';
import { requireAdmin, requireAuth } from '../../middleware/auth.middleware.ts';
import { sendSuccess } from '../../utils/response.ts';
import {
  approveWithdrawalSchema,
  createWithdrawalSchema,
  rejectWithdrawalSchema,
  withdrawalQuerySchema,
} from './withdrawals.schema.ts';
import { withdrawalsService } from './withdrawals.service.ts';

export const withdrawalsRoutes = new Hono();

/**
 * POST /api/v1/withdrawals
 * Request a withdrawal (moves available balance -> locked balance)
 */
withdrawalsRoutes.post(
  '/',
  requireAuth,
  zValidator('json', createWithdrawalSchema),
  async (c) => {
    const user = c.get('user');
    const body = c.req.valid('json');
    const idempotencyKey = c.req.header('Idempotency-Key') || c.req.header('idempotency-key') || body.idempotencyKey;

    const reqMeta = {
      ip: c.req.header('x-forwarded-for') || c.req.header('cf-connecting-ip'),
      userAgent: c.req.header('user-agent'),
      requestId: c.req.header('x-request-id'),
    };

    const result = await withdrawalsService.createWithdrawalRequest(user.userId, body, idempotencyKey, reqMeta);
    return sendSuccess(c, result, undefined, 201);
  }
);

/**
 * GET /api/v1/withdrawals
 * List authenticated user's withdrawal requests
 */
withdrawalsRoutes.get(
  '/',
  requireAuth,
  zValidator('query', withdrawalQuerySchema),
  async (c) => {
    const user = c.get('user');
    const queryParams = c.req.valid('query');
    const result = await withdrawalsService.getUserWithdrawals(user.userId, queryParams);

    return sendSuccess(c, result.withdrawals, {
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
 * Admin Router for Withdrawals
 */
export const adminWithdrawalsRoutes = new Hono();

/**
 * GET /api/v1/admin/withdrawals
 * Admin list all withdrawal requests
 */
adminWithdrawalsRoutes.get(
  '/',
  requireAdmin,
  zValidator('query', withdrawalQuerySchema),
  async (c) => {
    const queryParams = c.req.valid('query');
    const result = await withdrawalsService.getAdminWithdrawals(queryParams);

    return sendSuccess(c, result.withdrawals, {
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
 * POST /api/v1/admin/withdrawals/:id/approve
 * Approve & complete withdrawal
 */
adminWithdrawalsRoutes.post(
  '/:id/approve',
  requireAdmin,
  zValidator('json', approveWithdrawalSchema),
  async (c) => {
    const adminUser = c.get('user');
    const withdrawalId = c.req.param('id');
    const body = c.req.valid('json');

    const reqMeta = {
      ip: c.req.header('x-forwarded-for') || c.req.header('cf-connecting-ip'),
      userAgent: c.req.header('user-agent'),
      requestId: c.req.header('x-request-id'),
    };

    const result = await withdrawalsService.approveWithdrawal(adminUser.userId, withdrawalId, body, reqMeta);
    return sendSuccess(c, result, undefined, 200);
  }
);

/**
 * POST /api/v1/admin/withdrawals/:id/reject
 * Reject withdrawal & release locked funds back to user available balance
 */
adminWithdrawalsRoutes.post(
  '/:id/reject',
  requireAdmin,
  zValidator('json', rejectWithdrawalSchema),
  async (c) => {
    const adminUser = c.get('user');
    const withdrawalId = c.req.param('id');
    const body = c.req.valid('json');

    const reqMeta = {
      ip: c.req.header('x-forwarded-for') || c.req.header('cf-connecting-ip'),
      userAgent: c.req.header('user-agent'),
      requestId: c.req.header('x-request-id'),
    };

    const result = await withdrawalsService.rejectWithdrawal(adminUser.userId, withdrawalId, body, reqMeta);
    return sendSuccess(c, result, undefined, 200);
  }
);
