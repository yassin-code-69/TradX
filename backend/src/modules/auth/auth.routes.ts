import { Hono } from 'hono';
import { requireAuth } from '../../middleware/auth.ts';
import { sendSuccess } from '../../utils/response.ts';

export const authRoutes = new Hono();

/**
 * GET /api/v1/me
 * Returns current authenticated user details, roles, permissions, and profile
 */
authRoutes.get('/me', requireAuth, async (c) => {
  const user = c.get('user');
  return sendSuccess(c, user);
});
