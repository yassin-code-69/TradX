-- ============================================================================
-- TRADEX Consolidated Production Schema
-- Compiled from migrations 000001 through 000007
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE SCHEMA IF NOT EXISTS auth;

CREATE TABLE IF NOT EXISTS auth.users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Reusable timestamp trigger function
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 1. Media Assets
CREATE TABLE IF NOT EXISTS media_assets (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  public_id UUID UNIQUE NOT NULL DEFAULT gen_random_uuid(),
  owner_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  cloudinary_public_id VARCHAR(255) UNIQUE NOT NULL,
  secure_url TEXT NOT NULL,
  resource_type VARCHAR(50) NOT NULL DEFAULT 'image',
  asset_type VARCHAR(50) NOT NULL DEFAULT 'general',
  width INTEGER NULL,
  height INTEGER NULL,
  bytes BIGINT NULL,
  mime_type VARCHAR(100) NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_media_assets_owner ON media_assets(owner_user_id);
CREATE INDEX IF NOT EXISTS idx_media_assets_public_id ON media_assets(public_id);

-- 2. Profiles
CREATE TABLE IF NOT EXISTS profiles (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE RESTRICT,
  public_id UUID UNIQUE NOT NULL DEFAULT gen_random_uuid(),
  username VARCHAR(100) NULL,
  full_name VARCHAR(255) NULL,
  phone VARCHAR(50) NULL,
  email VARCHAR(255) NULL,
  avatar_asset_id BIGINT NULL REFERENCES media_assets(id) ON DELETE SET NULL,
  status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'SUSPENDED', 'BLOCKED', 'CLOSED')),
  kyc_status VARCHAR(50) NOT NULL DEFAULT 'NOT_SUBMITTED' CHECK (kyc_status IN ('NOT_SUBMITTED', 'PENDING', 'VERIFIED', 'REJECTED')),
  role VARCHAR(50) NOT NULL DEFAULT 'USER',
  referral_code VARCHAR(100) UNIQUE NULL,
  referred_by UUID NULL REFERENCES profiles(user_id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_profiles_username_lower ON profiles (lower(username)) WHERE username IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_profiles_phone ON profiles (phone) WHERE phone IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_profiles_email_lower ON profiles (lower(email)) WHERE email IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_profiles_referred_by ON profiles (referred_by) WHERE referred_by IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_profiles_status ON profiles (status);
CREATE INDEX IF NOT EXISTS idx_profiles_public_id ON profiles (public_id);

DROP TRIGGER IF EXISTS trg_profiles_updated_at ON profiles;
CREATE TRIGGER trg_profiles_updated_at
BEFORE UPDATE ON profiles
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

-- 3. User KYC
CREATE TABLE IF NOT EXISTS user_kyc (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  public_id UUID UNIQUE NOT NULL DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE NOT NULL REFERENCES profiles(user_id) ON DELETE RESTRICT,
  status VARCHAR(50) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('NOT_SUBMITTED', 'PENDING', 'VERIFIED', 'REJECTED')),
  document_type VARCHAR(50) NOT NULL CHECK (document_type IN ('NID', 'PASSPORT', 'DRIVING_LICENSE', 'OTHER')),
  document_number_masked VARCHAR(100) NOT NULL,
  front_asset_id BIGINT NULL REFERENCES media_assets(id) ON DELETE RESTRICT,
  back_asset_id BIGINT NULL REFERENCES media_assets(id) ON DELETE RESTRICT,
  selfie_asset_id BIGINT NULL REFERENCES media_assets(id) ON DELETE RESTRICT,
  reject_reason TEXT NULL,
  submitted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  reviewed_at TIMESTAMPTZ NULL,
  reviewed_by UUID NULL REFERENCES profiles(user_id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_user_kyc_user ON user_kyc (user_id);
CREATE INDEX IF NOT EXISTS idx_user_kyc_status ON user_kyc (status);
CREATE INDEX IF NOT EXISTS idx_user_kyc_pending ON user_kyc (submitted_at DESC) WHERE status = 'PENDING';

DROP TRIGGER IF EXISTS trg_user_kyc_updated_at ON user_kyc;
CREATE TRIGGER trg_user_kyc_updated_at
BEFORE UPDATE ON user_kyc
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

-- 4. RBAC Roles & Permissions
CREATE TABLE IF NOT EXISTS roles (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  code VARCHAR(50) UNIQUE NOT NULL,
  name VARCHAR(100) NOT NULL,
  description TEXT NULL,
  is_system BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS permissions (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  code VARCHAR(100) UNIQUE NOT NULL,
  name VARCHAR(150) NOT NULL,
  description TEXT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS role_permissions (
  role_id BIGINT NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
  permission_id BIGINT NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (role_id, permission_id)
);
CREATE INDEX IF NOT EXISTS idx_role_permissions_permission_id ON role_permissions(permission_id);

CREATE TABLE IF NOT EXISTS user_roles (
  user_id UUID NOT NULL REFERENCES profiles(user_id) ON DELETE CASCADE,
  role_id BIGINT NOT NULL REFERENCES roles(id) ON DELETE RESTRICT,
  assigned_by UUID NULL REFERENCES profiles(user_id) ON DELETE SET NULL,
  assigned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, role_id)
);
CREATE INDEX IF NOT EXISTS idx_user_roles_role_id ON user_roles(role_id);

-- 5. Wallets & Ledger
CREATE TABLE IF NOT EXISTS wallets (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  public_id UUID UNIQUE NOT NULL DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE NOT NULL REFERENCES profiles(user_id) ON DELETE RESTRICT,
  currency CHAR(3) NOT NULL DEFAULT 'BDT',
  available_balance_minor BIGINT NOT NULL DEFAULT 0 CHECK (available_balance_minor >= 0),
  locked_balance_minor BIGINT NOT NULL DEFAULT 0 CHECK (locked_balance_minor >= 0),
  version BIGINT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_wallets_user_id ON wallets(user_id);

DROP TRIGGER IF EXISTS trg_wallets_updated_at ON wallets;
CREATE TRIGGER trg_wallets_updated_at
BEFORE UPDATE ON wallets
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TABLE IF NOT EXISTS ledger_accounts (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  public_id UUID UNIQUE NOT NULL DEFAULT gen_random_uuid(),
  owner_type VARCHAR(50) NOT NULL,
  owner_id VARCHAR(255) NOT NULL,
  account_type VARCHAR(50) NOT NULL CHECK (
    account_type IN (
      'USER_AVAILABLE', 'USER_LOCKED', 'DEPOSIT_CLEARING', 'WITHDRAWAL_CLEARING',
      'PLATFORM_REVENUE', 'PRIZE_POOL', 'BONUS_POOL', 'AGENT_COMMISSION', 'SYSTEM_ADJUSTMENT'
    )
  ),
  currency CHAR(3) NOT NULL DEFAULT 'BDT',
  status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'FROZEN', 'CLOSED')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT uq_ledger_accounts_owner_type_currency UNIQUE (owner_type, owner_id, account_type, currency)
);

CREATE TABLE IF NOT EXISTS ledger_transactions (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  public_id UUID UNIQUE NOT NULL DEFAULT gen_random_uuid(),
  transaction_type VARCHAR(50) NOT NULL,
  reference_type VARCHAR(50) NULL,
  reference_id VARCHAR(255) NULL,
  idempotency_key VARCHAR(255) NULL,
  status VARCHAR(50) NOT NULL DEFAULT 'COMPLETED' CHECK (status IN ('PENDING', 'COMPLETED', 'POSTED', 'REVERSED', 'FAILED')),
  created_by UUID NULL,
  metadata JSONB NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS ledger_entries (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  transaction_id BIGINT NOT NULL REFERENCES ledger_transactions(id) ON DELETE RESTRICT,
  account_id BIGINT NOT NULL REFERENCES ledger_accounts(id) ON DELETE RESTRICT,
  amount_minor BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_ledger_entries_transaction ON ledger_entries(transaction_id);
CREATE INDEX IF NOT EXISTS idx_ledger_entries_account_id ON ledger_entries(account_id, id);

CREATE TABLE IF NOT EXISTS idempotency_keys (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES profiles(user_id) ON DELETE CASCADE,
  operation VARCHAR(100) NOT NULL,
  key VARCHAR(255) NOT NULL,
  request_hash VARCHAR(255) NOT NULL,
  response_status INTEGER NOT NULL,
  response_body JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (now() + INTERVAL '24 hours'),
  CONSTRAINT uq_idempotency_keys_user_op_key UNIQUE (user_id, operation, key)
);

-- 6. Payment Methods, Deposits, Withdrawals & Transfers
CREATE TABLE IF NOT EXISTS payment_methods (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  public_id UUID UNIQUE NOT NULL DEFAULT gen_random_uuid(),
  code VARCHAR(50) UNIQUE NOT NULL,
  name VARCHAR(100) NOT NULL,
  type VARCHAR(50) NOT NULL DEFAULT 'MOBILE_BANKING',
  account_number VARCHAR(100) NOT NULL,
  account_name VARCHAR(100) NOT NULL,
  instructions TEXT NOT NULL,
  minimum_deposit_minor BIGINT NOT NULL DEFAULT 10000 CHECK (minimum_deposit_minor > 0),
  maximum_deposit_minor BIGINT NOT NULL DEFAULT 2500000 CHECK (maximum_deposit_minor >= minimum_deposit_minor),
  minimum_withdraw_minor BIGINT NOT NULL DEFAULT 10000 CHECK (minimum_withdraw_minor > 0),
  maximum_withdraw_minor BIGINT NOT NULL DEFAULT 2500000 CHECK (maximum_withdraw_minor >= minimum_withdraw_minor),
  deposit_fee_percentage_basis_points INTEGER NOT NULL DEFAULT 0 CHECK (deposit_fee_percentage_basis_points >= 0),
  deposit_fee_fixed_minor BIGINT NOT NULL DEFAULT 0 CHECK (deposit_fee_fixed_minor >= 0),
  withdraw_fee_percentage_basis_points INTEGER NOT NULL DEFAULT 0 CHECK (withdraw_fee_percentage_basis_points >= 0),
  withdraw_fee_fixed_minor BIGINT NOT NULL DEFAULT 0 CHECK (withdraw_fee_fixed_minor >= 0),
  deposit_enabled BOOLEAN NOT NULL DEFAULT true,
  withdraw_enabled BOOLEAN NOT NULL DEFAULT true,
  display_order INTEGER NOT NULL DEFAULT 0,
  status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE', 'MAINTENANCE')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS deposit_requests (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  public_id UUID UNIQUE NOT NULL DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(user_id) ON DELETE RESTRICT,
  payment_method_id BIGINT NOT NULL REFERENCES payment_methods(id) ON DELETE RESTRICT,
  amount_minor BIGINT NOT NULL CHECK (amount_minor > 0),
  sender_account VARCHAR(100) NOT NULL,
  provider_transaction_id VARCHAR(100) NULL,
  proof_asset_id BIGINT NULL REFERENCES media_assets(id) ON DELETE RESTRICT,
  status VARCHAR(50) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED', 'CANCELLED')),
  reviewed_by UUID NULL REFERENCES profiles(user_id) ON DELETE SET NULL,
  reviewed_at TIMESTAMPTZ NULL,
  reject_reason TEXT NULL,
  ledger_transaction_id BIGINT NULL REFERENCES ledger_transactions(id) ON DELETE RESTRICT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_deposit_requests_provider_tx
ON deposit_requests (payment_method_id, provider_transaction_id)
WHERE provider_transaction_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_deposit_requests_pending ON deposit_requests (created_at DESC) WHERE status = 'PENDING';

CREATE TABLE IF NOT EXISTS withdrawal_requests (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  public_id UUID UNIQUE NOT NULL DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(user_id) ON DELETE RESTRICT,
  payment_method_id BIGINT NOT NULL REFERENCES payment_methods(id) ON DELETE RESTRICT,
  receiver_account VARCHAR(100) NOT NULL,
  amount_minor BIGINT NOT NULL CHECK (amount_minor > 0),
  fee_minor BIGINT NOT NULL DEFAULT 0 CHECK (fee_minor >= 0),
  net_amount_minor BIGINT NOT NULL CHECK (net_amount_minor > 0),
  status VARCHAR(50) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED', 'CANCELLED')),
  reviewed_by UUID NULL REFERENCES profiles(user_id) ON DELETE SET NULL,
  reviewed_at TIMESTAMPTZ NULL,
  completed_at TIMESTAMPTZ NULL,
  reject_reason TEXT NULL,
  ledger_transaction_id BIGINT NULL REFERENCES ledger_transactions(id) ON DELETE RESTRICT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT chk_withdrawal_net_amount CHECK (net_amount_minor = amount_minor - fee_minor)
);
CREATE INDEX IF NOT EXISTS idx_withdrawal_requests_pending ON withdrawal_requests (created_at DESC) WHERE status = 'PENDING';

CREATE TABLE IF NOT EXISTS wallet_transfers (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  public_id UUID UNIQUE NOT NULL DEFAULT gen_random_uuid(),
  sender_user_id UUID NOT NULL REFERENCES profiles(user_id) ON DELETE RESTRICT,
  receiver_user_id UUID NOT NULL REFERENCES profiles(user_id) ON DELETE RESTRICT,
  amount_minor BIGINT NOT NULL CHECK (amount_minor > 0),
  fee_minor BIGINT NOT NULL DEFAULT 0 CHECK (fee_minor >= 0),
  status VARCHAR(50) NOT NULL DEFAULT 'COMPLETED' CHECK (status IN ('PENDING', 'COMPLETED', 'FAILED', 'REVERSED')),
  ledger_transaction_id BIGINT NULL REFERENCES ledger_transactions(id) ON DELETE RESTRICT,
  idempotency_key VARCHAR(255) NULL,
  note VARCHAR(500) NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at TIMESTAMPTZ NULL,
  CONSTRAINT chk_wallet_transfers_no_self_transfer CHECK (sender_user_id <> receiver_user_id)
);

-- 7. Draws, Tickets, Results, Winners
CREATE TABLE IF NOT EXISTS draw_types (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  code VARCHAR(50) UNIQUE NOT NULL,
  name VARCHAR(100) NOT NULL,
  digit_length SMALLINT NOT NULL CHECK (digit_length > 0),
  default_ticket_price_minor BIGINT NOT NULL CHECK (default_ticket_price_minor > 0),
  status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS draws (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  public_id UUID UNIQUE NOT NULL DEFAULT gen_random_uuid(),
  draw_type_id BIGINT NOT NULL REFERENCES draw_types(id) ON DELETE RESTRICT,
  sequence_number VARCHAR(100) NOT NULL,
  ticket_price_minor BIGINT NOT NULL CHECK (ticket_price_minor > 0),
  sale_open_at TIMESTAMPTZ NOT NULL,
  sale_close_at TIMESTAMPTZ NOT NULL,
  draw_at TIMESTAMPTZ NOT NULL,
  status VARCHAR(50) NOT NULL DEFAULT 'SCHEDULED' CHECK (
    status IN ('DRAFT', 'SCHEDULED', 'OPEN', 'CLOSED', 'PROCESSING', 'COMPLETED', 'CANCELLED')
  ),
  total_tickets BIGINT NOT NULL DEFAULT 0 CHECK (total_tickets >= 0),
  total_sales_minor BIGINT NOT NULL DEFAULT 0 CHECK (total_sales_minor >= 0),
  created_by UUID NULL REFERENCES profiles(user_id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT chk_draw_sale_window CHECK (sale_open_at < sale_close_at),
  CONSTRAINT chk_draw_close_before_draw CHECK (sale_close_at <= draw_at)
);
CREATE INDEX IF NOT EXISTS idx_draws_open ON draws (draw_at) WHERE status = 'OPEN';

CREATE TABLE IF NOT EXISTS number_rules (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  draw_type_id BIGINT NOT NULL REFERENCES draw_types(id) ON DELETE CASCADE,
  number_value VARCHAR(50) NOT NULL,
  rule_type VARCHAR(50) NOT NULL CHECK (rule_type IN ('ALLOWED', 'BLOCKED', 'HOT')),
  reason TEXT NULL,
  start_at TIMESTAMPTZ NULL,
  end_at TIMESTAMPTZ NULL,
  created_by UUID NULL REFERENCES profiles(user_id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS prize_rules (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  draw_type_id BIGINT NOT NULL REFERENCES draw_types(id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL,
  match_type VARCHAR(50) NOT NULL,
  prize_amount_minor BIGINT NOT NULL CHECK (prize_amount_minor > 0),
  priority INTEGER NOT NULL DEFAULT 1,
  status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS draw_prize_rules (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  draw_id BIGINT NOT NULL REFERENCES draws(id) ON DELETE CASCADE,
  rule_code VARCHAR(50) NOT NULL,
  name VARCHAR(100) NOT NULL,
  match_type VARCHAR(50) NOT NULL,
  prize_amount_minor BIGINT NOT NULL CHECK (prize_amount_minor > 0),
  priority INTEGER NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS ticket_orders (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  public_id UUID UNIQUE NOT NULL DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(user_id) ON DELETE RESTRICT,
  draw_id BIGINT NOT NULL REFERENCES draws(id) ON DELETE RESTRICT,
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  unit_price_minor BIGINT NOT NULL CHECK (unit_price_minor > 0),
  subtotal_minor BIGINT NOT NULL DEFAULT 0 CHECK (subtotal_minor >= 0),
  discount_minor BIGINT NOT NULL DEFAULT 0 CHECK (discount_minor >= 0),
  total_minor BIGINT NOT NULL CHECK (total_minor >= 0),
  status VARCHAR(50) NOT NULL DEFAULT 'PAID' CHECK (status IN ('PENDING', 'PAID', 'CANCELLED', 'REFUNDED')),
  ledger_transaction_id BIGINT NULL REFERENCES ledger_transactions(id) ON DELETE RESTRICT,
  idempotency_key VARCHAR(255) NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS tickets (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  public_id UUID UNIQUE NOT NULL DEFAULT gen_random_uuid(),
  order_id BIGINT NOT NULL REFERENCES ticket_orders(id) ON DELETE RESTRICT,
  user_id UUID NOT NULL REFERENCES profiles(user_id) ON DELETE RESTRICT,
  draw_id BIGINT NOT NULL REFERENCES draws(id) ON DELETE RESTRICT,
  selected_number VARCHAR(50) NOT NULL CHECK (selected_number ~ '^[0-9]+$'),
  ticket_price_minor BIGINT NOT NULL CHECK (ticket_price_minor > 0),
  status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'CANCELLED', 'REFUNDED', 'WON', 'LOST')),
  is_winner BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_tickets_draw_number ON tickets (draw_id, selected_number);
CREATE INDEX IF NOT EXISTS idx_tickets_user_history ON tickets (user_id, created_at DESC);

CREATE TABLE IF NOT EXISTS draw_results (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  public_id UUID UNIQUE NOT NULL DEFAULT gen_random_uuid(),
  draw_id BIGINT UNIQUE NOT NULL REFERENCES draws(id) ON DELETE RESTRICT,
  winning_number VARCHAR(50) NOT NULL CHECK (winning_number ~ '^[0-9]+$'),
  result_hash VARCHAR(255) NULL,
  published_by UUID NULL REFERENCES profiles(user_id) ON DELETE SET NULL,
  published_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS draw_result_revisions (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  draw_result_id BIGINT NOT NULL REFERENCES draw_results(id) ON DELETE RESTRICT,
  old_winning_number VARCHAR(50) NOT NULL,
  new_winning_number VARCHAR(50) NOT NULL,
  reason TEXT NOT NULL,
  changed_by UUID NOT NULL REFERENCES profiles(user_id) ON DELETE RESTRICT,
  revision_number INTEGER NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS winners (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  public_id UUID UNIQUE NOT NULL DEFAULT gen_random_uuid(),
  draw_id BIGINT NOT NULL REFERENCES draws(id) ON DELETE RESTRICT,
  ticket_id BIGINT UNIQUE NOT NULL REFERENCES tickets(id) ON DELETE RESTRICT,
  user_id UUID NOT NULL REFERENCES profiles(user_id) ON DELETE RESTRICT,
  prize_rule_id BIGINT NULL REFERENCES prize_rules(id) ON DELETE SET NULL,
  winning_amount_minor BIGINT NOT NULL CHECK (winning_amount_minor > 0),
  status VARCHAR(50) NOT NULL DEFAULT 'PAID' CHECK (status IN ('PENDING', 'PAID', 'CANCELLED', 'CLAIMED')),
  ledger_transaction_id BIGINT NULL REFERENCES ledger_transactions(id) ON DELETE RESTRICT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  paid_at TIMESTAMPTZ NULL
);

-- 8. Notifications, Deliveries, Banners, Audit, Outbox
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
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON notifications (user_id, created_at DESC) WHERE read_at IS NULL;

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
CREATE INDEX IF NOT EXISTS idx_outbox_events_worker ON outbox_events (available_at, id) WHERE status = 'PENDING';
