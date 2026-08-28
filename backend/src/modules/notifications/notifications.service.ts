import { query } from '../../db/index.ts';

export interface NotificationItem {
  id: number;
  public_id: string;
  user_id: string | null;
  type: string;
  title: string;
  body: string;
  data?: Record<string, unknown> | null;
  read_at?: string | null;
  created_at: string;
}

export class NotificationsService {
  /**
   * Get user notifications with unread count
   */
  async getUserNotifications(
    userId: string,
    options?: {
      unread_only?: boolean;
      limit?: number;
      offset?: number;
    }
  ): Promise<{
    notifications: NotificationItem[];
    unreadCount: number;
    total: number;
  }> {
    const params: unknown[] = [userId];
    const conditions: string[] = ['(user_id = $1 OR user_id IS NULL)'];

    if (options?.unread_only) {
      conditions.push('read_at IS NULL');
    }

    const whereClause = `WHERE ${conditions.join(' AND ')}`;
    const limit = Math.min(options?.limit ?? 20, 100);
    const offset = options?.offset ?? 0;

    // Total count
    const totalSql = `SELECT COUNT(*) as count FROM notifications ${whereClause}`;
    const totalRes = await query<{ count: string }>(totalSql, params);
    const total = parseInt(totalRes.rows[0]?.count || '0', 10);

    // Unread count
    const unreadSql = `SELECT COUNT(*) as count FROM notifications WHERE (user_id = $1 OR user_id IS NULL) AND read_at IS NULL`;
    const unreadRes = await query<{ count: string }>(unreadSql, [userId]);
    const unreadCount = parseInt(unreadRes.rows[0]?.count || '0', 10);

    // Items
    const listSql = `
      SELECT id, public_id, user_id, type, title, body, data, read_at, created_at
      FROM notifications
      ${whereClause}
      ORDER BY created_at DESC
      LIMIT $${params.length + 1} OFFSET $${params.length + 2}
    `;

    const listRes = await query<NotificationItem>(listSql, [...params, limit, offset]);

    return {
      notifications: listRes.rows,
      unreadCount,
      total,
    };
  }

  /**
   * Mark a specific notification as read
   */
  async markAsRead(idOrPublicId: string | number, userId: string): Promise<boolean> {
    const isNumeric = !isNaN(Number(idOrPublicId)) && !String(idOrPublicId).includes('-');
    const condition = isNumeric ? 'id = $1' : 'public_id = $1';

    const res = await query(
      `UPDATE notifications 
       SET read_at = NOW() 
       WHERE ${condition} AND (user_id = $2 OR user_id IS NULL) AND read_at IS NULL
       RETURNING id`,
      [idOrPublicId, userId]
    );

    return (res.rowCount ?? 0) > 0;
  }

  /**
   * Mark all notifications as read for a user
   */
  async markAllAsRead(userId: string): Promise<number> {
    const res = await query(
      `UPDATE notifications 
       SET read_at = NOW() 
       WHERE (user_id = $1 OR user_id IS NULL) AND read_at IS NULL`,
      [userId]
    );

    return res.rowCount ?? 0;
  }

  /**
   * Create a notification
   */
  async createNotification(data: {
    user_id?: string | null;
    type: string;
    title: string;
    body: string;
    data?: Record<string, unknown>;
  }): Promise<NotificationItem> {
    const sql = `
      INSERT INTO notifications (
        public_id, user_id, type, title, body, data, created_at
      ) VALUES (
        gen_random_uuid(), $1, $2, $3, $4, $5, NOW()
      ) RETURNING id, public_id, user_id, type, title, body, data, read_at, created_at
    `;

    const res = await query<NotificationItem>(sql, [
      data.user_id || null,
      data.type,
      data.title,
      data.body,
      data.data ? JSON.stringify(data.data) : null,
    ]);

    return res.rows[0]!;
  }
}

export const notificationsService = new NotificationsService();
