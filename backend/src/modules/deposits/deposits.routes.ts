import { zValidator } from '@hono/zod-validator';
import { Hono } from 'hono';
import { requireAdmin, requireAuth } from '../../middleware/auth.middleware.ts';
import { sendSuccess } from '../../utils/response.ts';
import {
  approveDepositSchema,
  createDepositSchema,
  depositQuerySchema,
  rejectDepositSchema,
} from './deposits.schema.ts';
import { depositsService } from './deposits.service.ts';

export const depositsRoutes = new Hono();

/**
 * POST /api/v1/deposits
 * Submit manual deposit request
 */
depositsRoutes.post(
  '/',
  requireAuth,
  zValidator('json', createDepositSchema),
  async (c) => {
    const user = c.get('user');
    const body = c.req.valid('json');

    const reqMeta = {
      ip: c.req.header('x-forwarded-for') || c.req.header('cf-connecting-ip'),
      userAgent: c.req.header('user-agent'),
      requestId: c.req.header('x-request-id'),
    };

    const result = await depositsService.createDepositRequest(user.userId, body, reqMeta);
    return sendSuccess(c, result, undefined, 201);
  }
);

/**
 * GET /api/v1/deposits
 * List user's deposit requests
 */
depositsRoutes.get(
  '/',
  requireAuth,
  zValidator('query', depositQuerySchema),
  async (c) => {
    const user = c.get('user');
    const queryParams = c.req.valid('query');
    const result = await depositsService.getUserDeposits(user.userId, queryParams);

    return sendSuccess(c, result.deposits, {
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
 * Admin Router for Deposits
 */
export const adminDepositsRoutes = new Hono();

/**
 * GET /api/v1/admin/deposits
 * Admin list all deposits for review
 */
adminDepositsRoutes.get(
  '/',
  requireAdmin,
  zValidator('query', depositQuerySchema),
  async (c) => {
    const queryParams = c.req.valid('query');
    const result = await depositsService.getAdminDeposits(queryParams);

    return sendSuccess(c, result.deposits, {
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
 * POST /api/v1/admin/deposits/:id/approve
 * Approve deposit and atomically credit user wallet
 */
adminDepositsRoutes.post(
  '/:id/approve',
  requireAdmin,
  zValidator('json', approveDepositSchema),
  async (c) => {
    const adminUser = c.get('user');
    const depositId = c.req.param('id');
    const body = c.req.valid('json');

    const reqMeta = {
      ip: c.req.header('x-forwarded-for') || c.req.header('cf-connecting-ip'),
      userAgent: c.req.header('user-agent'),
      requestId: c.req.header('x-request-id'),
    };

    const result = await depositsService.approveDeposit(adminUser.userId, depositId, body, reqMeta);
    return sendSuccess(c, result, undefined, 200);
  }
);

/**
 * POST /api/v1/admin/deposits/:id/reject
 * Reject deposit with reason
 */
adminDepositsRoutes.post(
  '/:id/reject',
  requireAdmin,
  zValidator('json', rejectDepositSchema),
  async (c) => {
    const adminUser = c.get('user');
    const depositId = c.req.param('id');
    const body = c.req.valid('json');

    const reqMeta = {
      ip: c.req.header('x-forwarded-for') || c.req.header('cf-connecting-ip'),
      userAgent: c.req.header('user-agent'),
      requestId: c.req.header('x-request-id'),
    };

    const result = await depositsService.rejectDeposit(adminUser.userId, depositId, body, reqMeta);
    return sendSuccess(c, result, undefined, 200);
  }
);
