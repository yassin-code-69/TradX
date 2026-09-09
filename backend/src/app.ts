import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { logger } from 'hono/logger';
import { config } from './config/index.ts';
import { errorHandler, notFoundHandler } from './middleware/errorHandler.ts';
import {
  adminRateLimiter,
  authRateLimiter,
  depositRateLimiter,
  walletRateLimiter,
  withdrawalRateLimiter,
} from './middleware/rateLimiter.ts';
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

/**
 * Standard allowed origin patterns for browser clients
 */
const ALLOWED_ORIGIN_PATTERNS = [
  /^https?:\/\/localhost(:\d+)?$/,
  /^https?:\/\/127\.0\.0\.1(:\d+)?$/,
  /^https?:\/\/([a-zA-Z0-9-]+\.)?tradex\.(com|io|app|dev)$/,
  /^https?:\/\/([a-zA-Z0-9-]+\.)?xoxoshop\.com$/,
  /^https?:\/\/([a-zA-Z0-9-]+\.)?vercel\.app$/,
];

/**
 * Validates whether an incoming HTTP request origin is permitted
 */
export function isAllowedOrigin(origin: string | undefined): boolean {
  if (!origin) {
    // Non-browser or direct requests (mobile apps, curl, server-to-server)
    return true;
  }

  const envOrigins = process.env.ALLOWED_ORIGINS || (config.CORS_ORIGIN !== '*' ? config.CORS_ORIGIN : undefined);
  if (envOrigins) {
    const origins = envOrigins.split(',').map((o) => o.trim());
    if (origins.includes(origin)) {
      return true;
    }
  }

  return ALLOWED_ORIGIN_PATTERNS.some((pattern) => pattern.test(origin));
}

// Global Middleware
app.use('*', logger());

// Dynamic CORS Configuration
app.use(
  '*',
  cors({
    origin: (origin) => {
      // Allow non-origin requests (e.g. mobile/curl)
      if (!origin) {
        return '*';
      }
      if (isAllowedOrigin(origin)) {
        return origin;
      }
      return null;
    },
    credentials: true,
    allowMethods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowHeaders: ['Content-Type', 'Authorization', 'Idempotency-Key', 'X-Request-ID'],
    exposeHeaders: [
      'Content-Length',
      'X-Request-ID',
      'RateLimit-Limit',
      'RateLimit-Remaining',
      'RateLimit-Reset',
      'Retry-After',
    ],
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

// Apply Rate Limiters to Sensitive Endpoints
app.use('/api/v1/auth/*', authRateLimiter);
app.use('/api/v1/auth', authRateLimiter);
app.use('/api/v1/me', authRateLimiter);

app.use('/api/v1/wallet/*', walletRateLimiter);
app.use('/api/v1/wallet', walletRateLimiter);

app.use('/api/v1/deposits/*', depositRateLimiter);
app.use('/api/v1/deposits', depositRateLimiter);

app.use('/api/v1/withdrawals/*', withdrawalRateLimiter);
app.use('/api/v1/withdrawals', withdrawalRateLimiter);

app.use('/api/v1/admin/*', adminRateLimiter);
app.use('/api/v1/admin', adminRateLimiter);

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
