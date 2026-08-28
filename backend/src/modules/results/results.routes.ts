import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import { resultsService } from './results.service.ts';
import { requireAuth, requireAdmin } from '../../middleware/auth.ts';
import { sendSuccess, paginatedResponse, NotFoundError } from '../../utils/response.ts';

export const resultsRoutes = new Hono();
export const adminResultsRoutes = new Hono();

// Query Schema
const getResultsQuerySchema = z.object({
  draw_type: z.string().optional(),
  limit: z.coerce.number().int().positive().optional().default(20),
  offset: z.coerce.number().int().nonnegative().optional().default(0),
});

// Publish Result Schema
const publishResultSchema = z.object({
  draw_id: z.union([z.number().int().positive(), z.string().min(1)]),
  winning_number: z.string().min(1).regex(/^\d+$/, 'Winning number must contain only numeric characters'),
  result_hash: z.string().optional(),
});

/**
 * Public Results Routes: /api/v1/results
 */

// GET /api/v1/results
resultsRoutes.get('/', zValidator('query', getResultsQuerySchema), async (c) => {
  const query = c.req.valid('query');
  const data = await resultsService.getResults(query);
  return paginatedResponse(c, data.results, {
    total: data.total,
    limit: query.limit,
    offset: query.offset,
  });
});

// GET /api/v1/results/:drawId
resultsRoutes.get('/:drawId', async (c) => {
  const drawId = c.req.param('drawId');
  const details = await resultsService.getResultByDrawId(drawId);
  if (!details) {
    throw new NotFoundError('Result not found for this draw');
  }
  return sendSuccess(c, details);
});

/**
 * Admin Results Routes: /api/v1/admin/results
 */
adminResultsRoutes.use('*', requireAuth, requireAdmin);

// POST /api/v1/admin/results/publish
adminResultsRoutes.post('/publish', zValidator('json', publishResultSchema), async (c) => {
  const user = c.get('user');
  const body = c.req.valid('json');

  const published = await resultsService.publishResult(user.id, body);
  return sendSuccess(
    c,
    published,
    { message: 'Draw result published and winners calculated successfully' },
    201
  );
});
