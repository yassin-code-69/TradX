-- ============================================================================
-- TRADEX DATABASE MIGRATION SUITE
-- Migration: 000005_draws_tickets_results_winners.sql
-- Description: Lottery Core — Draw Types, Draws, Number Rules, Tickets, Results & Winners
-- ============================================================================

-- 1. Draw Types Table
-- Defines rules and formats for Mega (7-digit), Daily (3-digit), and Hourly (3-digit) draws
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

DROP TRIGGER IF EXISTS trg_draw_types_updated_at ON draw_types;
CREATE TRIGGER trg_draw_types_updated_at
BEFORE UPDATE ON draw_types
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

-- Seed Deterministic Draw Types
INSERT INTO draw_types (code, name, digit_length, default_ticket_price_minor, status) VALUES
  ('MEGA', 'Mega Draw', 7, 5000, 'ACTIVE'),       -- 7-digit: 0000000 - 9999999, ৳50.00
  ('DAILY', 'Daily Draw', 3, 2000, 'ACTIVE'),     -- 3-digit: 000 - 999, ৳20.00
  ('HOURLY', 'Hourly Draw', 3, 1000, 'ACTIVE')    -- 3-digit: 000 - 999, ৳10.00
ON CONFLICT (code) DO NOTHING;

-- 2. Draws Table
-- Individual scheduled lottery rounds with strict chronological invariants
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

CREATE INDEX IF NOT EXISTS idx_draws_type_draw_at ON draws (draw_type_id, draw_at DESC);
CREATE INDEX IF NOT EXISTS idx_draws_status_draw_at ON draws (status, draw_at);
CREATE INDEX IF NOT EXISTS idx_draws_created_by ON draws (created_by) WHERE created_by IS NOT NULL;

-- High performance partial index for active draws
CREATE INDEX IF NOT EXISTS idx_draws_open ON draws (draw_at) WHERE status = 'OPEN';

DROP TRIGGER IF EXISTS trg_draws_updated_at ON draws;
CREATE TRIGGER trg_draws_updated_at
BEFORE UPDATE ON draws
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

-- 3. Number Rules Table
-- Number management: ALLOWED, BLOCKED, and HOT numbers per draw type
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

CREATE INDEX IF NOT EXISTS idx_number_rules_lookup ON number_rules (draw_type_id, number_value);
CREATE INDEX IF NOT EXISTS idx_number_rules_type ON number_rules (draw_type_id, rule_type);

DROP TRIGGER IF EXISTS trg_number_rules_updated_at ON number_rules;
CREATE TRIGGER trg_number_rules_updated_at
BEFORE UPDATE ON number_rules
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

-- 4. Prize Rules Table
-- Payout tiers based on match type (exact match, suffix matches)
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

CREATE INDEX IF NOT EXISTS idx_prize_rules_draw_type ON prize_rules (draw_type_id, priority ASC);

-- Historical snapshot of prize rules locked at draw creation time
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

CREATE INDEX IF NOT EXISTS idx_draw_prize_rules_draw ON draw_prize_rules (draw_id, priority ASC);

-- 5. Ticket Orders Table
-- Purchase orders grouped into single financial transactions
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

CREATE INDEX IF NOT EXISTS idx_ticket_orders_user ON ticket_orders (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ticket_orders_draw ON ticket_orders (draw_id);
CREATE INDEX IF NOT EXISTS idx_ticket_orders_ledger ON ticket_orders (ledger_transaction_id) WHERE ledger_transaction_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_ticket_orders_idempotency ON ticket_orders (idempotency_key) WHERE idempotency_key IS NOT NULL;

-- 6. Tickets Table
-- Individual lottery ticket entries.
-- CRITICAL RULE: selected_number must be stored as VARCHAR to preserve leading zeros ('0012345', '007').
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

-- Highly optimized indexes for ticket verification and winner discovery
CREATE INDEX IF NOT EXISTS idx_tickets_draw_number ON tickets (draw_id, selected_number);
CREATE INDEX IF NOT EXISTS idx_tickets_user_history ON tickets (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_tickets_order_id ON tickets (order_id);
CREATE INDEX IF NOT EXISTS idx_tickets_winners ON tickets (draw_id, created_at DESC) WHERE is_winner = true;

DROP TRIGGER IF EXISTS trg_tickets_updated_at ON tickets;
CREATE TRIGGER trg_tickets_updated_at
BEFORE UPDATE ON tickets
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

-- 7. Draw Results Table
-- Official published results with cryptographic result hash and immutability protection
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

CREATE INDEX IF NOT EXISTS idx_draw_results_draw_id ON draw_results (draw_id);

-- Result Revisions (Formal legal audit trail in case of officially mandated revisions)
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

CREATE INDEX IF NOT EXISTS idx_draw_result_revisions_result ON draw_result_revisions (draw_result_id);

-- Immutability Guard Trigger: Prevents direct silent edits to official winning numbers
CREATE OR REPLACE FUNCTION prevent_draw_result_modification()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'UPDATE' THEN
    IF OLD.winning_number <> NEW.winning_number THEN
      RAISE EXCEPTION 'Official draw results are immutable. Winning numbers cannot be directly modified. Use draw_result_revisions.';
    END IF;
  ELSIF TG_OP = 'DELETE' THEN
    RAISE EXCEPTION 'Official draw results are immutable and cannot be deleted.';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_draw_results_immutability ON draw_results;
CREATE TRIGGER trg_draw_results_immutability
BEFORE UPDATE OR DELETE ON draw_results
FOR EACH ROW
EXECUTE FUNCTION prevent_draw_result_modification();

-- 8. Winners Table
-- Records calculated winners and links directly to double-entry ledger payout transactions
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

CREATE INDEX IF NOT EXISTS idx_winners_user_history ON winners (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_winners_draw_status ON winners (draw_id, status);
CREATE INDEX IF NOT EXISTS idx_winners_prize_rule ON winners (prize_rule_id) WHERE prize_rule_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_winners_ledger ON winners (ledger_transaction_id) WHERE ledger_transaction_id IS NOT NULL;
