import { zValidator } from '@hono/zod-validator';
import { Hono } from 'hono';
import { requireAdmin, requireAuth } from '../../middleware/auth.middleware.ts';
import { sendSuccess } from '../../utils/response.ts';
import { sendTransferSchema, transferQuerySchema } from './transfers.schema.ts';
import { transfersService } from './transfers.service.ts';

export const transfersRoutes = new Hono();

/**
 * POST /api/v1/wallet/transfers
 * Send money from authenticated user to recipient by username or phone.
 * Supports Idempotency-Key header.
 */
transfersRoutes.post(
  '/',
  requireAuth,
  zValidator('json', sendTransferSchema),
  async (c) => {
    const user = c.get('user');
    const body = c.req.valid('json');
    const idempotencyKey = c.req.header('Idempotency-Key') || c.req.header('idempotency-key') || body.idempotencyKey;

    const reqMeta = {
      ip: c.req.header('x-forwarded-for') || c.req.header('cf-connecting-ip'),
      userAgent: c.req.header('user-agent'),
      requestId: c.req.header('x-request-id'),
    };

    const result = await transfersService.sendTransfer(user.userId, body, idempotencyKey, reqMeta);
    return sendSuccess(c, result, undefined, 200);
  }
);

/**
 * GET /api/v1/wallet/transfers
 * List current user's transfers (sent & received)
 */
transfersRoutes.get(
  '/',
  requireAuth,
  zValidator('query', transferQuerySchema),
  async (c) => {
    const user = c.get('user');
    const queryParams = c.req.valid('query');
    const result = await transfersService.getUserTransfers(user.userId, queryParams);

    return sendSuccess(c, result.transfers, {
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
 * Admin Router for Transfers
 */
export const adminTransfersRoutes = new Hono();

/**
 * GET /api/v1/admin/transfers
 * Admin list all transfers
 */
adminTransfersRoutes.get(
  '/',
  requireAdmin,
  zValidator('query', transferQuerySchema),
  async (c) => {
    const queryParams = c.req.valid('query');
    const result = await transfersService.getAdminTransfers(queryParams);

    return sendSuccess(c, result.transfers, {
      pagination: {
        total: result.total,
        page: result.page,
        limit: result.limit,
        totalPages: Math.ceil(result.total / result.limit),
      },
    });
  }
);
