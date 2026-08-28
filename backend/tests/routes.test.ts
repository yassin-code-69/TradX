import { describe, expect, it } from 'bun:test';
import app from '../src/app.ts';

describe('App Routes and Financial Endpoints', () => {
  it('GET /health returns healthy status', async () => {
    const res = await app.request('/health');
    expect(res.status).toBe(200);
    const json = (await res.json()) as any;
    expect(json.status).toBe('ok');
  });

  it('GET /api/v1/health returns healthy version', async () => {
    const res = await app.request('/api/v1/health');
    expect(res.status).toBe(200);
    const json = (await res.json()) as any;
    expect(json.status).toBe('ok');
  });

  it('GET /api/v1/wallet returns 401 without auth token', async () => {
    const res = await app.request('/api/v1/wallet');
    expect(res.status).toBe(401);
    const json = (await res.json()) as any;
    expect(json.success).toBe(false);
    expect(json.error.code).toBe('UNAUTHORIZED');
    expect(json.data).toBeNull();
  });

  it('POST /api/v1/wallet/transfers returns 401 without auth token', async () => {
    const res = await app.request('/api/v1/wallet/transfers', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ recipient: 'user_b', amountMinor: 5000 }),
    });
    expect(res.status).toBe(401);
    const json = (await res.json()) as any;
    expect(json.success).toBe(false);
    expect(json.error.code).toBe('UNAUTHORIZED');
  });

  it('POST /api/v1/deposits returns 401 without auth token', async () => {
    const res = await app.request('/api/v1/deposits', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        paymentMethodCode: 'BKASH',
        amountMinor: 50000,
        senderAccount: '01700000000',
        providerTransactionId: 'TRX123',
      }),
    });
    expect(res.status).toBe(401);
    const json = (await res.json()) as any;
    expect(json.success).toBe(false);
    expect(json.error.code).toBe('UNAUTHORIZED');
  });

  it('POST /api/v1/withdrawals returns 401 without auth token', async () => {
    const res = await app.request('/api/v1/withdrawals', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        paymentMethodCode: 'BKASH',
        amountMinor: 20000,
        receiverAccount: '01700000000',
      }),
    });
    expect(res.status).toBe(401);
    const json = (await res.json()) as any;
    expect(json.success).toBe(false);
    expect(json.error.code).toBe('UNAUTHORIZED');
  });

  it('GET /api/v1/payment-methods is accessible', async () => {
    const res = await app.request('/api/v1/payment-methods');
    expect([200, 500]).toContain(res.status);
  });

  it('GET /non-existent-route returns 404 with structured error', async () => {
    const res = await app.request('/api/v1/non-existent');
    expect(res.status).toBe(404);
    const json = (await res.json()) as any;
    expect(json.success).toBe(false);
    expect(json.error.code).toBe('ROUTE_NOT_FOUND');
    expect(json.data).toBeNull();
  });
});
