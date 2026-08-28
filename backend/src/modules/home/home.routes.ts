import { Hono } from 'hono';
import { optionalAuth } from '../../middleware/auth.ts';
import { drawsService } from '../draws/draws.service.ts';
import { resultsService } from '../results/results.service.ts';
import { notificationsService } from '../notifications/notifications.service.ts';
import { query } from '../../db/index.ts';

export const homeRoutes = new Hono();

/**
 * GET /api/v1/home
 * Consolidated home feed: active draws, latest results, wallet summary, notifications count, promo banners
 */
homeRoutes.get('/', optionalAuth, async (c) => {
  try {
    const user = c.get('user');

    // 1. Fetch active & scheduled draws (Mega, Daily, Hourly)
    const drawsData = await drawsService.getDraws({
      status: 'OPEN',
      limit: 10,
    });

    // If less than 3 draws open, include scheduled draws
    let activeDraws = drawsData.draws;
    if (activeDraws.length < 3) {
      const scheduledDrawsData = await drawsService.getDraws({
        limit: 10,
      });
      activeDraws = scheduledDrawsData.draws;
    }

    // Categorize draws by type
    const categorizedDraws = {
      mega: activeDraws.find((d) => d.draw_type_code === 'MEGA') || null,
      daily: activeDraws.find((d) => d.draw_type_code === 'DAILY') || null,
      hourly: activeDraws.find((d) => d.draw_type_code === 'HOURLY') || null,
      all: activeDraws,
    };

    // 2. Fetch latest results
    const resultsData = await resultsService.getResults({ limit: 5 });

    // 3. User Wallet Summary (if authenticated)
    let walletSummary: {
      available_balance_minor: string | number;
      locked_balance_minor: string | number;
      currency: string;
    } | null = null;

    let unreadNotificationsCount = 0;

    if (user?.id) {
      try {
        const walletRes = await query<{
          available_balance_minor: string;
          locked_balance_minor: string;
          currency: string;
        }>(
          'SELECT available_balance_minor, locked_balance_minor, currency FROM wallets WHERE user_id = $1',
          [user.id]
        );

        if (walletRes.rows[0]) {
          walletSummary = walletRes.rows[0];
        } else {
          walletSummary = {
            available_balance_minor: '0',
            locked_balance_minor: '0',
            currency: 'BDT',
          };
        }

        // Notification count
        const notifData = await notificationsService.getUserNotifications(user.id, { unread_only: true, limit: 1 });
        unreadNotificationsCount = notifData.unreadCount;
      } catch (e) {
        // Fallback gracefully for wallet
        walletSummary = {
          available_balance_minor: '0',
          locked_balance_minor: '0',
          currency: 'BDT',
        };
      }
    }

    // 4. Promo Banners
    let promoBanners: Array<{
      id: string | number;
      title: string;
      subtitle: string;
      image_url: string;
      action_url?: string;
      badge?: string;
    }> = [
      {
        id: 'mega-jackpot-1',
        title: 'Mega Draw ৳10,000,000 Jackpot!',
        subtitle: 'Pick your lucky 7 digits today',
        image_url: 'https://images.unsplash.com/photo-1518609878373-06d740f60d8b?auto=format&fit=crop&w=800&q=80',
        action_url: '/draws/mega',
        badge: 'HOT',
      },
      {
        id: 'daily-triple-2',
        title: 'Daily Draw ৳5,000 Prize',
        subtitle: 'Draws every day at 8:00 PM',
        image_url: 'https://images.unsplash.com/photo-1579621970563-ebec7560ff3e?auto=format&fit=crop&w=800&q=80',
        action_url: '/draws/daily',
        badge: 'DAILY',
      },
      {
        id: 'hourly-fast-3',
        title: 'Hourly Speed Draw',
        subtitle: 'Fast wins every hour from 10 AM to 10 PM',
        image_url: 'https://images.unsplash.com/photo-1553729459-efe14ef6055d?auto=format&fit=crop&w=800&q=80',
        action_url: '/draws/hourly',
        badge: 'FAST',
      },
    ];

    try {
      const bannerRes = await query<{
        id: number;
        title: string;
        subtitle: string;
        image_url: string;
        action_url: string;
        badge: string;
      }>("SELECT id, title, subtitle, image_url, action_url, badge FROM promo_banners WHERE status = 'ACTIVE' ORDER BY priority ASC LIMIT 5");
      if (bannerRes.rows.length > 0) {
        promoBanners = bannerRes.rows;
      }
    } catch {
      // Use fallback default promo banners if table not yet populated
    }

    return c.json({
      success: true,
      data: {
        active_draws: categorizedDraws,
        latest_results: resultsData.results,
        wallet: walletSummary,
        unread_notifications_count: unreadNotificationsCount,
        promo_banners: promoBanners,
      },
    });
  } catch (error: any) {
    return c.json({ success: false, error: error?.message || 'Failed to load home overview' }, 500);
  }
});
