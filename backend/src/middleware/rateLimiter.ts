import type { Context, MiddlewareHandler } from 'hono';
import { errorResponse } from '../utils/response.ts';

export interface RateLimitOptions {
  /**
   * Time window in milliseconds (default: 60,000 ms / 1 minute)
   */
  windowMs?: number;

  /**
   * Maximum number of requests allowed within windowMs (default: 60)
   */
  max?: number;

  /**
   * Custom error message returned when limit is exceeded
   */
  message?: string;

  /**
   * Status code returned on rate limit exceeded (default: 429)
   */
  statusCode?: number;

  /**
   * Key generator function to identify unique clients
   */
  keyGenerator?: (c: Context) => string;

  /**
   * Optional function to skip rate limiting for specific requests
   */
  skip?: (c: Context) => boolean | Promise<boolean>;

  /**
   * Prefix for store keys to isolate buckets (e.g. 'auth', 'admin', 'wallet')
   */
  prefix?: string;

  /**
   * Whether to send standard rate limit headers (default: true)
   */
  headers?: boolean;
}

interface ClientRecord {
  timestamps: number[];
}

/**
 * In-memory sliding window rate limit store
 */
const rateLimitStore = new Map<string, ClientRecord>();

/**
 * Clear all in-memory rate limit records (useful for testing)
 */
export function clearRateLimits(): void {
  rateLimitStore.clear();
}

/**
 * Default client identifier resolver
 */
export function defaultKeyGenerator(c: Context): string {
  const forwarded = c.req.header('x-forwarded-for');
  if (forwarded) {
    const parts = forwarded.split(',');
    const firstPart = parts[0];
    if (firstPart) {
      const firstIp = firstPart.trim();
      if (firstIp) return firstIp;
    }
  }

  const realIp = c.req.header('x-real-ip') || c.req.header('cf-connecting-ip');
  if (realIp && realIp.trim()) {
    return realIp.trim();
  }

  const user = c.get('user');
  if (user && typeof user === 'object' && 'id' in user && user.id) {
    return `user:${user.id}`;
  }

  const userId = c.get('userId');
  if (typeof userId === 'string' && userId) {
    return `user:${userId}`;
  }

  return '127.0.0.1';
}

/**
 * Prune stale timestamps older than the sliding window
 */
function pruneTimestamps(timestamps: number[], windowStart: number): number[] {
  let low = 0;
  let high = timestamps.length;
  while (low < high) {
    const mid = (low + high) >>> 1;
    const val = timestamps[mid];
    if (val !== undefined && val < windowStart) {
      low = mid + 1;
    } else {
      high = mid;
    }
  }
  return low > 0 ? timestamps.slice(low) : timestamps;
}

// Periodic garbage collection for memory safety (every 60s)
const gcInterval = setInterval(() => {
  const now = Date.now();
  const defaultExpiry = 3600000; // 1 hour
  for (const [key, record] of rateLimitStore.entries()) {
    const valid = record.timestamps.filter((t) => t > now - defaultExpiry);
    if (valid.length === 0) {
      rateLimitStore.delete(key);
    } else {
      record.timestamps = valid;
    }
  }
}, 60000);

if (typeof gcInterval === 'object' && gcInterval && 'unref' in gcInterval && typeof gcInterval.unref === 'function') {
  gcInterval.unref();
}

/**
 * In-memory sliding window Rate Limiter Middleware for Hono
 */
export function rateLimiter(options: RateLimitOptions = {}): MiddlewareHandler {
  const windowMs = options.windowMs ?? 60000; // 1 minute default
  const isTestEnv = process.env.NODE_ENV === 'test';
  const defaultMax = isTestEnv ? 1000 : 60;
  const max = options.max ?? defaultMax;
  const message = options.message ?? 'Too many requests, please try again later.';
  const statusCode = options.statusCode ?? 429;
  const keyGen = options.keyGenerator ?? defaultKeyGenerator;
  const prefix = options.prefix ?? 'rl';
  const sendHeaders = options.headers ?? true;

  return async function rateLimitMiddleware(c: Context, next) {
    if (options.skip) {
      const shouldSkip = await options.skip(c);
      if (shouldSkip) {
        return next();
      }
    }

    const now = Date.now();
    const windowStart = now - windowMs;
    const clientKey = `${prefix}:${keyGen(c)}`;

    let record = rateLimitStore.get(clientKey);
    if (!record) {
      record = { timestamps: [] };
      rateLimitStore.set(clientKey, record);
    }

    // Prune entries outside current sliding window
    record.timestamps = pruneTimestamps(record.timestamps, windowStart);

    const currentCount = record.timestamps.length;
    const oldestTimestamp = record.timestamps[0] ?? now;
    const timeToResetMs = Math.max(0, oldestTimestamp + windowMs - now);
    const resetSeconds = Math.max(1, Math.ceil(timeToResetMs / 1000));

    if (currentCount >= max) {
      if (sendHeaders) {
        c.header('RateLimit-Limit', String(max));
        c.header('RateLimit-Remaining', '0');
        c.header('RateLimit-Reset', String(resetSeconds));
        c.header('Retry-After', String(resetSeconds));
      }

      return errorResponse(
        c,
        statusCode as any,
        'RATE_LIMIT_EXCEEDED',
        message,
        {
          limit: max,
          remaining: 0,
          retryAfter: resetSeconds,
          resetAt: new Date(now + timeToResetMs).toISOString(),
        }
      );
    }

    // Record this request
    record.timestamps.push(now);
    const remaining = Math.max(0, max - record.timestamps.length);

    if (sendHeaders) {
      c.header('RateLimit-Limit', String(max));
      c.header('RateLimit-Remaining', String(remaining));
      c.header('RateLimit-Reset', String(resetSeconds));
    }

    await next();
  };
}

/**
 * Pre-configured rate limiters for sensitive domains
 */
export const authRateLimiter = rateLimiter({
  prefix: 'auth',
  windowMs: 60 * 1000,
  max: process.env.NODE_ENV === 'test' ? 1000 : 30,
  message: 'Too many authentication attempts. Please try again after 1 minute.',
});

export const walletRateLimiter = rateLimiter({
  prefix: 'wallet',
  windowMs: 60 * 1000,
  max: process.env.NODE_ENV === 'test' ? 1000 : 60,
  message: 'Wallet transaction rate limit reached. Please wait before retrying.',
});

export const depositRateLimiter = rateLimiter({
  prefix: 'deposit',
  windowMs: 60 * 1000,
  max: process.env.NODE_ENV === 'test' ? 1000 : 30,
  message: 'Deposit submission rate limit reached. Please wait before retrying.',
});

export const withdrawalRateLimiter = rateLimiter({
  prefix: 'withdrawal',
  windowMs: 60 * 1000,
  max: process.env.NODE_ENV === 'test' ? 1000 : 30,
  message: 'Withdrawal submission rate limit reached. Please wait before retrying.',
});

export const adminRateLimiter = rateLimiter({
  prefix: 'admin',
  windowMs: 60 * 1000,
  max: process.env.NODE_ENV === 'test' ? 1000 : 120,
  message: 'Admin operation rate limit reached. Please wait before retrying.',
});

export const sensitiveRateLimiter = rateLimiter({
  prefix: 'sensitive',
  windowMs: 60 * 1000,
  max: process.env.NODE_ENV === 'test' ? 1000 : 60,
  message: 'Operation rate limit reached. Please wait before retrying.',
});
