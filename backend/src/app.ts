import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { logger } from 'hono/logger';
import { errorHandler, notFoundHandler } from './middleware/errorHandler.ts';
import { authRoutes } from './modules/auth/auth.routes.ts';
import { adminDepositsRoutes, depositsRoutes } from './modules/deposits/deposits.routes.ts';
import { adminDrawsRoutes, drawsRoutes } from './modules/draws/draws.routes.ts';
import { homeRoutes } from './modules/home/home.routes.ts';
import { notificationsRoutes } from './modules/notifications/notifications.routes.ts';
import { adminResultsRoutes, resultsRoutes } from './modules/results/results.routes.ts';
import {
  adminPaymentMethodsRoutes,
  paymentMethodsRoutes,
} from './modules/settings/payment-methods.routes.ts';
import { adminTicketsRoutes, ticketsRoutes } from './modules/tickets/tickets.routes.ts';
import { adminTransfersRoutes, transfersRoutes } from './modules/transfers/transfers.routes.ts';
import { adminWalletRoutes, walletRoutes } from './modules/wallet/wallet.routes.ts';
import { adminWithdrawalsRoutes, withdrawalsRoutes } from './modules/withdrawals/withdrawals.routes.ts';

export const app = new Hono();

// Global Middleware
app.use('*', logger());
app.use(
  '*',
  cors({
    origin: '*',
    allowMethods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowHeaders: ['Content-Type', 'Authorization', 'Idempotency-Key', 'X-Request-ID'],
    exposeHeaders: ['Content-Length', 'X-Request-ID'],
    maxAge: 600,
  })
);

// Request ID middleware
app.use('*', async (c, next) => {
  const reqId = c.req.header('x-request-id') || crypto.randomUUID();
  c.header('X-Request-ID', reqId);
  await next();
});

// Health Checks
app.get('/health', (c) =>
  c.json({
    status: 'ok',
    success: true,
    data: { status: 'ok', service: 'tradex-backend', timestamp: new Date().toISOString() },
  })
);
app.get('/api/v1/health', (c) =>
  c.json({
    status: 'ok',
    success: true,
    data: { status: 'ok', version: '1.0.0' },
  })
);

// Auth & Session
app.route('/api/v1', authRoutes);

// Core & Feeds
app.route('/api/v1/home', homeRoutes);
app.route('/api/v1/draws', drawsRoutes);
app.route('/api/v1/tickets', ticketsRoutes);
app.route('/api/v1/results', resultsRoutes);
app.route('/api/v1/notifications', notificationsRoutes);

// User Financial Modules
app.route('/api/v1/wallet/transfers', transfersRoutes);
app.route('/api/v1/wallet', walletRoutes);
app.route('/api/v1/deposits', depositsRoutes);
app.route('/api/v1/withdrawals', withdrawalsRoutes);
app.route('/api/v1/payment-methods', paymentMethodsRoutes);

// Admin Financial & Operational Modules
app.route('/api/v1/admin/draws', adminDrawsRoutes);
app.route('/api/v1/admin/tickets', adminTicketsRoutes);
app.route('/api/v1/admin/results', adminResultsRoutes);
app.route('/api/v1/admin/wallet', adminWalletRoutes);
app.route('/api/v1/admin/transfers', adminTransfersRoutes);
app.route('/api/v1/admin/deposits', adminDepositsRoutes);
app.route('/api/v1/admin/withdrawals', adminWithdrawalsRoutes);
app.route('/api/v1/admin/payment-methods', adminPaymentMethodsRoutes);

// Global Error & 404 Handlers
app.onError(errorHandler);
app.notFound(notFoundHandler);

export default app;
