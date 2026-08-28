-- ============================================================================
-- TRADEX DATABASE MIGRATION SUITE
-- Migration: 000006_notifications_banners_audit_outbox.sql
-- Description: Operational Core — Notifications, Banners, Append-Only Audit Trail & Transactional Outbox
-- ============================================================================

-- 1. Notifications Table
-- In-app and push notification records for individual users or platform broadcasts
CREATE TABLE IF NOT EXISTS notifications (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  public_id UUID UNIQUE NOT NULL DEFAULT gen_random_uuid(),
  user_id UUID NULL REFERENCES profiles(user_id) ON DELETE CASCADE,
  type VARCHAR(50) NOT NULL,
  title VARCHAR(255) NOT NULL,
  body TEXT NOT NULL,
  data JSONB NULL,
  read_at TIMESTAMPTZ NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_history ON notifications (user_id, created_at DESC);

-- Partial index for fast unread notifications lookup
CREATE INDEX IF NOT EXISTS idx_notifications_unread
ON notifications (user_id, created_at DESC)
WHERE read_at IS NULL;

-- 2. Notification Deliveries Table
-- Tracks multi-channel dispatch status (Push, SMS, Email)
CREATE TABLE IF NOT EXISTS notification_deliveries (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  notification_id BIGINT NOT NULL REFERENCES notifications(id) ON DELETE CASCADE,
  channel VARCHAR(50) NOT NULL DEFAULT 'IN_APP',
  status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
  attempts INTEGER NOT NULL DEFAULT 0,
  sent_at TIMESTAMPTZ NULL,
  failed_at TIMESTAMPTZ NULL,
  provider_message_id VARCHAR(255) NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_notification_deliveries_notif ON notification_deliveries (notification_id);

-- 3. Banners Table
-- Promotional campaigns and marketing assets displayed on user apps and web-admin
CREATE TABLE IF NOT EXISTS banners (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  public_id UUID UNIQUE NOT NULL DEFAULT gen_random_uuid(),
  title VARCHAR(255) NOT NULL,
  subtitle VARCHAR(255) NULL,
  image_url TEXT NOT NULL,
  action_url TEXT NULL,
  target_url TEXT NULL,
  badge VARCHAR(50) NULL,
  media_asset_id BIGINT NULL REFERENCES media_assets(id) ON DELETE SET NULL,
  placement VARCHAR(50) NOT NULL DEFAULT 'HOME',
  start_at TIMESTAMPTZ NULL,
  end_at TIMESTAMPTZ NULL,
  sort_order INTEGER NOT NULL DEFAULT 1,
  priority INTEGER NOT NULL DEFAULT 1,
  status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE', 'DRAFT', 'EXPIRED')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_banners_status_priority ON banners (status, priority ASC, sort_order ASC);
CREATE INDEX IF NOT EXISTS idx_banners_placement ON banners (placement, status);

DROP TRIGGER IF EXISTS trg_banners_updated_at ON banners;
CREATE TRIGGER trg_banners_updated_at
BEFORE UPDATE ON banners
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

-- Backward compatibility view: promo_banners
-- Allows existing queries referencing promo_banners to work seamlessly
CREATE OR REPLACE VIEW promo_banners AS
SELECT
  id,
  public_id,
  title,
  subtitle,
  image_url,
  COALESCE(action_url, target_url) AS action_url,
  badge,
  COALESCE(priority, sort_order, 1) AS priority,
  status,
  created_at
FROM banners;

-- 4. Audit Logs Table
-- Immutable, append-only compliance log recording all critical administrative and financial actions
CREATE TABLE IF NOT EXISTS audit_logs (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  actor_user_id UUID NULL REFERENCES profiles(user_id) ON DELETE SET NULL,
  action VARCHAR(100) NOT NULL,
  entity_type VARCHAR(100) NOT NULL,
  entity_id VARCHAR(100) NOT NULL,
  old_values JSONB NULL,
  new_values JSONB NULL,
  ip_address INET NULL,
  user_agent TEXT NULL,
  request_id VARCHAR(100) NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_actor ON audit_logs (actor_user_id, created_at DESC) WHERE actor_user_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_audit_logs_entity ON audit_logs (entity_type, entity_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON audit_logs (action, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_request ON audit_logs (request_id) WHERE request_id IS NOT NULL;

-- Append-Only Immutability Trigger on Audit Logs
CREATE OR REPLACE FUNCTION prevent_audit_log_modification()
RETURNS TRIGGER AS $$
BEGIN
  RAISE EXCEPTION 'Audit logs are strictly append-only and cannot be modified or deleted.';
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_audit_logs_append_only ON audit_logs;
CREATE TRIGGER trg_audit_logs_append_only
BEFORE UPDATE OR DELETE ON audit_logs
FOR EACH ROW
EXECUTE FUNCTION prevent_audit_log_modification();

-- 5. Transactional Outbox Events Table
-- Guarantees reliable asynchronous event publishing with SKIP LOCKED concurrency pattern
CREATE TABLE IF NOT EXISTS outbox_events (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  event_id UUID UNIQUE NOT NULL DEFAULT gen_random_uuid(),
  event_type VARCHAR(100) NOT NULL,
  aggregate_type VARCHAR(100) NOT NULL,
  aggregate_id VARCHAR(100) NOT NULL,
  payload JSONB NOT NULL,
  status VARCHAR(50) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'PROCESSING', 'PROCESSED', 'FAILED')),
  attempts INTEGER NOT NULL DEFAULT 0 CHECK (attempts >= 0),
  available_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  processed_at TIMESTAMPTZ NULL,
  last_error TEXT NULL
);

-- Critical High-Performance Index for Outbox Worker claiming tasks with SELECT ... FOR UPDATE SKIP LOCKED
CREATE INDEX IF NOT EXISTS idx_outbox_events_worker
ON outbox_events (available_at, id)
WHERE status = 'PENDING';

CREATE INDEX IF NOT EXISTS idx_outbox_events_aggregate
ON outbox_events (aggregate_type, aggregate_id);
