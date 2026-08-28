-- ============================================================================
-- TRADEX DATABASE MIGRATION SUITE
-- Migration: 000004_payment_methods_deposits_withdrawals.sql
-- Description: Payment Methods, Manual Deposits, Withdrawals, and User-to-User Transfers
-- ============================================================================

-- 1. Payment Methods Table
-- Configured payment gateways/methods for Bangladesh e-wallets and banks
CREATE TABLE IF NOT EXISTS payment_methods (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  public_id UUID UNIQUE NOT NULL DEFAULT gen_random_uuid(),
  code VARCHAR(50) UNIQUE NOT NULL,
  name VARCHAR(100) NOT NULL,
  type VARCHAR(50) NOT NULL DEFAULT 'MOBILE_BANKING', -- 'MOBILE_BANKING' or 'BANK'
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

DROP TRIGGER IF EXISTS trg_payment_methods_updated_at ON payment_methods;
CREATE TRIGGER trg_payment_methods_updated_at
BEFORE UPDATE ON payment_methods
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

-- Seed Standard Payment Methods (bKash, Nagad, Rocket, Bank)
INSERT INTO payment_methods (
  code, name, type, account_number, account_name, instructions,
  minimum_deposit_minor, maximum_deposit_minor,
  minimum_withdraw_minor, maximum_withdraw_minor,
  deposit_fee_percentage_basis_points, deposit_fee_fixed_minor,
  withdraw_fee_percentage_basis_points, withdraw_fee_fixed_minor,
  deposit_enabled, withdraw_enabled, display_order, status
) VALUES
  (
    'BKASH', 'bKash', 'MOBILE_BANKING', '01700000000', 'TRADEX Merchant',
    'Cash-in or Send Money to the merchant number. Enter your transaction ID (TrxID) below for verification.',
    10000, 2500000, 10000, 2500000, 0, 0, 180, 0, true, true, 1, 'ACTIVE'
  ),
  (
    'NAGAD', 'Nagad', 'MOBILE_BANKING', '01800000000', 'TRADEX Merchant',
    'Send Money to the Nagad merchant number and provide your transaction reference number.',
    10000, 2500000, 10000, 2500000, 0, 0, 150, 0, true, true, 2, 'ACTIVE'
  ),
  (
    'ROCKET', 'Rocket', 'MOBILE_BANKING', '019000000000', 'TRADEX Merchant',
    'Send Money via Dutch-Bangla Rocket and submit the 12-digit transaction ID.',
    10000, 2500000, 10000, 2500000, 0, 0, 180, 0, true, true, 3, 'ACTIVE'
  ),
  (
    'BANK', 'Bank Transfer', 'BANK', '100.120.345678', 'TRADEX Ltd (City Bank)',
    'Transfer funds via BEFTN, NPSB, or RTGS. Submit your deposit receipt and bank reference number.',
    50000, 10000000, 50000, 10000000, 0, 0, 0, 0, true, true, 4, 'ACTIVE'
  )
ON CONFLICT (code) DO NOTHING;

-- 2. Deposit Requests Table
-- Manual deposits requiring administrative or automated gateway verification
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

-- Unique Partial Index preventing duplicate provider transaction IDs
CREATE UNIQUE INDEX IF NOT EXISTS idx_deposit_requests_provider_tx
ON deposit_requests (payment_method_id, provider_transaction_id)
WHERE provider_transaction_id IS NOT NULL;

-- Deposit Foreign Key & History Indexes
CREATE INDEX IF NOT EXISTS idx_deposit_requests_user ON deposit_requests (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_deposit_requests_payment_method ON deposit_requests (payment_method_id);
CREATE INDEX IF NOT EXISTS idx_deposit_requests_ledger ON deposit_requests (ledger_transaction_id) WHERE ledger_transaction_id IS NOT NULL;

-- Partial Index for high performance admin queue
CREATE INDEX IF NOT EXISTS idx_deposit_requests_pending ON deposit_requests (created_at DESC) WHERE status = 'PENDING';

DROP TRIGGER IF EXISTS trg_deposit_requests_updated_at ON deposit_requests;
CREATE TRIGGER trg_deposit_requests_updated_at
BEFORE UPDATE ON deposit_requests
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

-- 3. Withdrawal Requests Table
-- User payouts requiring validation, balance locking, and clearance
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

CREATE INDEX IF NOT EXISTS idx_withdrawal_requests_user ON withdrawal_requests (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_withdrawal_requests_payment_method ON withdrawal_requests (payment_method_id);
CREATE INDEX IF NOT EXISTS idx_withdrawal_requests_ledger ON withdrawal_requests (ledger_transaction_id) WHERE ledger_transaction_id IS NOT NULL;

-- Partial Index for fast pending withdrawal queue
CREATE INDEX IF NOT EXISTS idx_withdrawal_requests_pending ON withdrawal_requests (created_at DESC) WHERE status = 'PENDING';

DROP TRIGGER IF EXISTS trg_withdrawal_requests_updated_at ON withdrawal_requests;
CREATE TRIGGER trg_withdrawal_requests_updated_at
BEFORE UPDATE ON withdrawal_requests
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

-- 4. User-to-User Wallet Transfers Table
-- Atomic peer-to-peer balance movement
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

CREATE INDEX IF NOT EXISTS idx_wallet_transfers_sender ON wallet_transfers (sender_user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_wallet_transfers_receiver ON wallet_transfers (receiver_user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_wallet_transfers_ledger ON wallet_transfers (ledger_transaction_id) WHERE ledger_transaction_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_wallet_transfers_idempotency ON wallet_transfers (idempotency_key) WHERE idempotency_key IS NOT NULL;
