import { describe, expect, it } from 'bun:test';
import { Hono } from 'hono';
import { app, isAllowedOrigin } from '../src/app.ts';
import { clearRateLimits, rateLimiter } from '../src/middleware/rateLimiter.ts';

describe('Backend Security Suite: Rate Limiting & Restricted CORS', () => {
  describe('1. In-Memory Sliding Window Rate Limiter', () => {
    it('should include standard rate limit headers on requests', async () => {
      clearRateLimits();
      const testApp = new Hono();
      testApp.use(
        '/test',
        rateLimiter({
          windowMs: 60000,
          max: 5,
          prefix: 'test-headers',
        })
      );
      testApp.get('/test', (c) => c.json({ ok: true }));

      const res = await testApp.request('/test', {
        headers: { 'x-forwarded-for': '192.168.1.1' },
      });

      expect(res.status).toBe(200);
      expect(res.headers.get('RateLimit-Limit')).toBe('5');
      expect(res.headers.get('RateLimit-Remaining')).toBe('4');
      expect(res.headers.get('RateLimit-Reset')).toBeTruthy();
    });

    it('should return 429 and Retry-After header when rate limit is exceeded', async () => {
      clearRateLimits();
      const testApp = new Hono();
      testApp.use(
        '/limited',
        rateLimiter({
          windowMs: 60000,
          max: 3,
          prefix: 'test-limit',
          message: 'Custom rate limit exceeded message',
        })
      );
      testApp.get('/limited', (c) => c.json({ ok: true }));

      const clientIp = '10.0.0.1';

      // 1st request -> remaining 2
      const res1 = await testApp.request('/limited', { headers: { 'x-forwarded-for': clientIp } });
      expect(res1.status).toBe(200);
      expect(res1.headers.get('RateLimit-Remaining')).toBe('2');

      // 2nd request -> remaining 1
      const res2 = await testApp.request('/limited', { headers: { 'x-forwarded-for': clientIp } });
      expect(res2.status).toBe(200);
      expect(res2.headers.get('RateLimit-Remaining')).toBe('1');

      // 3rd request -> remaining 0
      const res3 = await testApp.request('/limited', { headers: { 'x-forwarded-for': clientIp } });
      expect(res3.status).toBe(200);
      expect(res3.headers.get('RateLimit-Remaining')).toBe('0');

      // 4th request -> 429 Too Many Requests
      const res4 = await testApp.request('/limited', { headers: { 'x-forwarded-for': clientIp } });
      expect(res4.status).toBe(429);
      expect(res4.headers.get('RateLimit-Limit')).toBe('3');
      expect(res4.headers.get('RateLimit-Remaining')).toBe('0');
      expect(res4.headers.get('Retry-After')).toBeTruthy();
      expect(Number(res4.headers.get('Retry-After'))).toBeGreaterThanOrEqual(1);

      const json = (await res4.json()) as any;
      expect(json.success).toBe(false);
      expect(json.error.code).toBe('RATE_LIMIT_EXCEEDED');
      expect(json.error.message).toBe('Custom rate limit exceeded message');
      expect(json.error.details.limit).toBe(3);
      expect(json.error.details.remaining).toBe(0);
      expect(json.error.details.retryAfter).toBeGreaterThanOrEqual(1);
    });

    it('should isolate rate limits across different IP addresses', async () => {
      clearRateLimits();
      const testApp = new Hono();
      testApp.use(
        '/isolated',
        rateLimiter({
          windowMs: 60000,
          max: 2,
          prefix: 'test-ip',
        })
      );
      testApp.get('/isolated', (c) => c.json({ ok: true }));

      // IP 1 uses up quota
      await testApp.request('/isolated', { headers: { 'x-forwarded-for': '203.0.113.1' } });
      await testApp.request('/isolated', { headers: { 'x-forwarded-for': '203.0.113.1' } });
      const ip1Blocked = await testApp.request('/isolated', { headers: { 'x-forwarded-for': '203.0.113.1' } });
      expect(ip1Blocked.status).toBe(429);

      // IP 2 should still be allowed
      const ip2Allowed = await testApp.request('/isolated', { headers: { 'x-forwarded-for': '203.0.113.2' } });
      expect(ip2Allowed.status).toBe(200);
      expect(ip2Allowed.headers.get('RateLimit-Remaining')).toBe('1');
    });

    it('should slide window and permit new requests after window expires', async () => {
      clearRateLimits();
      const testApp = new Hono();
      testApp.use(
        '/sliding',
        rateLimiter({
          windowMs: 50, // 50ms window for fast test
          max: 1,
          prefix: 'test-sliding',
        })
      );
      testApp.get('/sliding', (c) => c.json({ ok: true }));

      const res1 = await testApp.request('/sliding', { headers: { 'x-forwarded-for': '1.1.1.1' } });
      expect(res1.status).toBe(200);

      const resBlocked = await testApp.request('/sliding', { headers: { 'x-forwarded-for': '1.1.1.1' } });
      expect(resBlocked.status).toBe(429);

      // Wait for window to expire
      await new Promise((r) => setTimeout(r, 60));

      const resAfterReset = await testApp.request('/sliding', { headers: { 'x-forwarded-for': '1.1.1.1' } });
      expect(resAfterReset.status).toBe(200);
    });
  });

  describe('2. Restricted CORS & Dynamic Origin Resolution', () => {
    it('isAllowedOrigin correctly permits standard dev origins and production domains', () => {
      expect(isAllowedOrigin('http://localhost:3000')).toBe(true);
      expect(isAllowedOrigin('http://localhost:3001')).toBe(true);
      expect(isAllowedOrigin('http://localhost:5173')).toBe(true);
      expect(isAllowedOrigin('http://localhost:8081')).toBe(true);
      expect(isAllowedOrigin('http://127.0.0.1:3000')).toBe(true);
      expect(isAllowedOrigin('https://tradex.com')).toBe(true);
      expect(isAllowedOrigin('https://admin.tradex.com')).toBe(true);
      expect(isAllowedOrigin('https://api.tradex.com')).toBe(true);
      expect(isAllowedOrigin('https://xoxoshop.com')).toBe(true);
      expect(isAllowedOrigin('https://preview-deploy.vercel.app')).toBe(true);
    });

    it('isAllowedOrigin rejects unauthorized third-party origins', () => {
      expect(isAllowedOrigin('http://malicious-site.com')).toBe(false);
      expect(isAllowedOrigin('https://fake-tradex.com.attacker.org')).toBe(false);
      expect(isAllowedOrigin('http://phishing.net')).toBe(false);
    });

    it('allows non-origin requests from mobile and curl clients', () => {
      expect(isAllowedOrigin(undefined)).toBe(true);
      expect(isAllowedOrigin('')).toBe(true);
    });

    it('responds to preflight OPTIONS requests with credentials and allowed headers', async () => {
      const res = await app.request('/api/v1/health', {
        method: 'OPTIONS',
        headers: {
          Origin: 'http://localhost:3000',
          'Access-Control-Request-Method': 'POST',
          'Access-Control-Request-Headers': 'Content-Type, Authorization, Idempotency-Key, X-Request-ID',
        },
      });

      expect(res.status).toBe(204);
      expect(res.headers.get('Access-Control-Allow-Origin')).toBe('http://localhost:3000');
      expect(res.headers.get('Access-Control-Allow-Credentials')).toBe('true');
      expect(res.headers.get('Access-Control-Allow-Methods')).toContain('POST');
      const allowHeaders = res.headers.get('Access-Control-Allow-Headers');
      expect(allowHeaders).toContain('Authorization');
      expect(allowHeaders).toContain('Idempotency-Key');
      expect(allowHeaders).toContain('X-Request-ID');
    });

    it('does not set Access-Control-Allow-Origin for disallowed origins', async () => {
      const res = await app.request('/api/v1/health', {
        method: 'GET',
        headers: {
          Origin: 'http://evil-attacker.com',
        },
      });

      expect(res.status).toBe(200);
      expect(res.headers.get('Access-Control-Allow-Origin')).toBeNull();
    });

    it('sets Access-Control-Allow-Origin to matched allowed origin on normal requests', async () => {
      const res = await app.request('/api/v1/health', {
        method: 'GET',
        headers: {
          Origin: 'http://localhost:3000',
        },
      });

      expect(res.status).toBe(200);
      expect(res.headers.get('Access-Control-Allow-Origin')).toBe('http://localhost:3000');
      expect(res.headers.get('Access-Control-Allow-Credentials')).toBe('true');
    });

    it('serves direct mobile/curl requests without Origin header seamlessly', async () => {
      const res = await app.request('/health');
      expect(res.status).toBe(200);
      const json = (await res.json()) as any;
      expect(json.status).toBe('ok');
    });
  });
});
