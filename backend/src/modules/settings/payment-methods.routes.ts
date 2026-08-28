import { zValidator } from '@hono/zod-validator';
import { Hono } from 'hono';
import { requireAdmin } from '../../middleware/auth.middleware.ts';
import { sendSuccess } from '../../utils/response.ts';
import {
  createPaymentMethodSchema,
  paymentMethodsQuerySchema,
  updatePaymentMethodSchema,
} from './payment-methods.schema.ts';
import { paymentMethodsService } from './payment-methods.service.ts';

export const paymentMethodsRoutes = new Hono();

/**
 * GET /api/v1/payment-methods
 * List active deposit & withdrawal methods (bKash, Nagad, Rocket, Bank, etc.)
 */
paymentMethodsRoutes.get(
  '/',
  zValidator(
    'query',
    paymentMethodsQuerySchema.pick({ type: true })
  ),
  async (c) => {
    const queryParams = c.req.valid('query');
    const methods = await paymentMethodsService.getActivePaymentMethods(queryParams);
    return sendSuccess(c, methods);
  }
);

/**
 * Admin Router for Payment Methods
 */
export const adminPaymentMethodsRoutes = new Hono();

/**
 * GET /api/v1/admin/payment-methods
 * Admin list all payment methods (active and inactive)
 */
adminPaymentMethodsRoutes.get(
  '/',
  requireAdmin,
  zValidator('query', paymentMethodsQuerySchema),
  async (c) => {
    const queryParams = c.req.valid('query');
    const result = await paymentMethodsService.getAllPaymentMethodsAdmin(queryParams);

    return sendSuccess(c, result.methods, {
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
 * POST /api/v1/admin/payment-methods
 * Admin create new payment method
 */
adminPaymentMethodsRoutes.post(
  '/',
  requireAdmin,
  zValidator('json', createPaymentMethodSchema),
  async (c) => {
    const adminUser = c.get('user');
    const body = c.req.valid('json');

    const reqMeta = {
      ip: c.req.header('x-forwarded-for') || c.req.header('cf-connecting-ip'),
      userAgent: c.req.header('user-agent'),
      requestId: c.req.header('x-request-id'),
    };

    const result = await paymentMethodsService.createPaymentMethod(adminUser.userId, body, reqMeta);
    return sendSuccess(c, result, undefined, 201);
  }
);

/**
 * GET /api/v1/admin/payment-methods/:id
 * Admin get payment method by ID
 */
adminPaymentMethodsRoutes.get('/:id', requireAdmin, async (c) => {
  const id = c.req.param('id');
  if (!id) {
    return c.json({ success: false, error: 'Payment method ID is required' }, 400);
  }
  const method = await paymentMethodsService.getPaymentMethodById(id);
  return sendSuccess(c, method);
});

/**
 * PATCH /api/v1/admin/payment-methods/:id
 * Admin update payment method
 */
adminPaymentMethodsRoutes.patch(
  '/:id',
  requireAdmin,
  zValidator('json', updatePaymentMethodSchema),
  async (c) => {
    const adminUser = c.get('user');
    const id = c.req.param('id');
    const body = c.req.valid('json');

    const reqMeta = {
      ip: c.req.header('x-forwarded-for') || c.req.header('cf-connecting-ip'),
      userAgent: c.req.header('user-agent'),
      requestId: c.req.header('x-request-id'),
    };

    const result = await paymentMethodsService.updatePaymentMethod(
      adminUser.userId,
      id,
      body,
      reqMeta
    );
    return sendSuccess(c, result);
  }
);

/**
 * DELETE /api/v1/admin/payment-methods/:id
 * Admin delete / deactivate payment method
 */
adminPaymentMethodsRoutes.delete('/:id', requireAdmin, async (c) => {
  const adminUser = c.get('user');
  const id = c.req.param('id');
  if (!id) {
    return c.json({ success: false, error: 'Payment method ID is required' }, 400);
  }

  const reqMeta = {
    ip: c.req.header('x-forwarded-for') || c.req.header('cf-connecting-ip'),
    userAgent: c.req.header('user-agent'),
    requestId: c.req.header('x-request-id'),
  };

  const result = await paymentMethodsService.deletePaymentMethod(adminUser.userId, id, reqMeta);
  return sendSuccess(c, result);
});
