import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import { drawsService, type DrawStatusCode } from './draws.service.ts';
import { requireAuth, requireAdmin } from '../../middleware/auth.ts';
import { sendSuccess, paginatedResponse, NotFoundError } from '../../utils/response.ts';

export const drawsRoutes = new Hono();
export const adminDrawsRoutes = new Hono();

// Query Schema
const getDrawsQuerySchema = z.object({
  draw_type: z.string().optional(),
  status: z.string().optional(),
  limit: z.coerce.number().int().positive().optional().default(20),
  offset: z.coerce.number().int().nonnegative().optional().default(0),
});

// Create Draw Schema
const createDrawSchema = z.object({
  draw_type_id: z.number().int().positive().optional(),
  draw_type_code: z.enum(['MEGA', 'DAILY', 'HOURLY']).optional(),
  sequence_number: z.string().optional(),
  ticket_price_minor: z.number().int().nonnegative().optional(),
  sale_open_at: z.string().datetime({ offset: true }).or(z.string()),
  sale_close_at: z.string().datetime({ offset: true }).or(z.string()),
  draw_at: z.string().datetime({ offset: true }).or(z.string()),
  status: z.enum(['DRAFT', 'SCHEDULED', 'OPEN', 'CLOSED', 'PROCESSING', 'COMPLETED', 'CANCELLED']).optional(),
});

// Update Status Schema
const updateStatusSchema = z.object({
  status: z.enum(['DRAFT', 'SCHEDULED', 'OPEN', 'CLOSED', 'PROCESSING', 'COMPLETED', 'CANCELLED']),
});

/**
 * Public/User Draws Routes: /api/v1/draws
 */
drawsRoutes.get('/', zValidator('query', getDrawsQuerySchema), async (c) => {
  const query = c.req.valid('query');
  const result = await drawsService.getDraws(query);
  return paginatedResponse(c, result.draws, {
    total: result.total,
    limit: query.limit,
    offset: query.offset,
  });
});

drawsRoutes.get('/:id', async (c) => {
  const id = c.req.param('id');
  const draw = await drawsService.getDrawById(id);
  if (!draw) {
    throw new NotFoundError('Draw not found');
  }
  return sendSuccess(c, draw);
});

/**
 * Admin Draws Routes: /api/v1/admin/draws
 */
adminDrawsRoutes.use('*', requireAuth, requireAdmin);

adminDrawsRoutes.get('/', zValidator('query', getDrawsQuerySchema), async (c) => {
  const query = c.req.valid('query');
  const result = await drawsService.getDraws(query);
  return paginatedResponse(c, result.draws, {
    total: result.total,
    limit: query.limit,
    offset: query.offset,
  });
});

adminDrawsRoutes.post('/', zValidator('json', createDrawSchema), async (c) => {
  const body = c.req.valid('json');
  const user = c.get('user');
  const createdDraw = await drawsService.createDraw(body, user?.id);
  return sendSuccess(c, createdDraw, { message: 'Draw created successfully' }, 201);
});

adminDrawsRoutes.patch('/:id/status', zValidator('json', updateStatusSchema), async (c) => {
  const id = c.req.param('id');
  const { status } = c.req.valid('json');
  const updated = await drawsService.updateDrawStatus(id, status as DrawStatusCode);
  return sendSuccess(c, updated, { message: `Draw status updated to ${status}` });
});
