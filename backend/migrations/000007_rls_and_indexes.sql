-- ============================================================================
-- TRADEX DATABASE MIGRATION SUITE
-- Migration: 000007_rls_and_indexes.sql
-- Description: Row Level Security (RLS) Policies & High-Performance Partial Indexes
-- ============================================================================

-- ============================================================================
-- 1. ENABLE ROW LEVEL SECURITY (RLS) ON ALL PUBLIC TABLES
-- ============================================================================

ALTER TABLE IF EXISTS profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS user_kyc ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS media_assets ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS role_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS ledger_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS ledger_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS ledger_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS idempotency_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS payment_methods ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS deposit_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS withdrawal_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS wallet_transfers ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS draw_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS draws ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS number_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS prize_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS draw_prize_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS ticket_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS draw_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS draw_result_revisions ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS winners ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS notification_deliveries ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS banners ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS outbox_events ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 2. SERVICE ROLE FULL ACCESS POLICIES (Backend Hono API Access)
-- ============================================================================
-- Ensures service_role (used by secure backend server) maintains unrestricted access

DO $$
DECLARE
  tbl TEXT;
  tbls TEXT[] := ARRAY[
    'profiles', 'user_kyc', 'media_assets', 'roles', 'permissions', 'role_permissions',
    'user_roles', 'wallets', 'ledger_accounts', 'ledger_transactions', 'ledger_entries',
    'idempotency_keys', 'payment_methods', 'deposit_requests', 'withdrawal_requests',
    'wallet_transfers', 'draw_types', 'draws', 'number_rules', 'prize_rules',
    'draw_prize_rules', 'ticket_orders', 'tickets', 'draw_results', 'draw_result_revisions',
    'winners', 'notifications', 'notification_deliveries', 'banners', 'audit_logs', 'outbox_events'
  ];
BEGIN
  FOREACH tbl IN ARRAY tbls LOOP
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = tbl) THEN
      EXECUTE format('DROP POLICY IF EXISTS service_role_all ON public.%I;', tbl);
      EXECUTE format('CREATE POLICY service_role_all ON public.%I FOR ALL TO service_role USING (true) WITH CHECK (true);', tbl);
    END IF;
  END LOOP;
END $$;

-- ============================================================================
-- 3. USER ACCESS POLICIES (Scoped to auth.uid() using cached subqueries)
-- Supabase Postgres Best Practice: (select auth.uid()) prevents per-row function evaluation
-- ============================================================================

-- Profiles: Users can read and update their own profile; read active users for transfers
DROP POLICY IF EXISTS profiles_user_select_own ON profiles;
CREATE POLICY profiles_user_select_own ON profiles
  FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id OR status = 'ACTIVE');

DROP POLICY IF EXISTS profiles_user_update_own ON profiles;
CREATE POLICY profiles_user_update_own ON profiles
  FOR UPDATE TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

-- User KYC: Users can view and submit their own KYC documents
DROP POLICY IF EXISTS kyc_user_select_own ON user_kyc;
CREATE POLICY kyc_user_select_own ON user_kyc
  FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS kyc_user_insert_own ON user_kyc;
CREATE POLICY kyc_user_insert_own ON user_kyc
  FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);

-- Wallets: Users can read their own wallet balances (mutations are backend service only)
DROP POLICY IF EXISTS wallets_user_select_own ON wallets;
CREATE POLICY wallets_user_select_own ON wallets
  FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id);

-- Tickets & Orders: Users can read their own tickets and orders
DROP POLICY IF EXISTS tickets_user_select_own ON tickets;
CREATE POLICY tickets_user_select_own ON tickets
  FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS ticket_orders_user_select_own ON ticket_orders;
CREATE POLICY ticket_orders_user_select_own ON ticket_orders
  FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id);

-- Deposits: Users can view their deposit history and initiate requests
DROP POLICY IF EXISTS deposits_user_select_own ON deposit_requests;
CREATE POLICY deposits_user_select_own ON deposit_requests
  FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS deposits_user_insert_own ON deposit_requests;
CREATE POLICY deposits_user_insert_own ON deposit_requests
  FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);

-- Withdrawals: Users can view their withdrawal history and initiate requests
DROP POLICY IF EXISTS withdrawals_user_select_own ON withdrawal_requests;
CREATE POLICY withdrawals_user_select_own ON withdrawal_requests
  FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS withdrawals_user_insert_own ON withdrawal_requests;
CREATE POLICY withdrawals_user_insert_own ON withdrawal_requests
  FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);

-- Transfers: Users can view transfers they sent or received
DROP POLICY IF EXISTS transfers_user_select_own ON wallet_transfers;
CREATE POLICY transfers_user_select_own ON wallet_transfers
  FOR SELECT TO authenticated
  USING ((select auth.uid()) = sender_user_id OR (select auth.uid()) = receiver_user_id);

-- Notifications: Users can view own notifications or broadcast alerts, and update read_at
DROP POLICY IF EXISTS notifications_user_select_own ON notifications;
CREATE POLICY notifications_user_select_own ON notifications
  FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id OR user_id IS NULL);

DROP POLICY IF EXISTS notifications_user_update_own ON notifications;
CREATE POLICY notifications_user_update_own ON notifications
  FOR UPDATE TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

-- ============================================================================
-- 4. PUBLIC & CATALOG READ POLICIES (Active content open for browsing)
-- ============================================================================

-- Active Payment Methods
DROP POLICY IF EXISTS payment_methods_public_read ON payment_methods;
CREATE POLICY payment_methods_public_read ON payment_methods
  FOR SELECT TO authenticated, anon
  USING (status = 'ACTIVE');

-- Active Draw Types
DROP POLICY IF EXISTS draw_types_public_read ON draw_types;
CREATE POLICY draw_types_public_read ON draw_types
  FOR SELECT TO authenticated, anon
  USING (status = 'ACTIVE');

-- Active and Scheduled Draws
DROP POLICY IF EXISTS draws_public_read ON draws;
CREATE POLICY draws_public_read ON draws
  FOR SELECT TO authenticated, anon
  USING (status IN ('OPEN', 'SCHEDULED', 'CLOSED', 'COMPLETED'));

-- Prize Rules & Snapshots
DROP POLICY IF EXISTS prize_rules_public_read ON prize_rules;
CREATE POLICY prize_rules_public_read ON prize_rules
  FOR SELECT TO authenticated, anon
  USING (status = 'ACTIVE');

DROP POLICY IF EXISTS draw_prize_rules_public_read ON draw_prize_rules;
CREATE POLICY draw_prize_rules_public_read ON draw_prize_rules
  FOR SELECT TO authenticated, anon
  USING (true);

-- Published Draw Results
DROP POLICY IF EXISTS draw_results_public_read ON draw_results;
CREATE POLICY draw_results_public_read ON draw_results
  FOR SELECT TO authenticated, anon
  USING (true);

-- Active Banners
DROP POLICY IF EXISTS banners_public_read ON banners;
CREATE POLICY banners_public_read ON banners
  FOR SELECT TO authenticated, anon
  USING (status = 'ACTIVE');

-- Winners: Publicly visible winners list
DROP POLICY IF EXISTS winners_public_read ON winners;
CREATE POLICY winners_public_read ON winners
  FOR SELECT TO authenticated, anon
  USING (status = 'PAID');

-- ============================================================================
-- 5. HIGH-PERFORMANCE PARTIAL & OPERATIONAL INDEXES
-- ============================================================================

-- Fast admin queue for pending deposit approvals
CREATE INDEX IF NOT EXISTS idx_deposit_requests_pending_queue
ON deposit_requests (created_at DESC)
WHERE status = 'PENDING';

-- Fast admin queue for pending withdrawal disbursements
CREATE INDEX IF NOT EXISTS idx_withdrawal_requests_pending_queue
ON withdrawal_requests (created_at DESC)
WHERE status = 'PENDING';

-- Fast active lottery draw discovery
CREATE INDEX IF NOT EXISTS idx_draws_active_open
ON draws (draw_at ASC)
WHERE status = 'OPEN';

-- Fast unread notification badge counter
CREATE INDEX IF NOT EXISTS idx_notifications_unread_fast
ON notifications (user_id, created_at DESC)
WHERE read_at IS NULL;

-- Fast winner ticket lookup
CREATE INDEX IF NOT EXISTS idx_tickets_winning_subset
ON tickets (draw_id, created_at DESC)
WHERE is_winner = true;

-- Transactional Outbox worker queue for instant polling
CREATE INDEX IF NOT EXISTS idx_outbox_events_pending_queue
ON outbox_events (available_at ASC, id ASC)
WHERE status = 'PENDING';

-- Fast pending KYC review queue
CREATE INDEX IF NOT EXISTS idx_user_kyc_pending_queue
ON user_kyc (submitted_at DESC)
WHERE status = 'PENDING';
