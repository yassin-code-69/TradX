-- ============================================================================
-- TRADEX DATABASE MIGRATION SUITE
-- Migration: 000002_rbac_roles_permissions.sql
-- Description: Role-Based Access Control (RBAC): Roles, Permissions, User Roles, and Deterministic Seeds
-- ============================================================================

-- 1. Roles Table
CREATE TABLE IF NOT EXISTS roles (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  code VARCHAR(50) UNIQUE NOT NULL,
  name VARCHAR(100) NOT NULL,
  description TEXT NULL,
  is_system BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

DROP TRIGGER IF EXISTS trg_roles_updated_at ON roles;
CREATE TRIGGER trg_roles_updated_at
BEFORE UPDATE ON roles
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

-- 2. Permissions Table
CREATE TABLE IF NOT EXISTS permissions (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  code VARCHAR(100) UNIQUE NOT NULL,
  name VARCHAR(150) NOT NULL,
  description TEXT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

DROP TRIGGER IF EXISTS trg_permissions_updated_at ON permissions;
CREATE TRIGGER trg_permissions_updated_at
BEFORE UPDATE ON permissions
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

-- 3. Role Permissions (Many-to-Many junction between roles and permissions)
CREATE TABLE IF NOT EXISTS role_permissions (
  role_id BIGINT NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
  permission_id BIGINT NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (role_id, permission_id)
);

-- Index foreign key column for joins and cascades
CREATE INDEX IF NOT EXISTS idx_role_permissions_permission_id ON role_permissions(permission_id);

-- 4. User Roles (Assignment of roles to profiles)
CREATE TABLE IF NOT EXISTS user_roles (
  user_id UUID NOT NULL REFERENCES profiles(user_id) ON DELETE CASCADE,
  role_id BIGINT NOT NULL REFERENCES roles(id) ON DELETE RESTRICT,
  assigned_by UUID NULL REFERENCES profiles(user_id) ON DELETE SET NULL,
  assigned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, role_id)
);

-- Foreign key indexes
CREATE INDEX IF NOT EXISTS idx_user_roles_role_id ON user_roles(role_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_assigned_by ON user_roles(assigned_by);

-- 5. Deterministic System Roles Seed
INSERT INTO roles (code, name, description, is_system) VALUES
  ('SUPER_ADMIN', 'Super Administrator', 'Full platform access and root administrative control', true),
  ('ADMIN', 'Administrator', 'Standard administrative operations and management access', true),
  ('FINANCE_ADMIN', 'Finance Administrator', 'Financial operations, deposit/withdrawal processing, and ledger auditing', true),
  ('DRAW_MANAGER', 'Draw Manager', 'Lottery draw scheduling, number management, and results publication', true),
  ('SUPPORT', 'Customer Support', 'Customer support, viewing user profiles, and KYC identity document verification', true),
  ('AGENT', 'Agent', 'Affiliate and regional agent operations and commission tracking', true),
  ('USER', 'Standard User', 'Registered lottery participant with personal wallet and ticket features', true)
ON CONFLICT (code) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  is_system = EXCLUDED.is_system;

-- 6. Deterministic Standard Permissions Seed
INSERT INTO permissions (code, name, description) VALUES
  ('users.view', 'View Users', 'View user profile listings and profile details'),
  ('users.manage', 'Manage Users', 'Edit user profile information, statuses, and role assignments'),
  ('users.block', 'Block Users', 'Suspend, block, or close user accounts'),
  ('kyc.view', 'View KYC', 'Inspect submitted identity and KYC documentation'),
  ('kyc.review', 'Review KYC', 'Approve or reject submitted KYC verification requests'),
  ('deposits.view', 'View Deposits', 'View deposit history and queue of pending deposits'),
  ('deposits.approve', 'Approve Deposits', 'Approve manual deposits and credit funds to user wallets'),
  ('deposits.reject', 'Reject Deposits', 'Reject invalid or unverified deposit requests'),
  ('withdrawals.view', 'View Withdrawals', 'View withdrawal requests and historical payouts'),
  ('withdrawals.approve', 'Approve Withdrawals', 'Approve and finalize withdrawal disbursements'),
  ('withdrawals.reject', 'Reject Withdrawals', 'Reject withdrawal requests and unlock locked balances'),
  ('wallet.view', 'View Wallets', 'Inspect user wallet balances and ledger account snapshots'),
  ('wallet.adjust', 'Adjust Wallets', 'Execute double-entry ledger backed balance adjustments'),
  ('wallet.transfer', 'Transfer Funds', 'Perform user-to-user wallet transfers'),
  ('draws.view', 'View Draws', 'View lottery draw catalog, schedules, and active rounds'),
  ('draws.create', 'Create Draws', 'Create and schedule new lottery draws'),
  ('draws.manage', 'Manage Draws', 'Update draw configurations, status, and number rules'),
  ('draws.execute', 'Execute Draws', 'Close sales, draw numbers, and trigger winning selection'),
  ('tickets.view', 'View Tickets', 'View purchased tickets and order histories'),
  ('tickets.purchase', 'Purchase Tickets', 'Purchase lottery tickets using wallet balance'),
  ('results.view', 'View Results', 'View published draw winning numbers and statistics'),
  ('results.publish', 'Publish Results', 'Publish and seal official draw results'),
  ('winners.view', 'View Winners', 'View winner listings and calculated prizes'),
  ('winners.process', 'Process Winners', 'Execute winner payouts and credit winnings via ledger'),
  ('settings.view', 'View Settings', 'View platform settings, configurations, and payment methods'),
  ('settings.manage', 'Manage Settings', 'Update payment methods, fee schedules, and feature flags'),
  ('audit.view', 'View Audit Logs', 'View immutable system audit logs and history'),
  ('reports.view', 'View Reports', 'View financial reconciliation reports and analytics')
ON CONFLICT (code) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description;

-- 7. Deterministic Role-Permission Association
-- SUPER_ADMIN: Receives all permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.code = 'SUPER_ADMIN'
ON CONFLICT DO NOTHING;

-- ADMIN: General platform administration
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r, permissions p
WHERE r.code = 'ADMIN'
  AND p.code IN (
    'users.view', 'users.manage', 'users.block', 'kyc.view', 'kyc.review',
    'deposits.view', 'withdrawals.view', 'wallet.view',
    'draws.view', 'draws.create', 'draws.manage', 'tickets.view',
    'results.view', 'winners.view', 'settings.view', 'audit.view', 'reports.view'
  )
ON CONFLICT DO NOTHING;

-- FINANCE_ADMIN: Financial and settlement operations
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r, permissions p
WHERE r.code = 'FINANCE_ADMIN'
  AND p.code IN (
    'deposits.view', 'deposits.approve', 'deposits.reject',
    'withdrawals.view', 'withdrawals.approve', 'withdrawals.reject',
    'wallet.view', 'wallet.adjust', 'reports.view', 'audit.view',
    'settings.view', 'settings.manage'
  )
ON CONFLICT DO NOTHING;

-- DRAW_MANAGER: Lottery operations and draw management
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r, permissions p
WHERE r.code = 'DRAW_MANAGER'
  AND p.code IN (
    'draws.view', 'draws.create', 'draws.manage', 'draws.execute',
    'tickets.view', 'results.view', 'results.publish', 'winners.view', 'winners.process'
  )
ON CONFLICT DO NOTHING;

-- SUPPORT: Customer care and document verification
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r, permissions p
WHERE r.code = 'SUPPORT'
  AND p.code IN (
    'users.view', 'kyc.view', 'kyc.review', 'tickets.view', 'deposits.view', 'withdrawals.view'
  )
ON CONFLICT DO NOTHING;

-- AGENT: Affiliate agent functions
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r, permissions p
WHERE r.code = 'AGENT'
  AND p.code IN (
    'wallet.transfer', 'tickets.purchase', 'draws.view', 'tickets.view', 'results.view'
  )
ON CONFLICT DO NOTHING;

-- USER: Standard lottery player
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r, permissions p
WHERE r.code = 'USER'
  AND p.code IN (
    'tickets.purchase', 'wallet.transfer', 'draws.view', 'tickets.view', 'results.view'
  )
ON CONFLICT DO NOTHING;
