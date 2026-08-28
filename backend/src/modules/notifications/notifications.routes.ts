import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import { notificationsService } from './notifications.service.ts';
import { requireAuth } from '../../middleware/auth.ts';
import { sendSuccess, paginatedResponse, BadRequestError } from '../../utils/response.ts';

export const notificationsRoutes = new Hono();

// Query Schema
const notificationsQuerySchema = z.object({
  unread_only: z
    .string()
    .optional()
    .transform((val) => val === 'true'),
  limit: z.coerce.number().int().positive().optional().default(20),
  offset: z.coerce.number().int().nonnegative().optional().default(0),
});

/**
 * GET /api/v1/notifications
 * List user notifications and unread count
 */
notificationsRoutes.get('/', requireAuth, zValidator('query', notificationsQuerySchema), async (c) => {
  const user = c.get('user');
  const query = c.req.valid('query');

  const result = await notificationsService.getUserNotifications(user.id, query);
  return paginatedResponse(
    c,
    result.notifications,
    {
      total: result.total,
      limit: query.limit,
      offset: query.offset,
    },
    { unread_count: result.unreadCount }
  );
});

/**
 * PATCH /api/v1/notifications/:id/read
 * Mark single notification as read
 */
notificationsRoutes.patch('/:id/read', requireAuth, async (c) => {
  const id = c.req.param('id');
  if (!id) {
    throw new BadRequestError('Notification ID is required');
  }
  const user = c.get('user');

  const success = await notificationsService.markAsRead(id, user.id);
  return sendSuccess(c, { marked: success }, {
    message: success ? 'Notification marked as read' : 'Notification already read or not found',
  });
});

/**
 * PATCH /api/v1/notifications/read-all
 * Mark all notifications as read
 */
notificationsRoutes.patch('/read-all', requireAuth, async (c) => {
  const user = c.get('user');
  const count = await notificationsService.markAllAsRead(user.id);
  return sendSuccess(
    c,
    { count },
    { message: `Marked ${count} notifications as read` }
  );
});
