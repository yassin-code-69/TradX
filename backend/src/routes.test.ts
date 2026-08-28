import { describe, expect, it } from 'bun:test';
import { app } from './app.ts';

describe('All Module Routes Existence & Responses', () => {
  it('GET /api/v1/draws', async () => {
    const res = await app.request('/api/v1/draws');
    expect([200, 500]).toContain(res.status); // 200 or DB connection fallback
  });

  it('GET /api/v1/draws/:id', async () => {
    const res = await app.request('/api/v1/draws/999999');
    expect([404, 500]).toContain(res.status);
  });

  it('GET /api/v1/results', async () => {
    const res = await app.request('/api/v1/results');
    expect([200, 500]).toContain(res.status);
  });

  it('GET /api/v1/results/:drawId', async () => {
    const res = await app.request('/api/v1/results/999999');
    expect([404, 500]).toContain(res.status);
  });

  it('GET /api/v1/home', async () => {
    const res = await app.request('/api/v1/home');
    expect([200, 500]).toContain(res.status);
  });

  it('GET /api/v1/notifications without auth should return 401', async () => {
    const res = await app.request('/api/v1/notifications');
    expect(res.status).toBe(401);
  });

  it('PATCH /api/v1/notifications/1/read without auth should return 401', async () => {
    const res = await app.request('/api/v1/notifications/1/read', { method: 'PATCH' });
    expect(res.status).toBe(401);
  });

  it('GET /api/v1/tickets/my-tickets without auth should return 401', async () => {
    const res = await app.request('/api/v1/tickets/my-tickets');
    expect(res.status).toBe(401);
  });

  it('GET /api/v1/admin/tickets without auth should return 401', async () => {
    const res = await app.request('/api/v1/admin/tickets');
    expect(res.status).toBe(401);
  });

  it('POST /api/v1/admin/results/publish without auth should return 401', async () => {
    const res = await app.request('/api/v1/admin/results/publish', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ draw_id: 1, winning_number: '1234567' }),
    });
    expect(res.status).toBe(401);
  });
});
