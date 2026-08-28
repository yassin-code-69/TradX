-- ============================================================================
-- TRADEX DATABASE MIGRATION SUITE
-- Migration: 000003_wallets_double_entry_ledger.sql
-- Description: Financial Core — Wallets Snapshot, Double-Entry Ledger, Idempotency & Balance Invariant
-- ============================================================================

-- 1. Wallets Table
-- Snapshot of user balances in integer minor units (paisa / cents).
-- Never uses FLOAT or REAL. Ledger entries are the permanent accounting truth.
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
CREATE INDEX IF NOT EXISTS idx_wallets_public_id ON wallets(public_id);

DROP TRIGGER IF EXISTS trg_wallets_updated_at ON wallets;
CREATE TRIGGER trg_wallets_updated_at
BEFORE UPDATE ON wallets
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

-- 2. Ledger Accounts Table
-- Chart of accounts for double-entry bookkeeping (user accounts and system accounts).
CREATE TABLE IF NOT EXISTS ledger_accounts (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  public_id UUID UNIQUE NOT NULL DEFAULT gen_random_uuid(),
  owner_type VARCHAR(50) NOT NULL, -- 'USER' or 'SYSTEM'
  owner_id VARCHAR(255) NOT NULL,   -- UUID string for users, 'SYSTEM' for system
  account_type VARCHAR(50) NOT NULL CHECK (
    account_type IN (
      'USER_AVAILABLE',
      'USER_LOCKED',
      'DEPOSIT_CLEARING',
      'WITHDRAWAL_CLEARING',
      'PLATFORM_REVENUE',
      'PRIZE_POOL',
      'BONUS_POOL',
      'AGENT_COMMISSION',
      'SYSTEM_ADJUSTMENT'
    )
  ),
  currency CHAR(3) NOT NULL DEFAULT 'BDT',
  status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'FROZEN', 'CLOSED')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT uq_ledger_accounts_owner_type_currency UNIQUE (owner_type, owner_id, account_type, currency)
);

CREATE INDEX IF NOT EXISTS idx_ledger_accounts_lookup ON ledger_accounts(owner_type, owner_id, account_type, currency);
CREATE INDEX IF NOT EXISTS idx_ledger_accounts_type ON ledger_accounts(account_type);

DROP TRIGGER IF EXISTS trg_ledger_accounts_updated_at ON ledger_accounts;
CREATE TRIGGER trg_ledger_accounts_updated_at
BEFORE UPDATE ON ledger_accounts
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

-- Seed Default System Accounts
INSERT INTO ledger_accounts (owner_type, owner_id, account_type, currency, status) VALUES
  ('SYSTEM', 'SYSTEM', 'DEPOSIT_CLEARING', 'BDT', 'ACTIVE'),
  ('SYSTEM', 'SYSTEM', 'WITHDRAWAL_CLEARING', 'BDT', 'ACTIVE'),
  ('SYSTEM', 'SYSTEM', 'PLATFORM_REVENUE', 'BDT', 'ACTIVE'),
  ('SYSTEM', 'SYSTEM', 'PRIZE_POOL', 'BDT', 'ACTIVE'),
  ('SYSTEM', 'SYSTEM', 'BONUS_POOL', 'BDT', 'ACTIVE'),
  ('SYSTEM', 'SYSTEM', 'AGENT_COMMISSION', 'BDT', 'ACTIVE'),
  ('SYSTEM', 'SYSTEM', 'SYSTEM_ADJUSTMENT', 'BDT', 'ACTIVE')
ON CONFLICT (owner_type, owner_id, account_type, currency) DO NOTHING;

-- 3. Ledger Transactions Table
-- Header record grouping balanced debits and credits
CREATE TABLE IF NOT EXISTS ledger_transactions (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  public_id UUID UNIQUE NOT NULL DEFAULT gen_random_uuid(),
  transaction_type VARCHAR(50) NOT NULL CHECK (
    transaction_type IN (
      'DEPOSIT',
      'WITHDRAWAL',
      'WITHDRAWAL_LOCK',
      'WITHDRAWAL_REFUND',
      'USER_TRANSFER',
      'TRANSFER_FEE',
      'TICKET_PURCHASE',
      'WINNING',
      'REFUND',
      'BONUS',
      'COMMISSION',
      'ADMIN_ADJUSTMENT',
      'REVERSAL'
    )
  ),
  reference_type VARCHAR(50) NULL,
  reference_id VARCHAR(255) NULL,
  idempotency_key VARCHAR(255) NULL,
  status VARCHAR(50) NOT NULL DEFAULT 'COMPLETED' CHECK (status IN ('PENDING', 'COMPLETED', 'POSTED', 'REVERSED', 'FAILED')),
  created_by UUID NULL,
  metadata JSONB NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_ledger_transactions_type ON ledger_transactions(transaction_type, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ledger_transactions_reference ON ledger_transactions(reference_type, reference_id);
CREATE INDEX IF NOT EXISTS idx_ledger_transactions_idempotency ON ledger_transactions(idempotency_key) WHERE idempotency_key IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_ledger_transactions_created_by ON ledger_transactions(created_by, created_at DESC) WHERE created_by IS NOT NULL;

-- 4. Ledger Entries Table
-- Double-entry balanced movement items (credits: positive, debits: negative)
CREATE TABLE IF NOT EXISTS ledger_entries (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  transaction_id BIGINT NOT NULL REFERENCES ledger_transactions(id) ON DELETE RESTRICT,
  account_id BIGINT NOT NULL REFERENCES ledger_accounts(id) ON DELETE RESTRICT,
  amount_minor BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_ledger_entries_transaction ON ledger_entries(transaction_id);
CREATE INDEX IF NOT EXISTS idx_ledger_entries_account_id ON ledger_entries(account_id, id);
CREATE INDEX IF NOT EXISTS idx_ledger_entries_account_history ON ledger_entries(account_id, created_at DESC);

-- 5. Financial Balance Invariant Trigger & Validation Function
-- Asserts that for every COMPLETED or POSTED ledger transaction: SUM(amount_minor) = 0
CREATE OR REPLACE FUNCTION verify_ledger_transaction_balance(p_transaction_id BIGINT)
RETURNS BOOLEAN AS $$
DECLARE
  v_sum BIGINT;
  v_count INTEGER;
BEGIN
  SELECT COALESCE(SUM(amount_minor), 0), COUNT(*)
  INTO v_sum, v_count
  FROM ledger_entries
  WHERE transaction_id = p_transaction_id;

  IF v_count = 0 OR v_sum <> 0 THEN
    RETURN FALSE;
  END IF;
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Trigger Function for balance invariant
CREATE OR REPLACE FUNCTION check_ledger_balance_invariant_trigger()
RETURNS TRIGGER AS $$
DECLARE
  v_sum BIGINT;
  v_tx_id BIGINT;
  v_status VARCHAR;
BEGIN
  v_tx_id := COALESCE(NEW.transaction_id, OLD.transaction_id);

  SELECT status INTO v_status FROM ledger_transactions WHERE id = v_tx_id;

  -- Only assert invariant when transaction is finalized as COMPLETED or POSTED
  IF v_status IN ('COMPLETED', 'POSTED') THEN
    SELECT COALESCE(SUM(amount_minor), 0) INTO v_sum
    FROM ledger_entries
    WHERE transaction_id = v_tx_id;

    IF v_sum <> 0 THEN
      RAISE EXCEPTION 'Financial balance invariant violated for transaction_id %: SUM(amount_minor) is % (must equal 0)',
        v_tx_id, v_sum;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Constraint trigger on ledger_entries deferred to commit time
DROP TRIGGER IF EXISTS trg_assert_ledger_balance_entries ON ledger_entries;
CREATE CONSTRAINT TRIGGER trg_assert_ledger_balance_entries
AFTER INSERT OR UPDATE OR DELETE ON ledger_entries
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION check_ledger_balance_invariant_trigger();

-- 6. Idempotency Keys Table
-- Guarantees once-only execution for financial transactions
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

CREATE INDEX IF NOT EXISTS idx_idempotency_lookup ON idempotency_keys(user_id, operation, key);
CREATE INDEX IF NOT EXISTS idx_idempotency_expires ON idempotency_keys(expires_at);
