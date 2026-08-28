import { describe, expect, it } from 'bun:test';
import { app } from './app.ts';

describe('API Route Mounts & Responses', () => {
  it('GET /health should return 200 and ok status', async () => {
    const res = await app.request('/health');
    expect(res.status).toBe(200);
    const json: any = await res.json();
    expect(json.status).toBe('ok');
  });

  it('GET /api/v1/health should return 200', async () => {
    const res = await app.request('/api/v1/health');
    expect(res.status).toBe(200);
    const json: any = await res.json();
    expect(json.status).toBe('ok');
  });

  it('POST /api/v1/admin/draws without auth should return 401 Unauthorized', async () => {
    const res = await app.request('/api/v1/admin/draws', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        draw_type_code: 'MEGA',
        sale_open_at: new Date().toISOString(),
        sale_close_at: new Date(Date.now() + 86400000).toISOString(),
        draw_at: new Date(Date.now() + 86400000).toISOString(),
      }),
    });
    expect(res.status).toBe(401);
  });

  it('POST /api/v1/tickets/purchase without auth should return 401 Unauthorized', async () => {
    const res = await app.request('/api/v1/tickets/purchase', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        draw_id: 1,
        selected_number: '0012345',
        quantity: 1,
      }),
    });
    expect(res.status).toBe(401);
  });
});
