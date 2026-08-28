import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import { ticketsService } from './tickets.service.ts';
import { requireAuth, requireAdmin } from '../../middleware/auth.ts';
import { sendSuccess, paginatedResponse, NotFoundError, BadRequestError } from '../../utils/response.ts';

export const ticketsRoutes = new Hono();
export const adminTicketsRoutes = new Hono();

// Purchase Ticket Schema
const purchaseTicketSchema = z.object({
  draw_id: z.union([z.number().int().positive(), z.string().min(1)]),
  selected_number: z.string().min(1).regex(/^\d+$/, 'Selected number must contain only numeric characters'),
  quantity: z.coerce.number().int().min(1).max(100).default(1),
  payment_method: z.enum(['WALLET']).optional().default('WALLET'),
  idempotency_key: z.string().optional(),
});

// My Tickets Query Schema
const myTicketsQuerySchema = z.object({
  draw_type: z.string().optional(),
  status: z.string().optional(),
  limit: z.coerce.number().int().positive().optional().default(20),
  offset: z.coerce.number().int().nonnegative().optional().default(0),
});

// Admin Tickets Query Schema
const adminTicketsQuerySchema = z.object({
  draw_id: z.string().optional(),
  user_id: z.string().optional(),
  status: z.string().optional(),
  is_winner: z
    .string()
    .optional()
    .transform((val) => (val === undefined ? undefined : val === 'true')),
  selected_number: z.string().optional(),
  limit: z.coerce.number().int().positive().optional().default(50),
  offset: z.coerce.number().int().nonnegative().optional().default(0),
});

/**
 * User Tickets Routes: /api/v1/tickets
 */

// POST /api/v1/tickets/purchase
ticketsRoutes.post('/purchase', requireAuth, zValidator('json', purchaseTicketSchema), async (c) => {
  const user = c.get('user');
  const body = c.req.valid('json');

  const result = await ticketsService.purchaseTickets(user.id, body);
  return sendSuccess(c, result, { message: 'Tickets purchased successfully' }, 201);
});

// GET /api/v1/tickets/my-tickets
ticketsRoutes.get('/my-tickets', requireAuth, zValidator('query', myTicketsQuerySchema), async (c) => {
  const user = c.get('user');
  const query = c.req.valid('query');
  const result = await ticketsService.getUserTickets(user.id, query);
  return paginatedResponse(c, result.tickets, {
    total: result.total,
    limit: query.limit,
    offset: query.offset,
  });
});

// GET /api/v1/tickets/:id
ticketsRoutes.get('/:id', requireAuth, async (c) => {
  const id = c.req.param('id');
  if (!id) {
    throw new BadRequestError('Ticket ID is required');
  }
  const user = c.get('user');
  const isAdmin = user.role === 'ADMIN' || user.role === 'SUPER_ADMIN';
  const ticket = await ticketsService.getTicketById(id, user.id, isAdmin);

  if (!ticket) {
    throw new NotFoundError('Ticket not found');
  }
  return sendSuccess(c, ticket);
});

/**
 * Admin Tickets Routes: /api/v1/admin/tickets
 */
adminTicketsRoutes.use('*', requireAuth, requireAdmin);

adminTicketsRoutes.get('/', zValidator('query', adminTicketsQuerySchema), async (c) => {
  const query = c.req.valid('query');
  const result = await ticketsService.getAdminTickets(query);
  return paginatedResponse(c, result.tickets, {
    total: result.total,
    limit: query.limit,
    offset: query.offset,
  });
});
