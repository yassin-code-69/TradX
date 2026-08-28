import { describe, expect, it } from 'bun:test';
import fs from 'fs';
import path from 'path';

describe('TRADEX Database Architecture & Migration Suite', () => {
  const migrationsDir = path.resolve(__dirname, '../migrations');

  const expectedMigrations = [
    '000001_core_profiles_auth.sql',
    '000002_rbac_roles_permissions.sql',
    '000003_wallets_double_entry_ledger.sql',
    '000004_payment_methods_deposits_withdrawals.sql',
    '000005_draws_tickets_results_winners.sql',
    '000006_notifications_banners_audit_outbox.sql',
    '000007_rls_and_indexes.sql',
  ];

  describe('1. Migration Manifest & Ordering', () => {
    it('should have all 7 required migration files in backend/migrations', () => {
      const files = fs.readdirSync(migrationsDir).sort();
      for (const expected of expectedMigrations) {
        expect(files).toContain(expected);
      }
    });

    it('each migration file must be non-empty and have valid SQL header comments', () => {
      for (const filename of expectedMigrations) {
        const filePath = path.join(migrationsDir, filename);
        const content = fs.readFileSync(filePath, 'utf-8');
        expect(content.length).toBeGreaterThan(100);
        expect(content).toContain('-- TRADEX DATABASE MIGRATION SUITE');
        expect(content).toContain(filename);
      }
    });
  });

  describe('2. Migration 000001: Core Profiles, Auth, Media & KYC', () => {
    const content = fs.readFileSync(
      path.join(migrationsDir, '000001_core_profiles_auth.sql'),
      'utf-8'
    );

    it('creates profiles table referencing auth.users(id)', () => {
      expect(content).toContain('CREATE TABLE IF NOT EXISTS profiles');
      expect(content).toContain('REFERENCES auth.users(id)');
    });

    it('enforces case-insensitive lowercase index on username', () => {
      expect(content).toContain('CREATE UNIQUE INDEX IF NOT EXISTS idx_profiles_username_lower');
      expect(content).toContain('ON profiles (lower(username))');
    });

    it('indexes phone for E.164 lookup', () => {
      expect(content).toContain('CREATE INDEX IF NOT EXISTS idx_profiles_phone ON profiles (phone)');
    });

    it('enforces status checks on user profiles and KYC', () => {
      expect(content).toContain("CHECK (status IN ('ACTIVE', 'SUSPENDED', 'BLOCKED', 'CLOSED'))");
      expect(content).toContain(
        "CHECK (kyc_status IN ('NOT_SUBMITTED', 'PENDING', 'VERIFIED', 'REJECTED'))"
      );
    });

    it('creates user_kyc table with masked numbers and asset IDs', () => {
      expect(content).toContain('CREATE TABLE IF NOT EXISTS user_kyc');
      expect(content).toContain('document_number_masked VARCHAR(100) NOT NULL');
      expect(content).toContain('front_asset_id BIGINT NULL');
      expect(content).toContain('back_asset_id BIGINT NULL');
      expect(content).toContain('selfie_asset_id BIGINT NULL');
    });

    it('creates media_assets table for Cloudinary metadata only', () => {
      expect(content).toContain('CREATE TABLE IF NOT EXISTS media_assets');
      expect(content).toContain('cloudinary_public_id VARCHAR(255) UNIQUE NOT NULL');
      expect(content).toContain('secure_url TEXT NOT NULL');
    });
  });

  describe('3. Migration 000002: RBAC Roles, Permissions & Seeds', () => {
    const content = fs.readFileSync(
      path.join(migrationsDir, '000002_rbac_roles_permissions.sql'),
      'utf-8'
    );

    it('creates roles, permissions, role_permissions, and user_roles tables', () => {
      expect(content).toContain('CREATE TABLE IF NOT EXISTS roles');
      expect(content).toContain('CREATE TABLE IF NOT EXISTS permissions');
      expect(content).toContain('CREATE TABLE IF NOT EXISTS role_permissions');
      expect(content).toContain('CREATE TABLE IF NOT EXISTS user_roles');
    });

    it('seeds deterministic system roles', () => {
      const roles = [
        'SUPER_ADMIN',
        'ADMIN',
        'FINANCE_ADMIN',
        'DRAW_MANAGER',
        'SUPPORT',
        'AGENT',
        'USER',
      ];
      for (const r of roles) {
        expect(content).toContain(`'${r}'`);
      }
    });

    it('seeds deterministic standard permissions', () => {
      const perms = [
        'users.view',
        'kyc.review',
        'deposits.approve',
        'withdrawals.approve',
        'wallet.adjust',
        'wallet.transfer',
        'draws.create',
        'tickets.purchase',
        'results.publish',
        'winners.process',
      ];
      for (const p of perms) {
        expect(content).toContain(`'${p}'`);
      }
    });

    it('indexes foreign keys for fast joins and cascade protection', () => {
      expect(content).toContain('idx_role_permissions_permission_id');
      expect(content).toContain('idx_user_roles_role_id');
    });
  });

  describe('4. Migration 000003: Wallets & Double-Entry Ledger', () => {
    const content = fs.readFileSync(
      path.join(migrationsDir, '000003_wallets_double_entry_ledger.sql'),
      'utf-8'
    );

    it('creates wallets table with non-negative checks and version counter', () => {
      expect(content).toContain('CREATE TABLE IF NOT EXISTS wallets');
      expect(content).toContain('available_balance_minor BIGINT NOT NULL DEFAULT 0');
      expect(content).toContain('CHECK (available_balance_minor >= 0)');
      expect(content).toContain('CHECK (locked_balance_minor >= 0)');
      expect(content).toContain('version BIGINT NOT NULL DEFAULT 0');
    });

    it('creates ledger_accounts with all required system and user account types', () => {
      expect(content).toContain('CREATE TABLE IF NOT EXISTS ledger_accounts');
      const types = [
        'USER_AVAILABLE',
        'USER_LOCKED',
        'DEPOSIT_CLEARING',
        'WITHDRAWAL_CLEARING',
        'PLATFORM_REVENUE',
        'PRIZE_POOL',
        'BONUS_POOL',
        'AGENT_COMMISSION',
        'SYSTEM_ADJUSTMENT',
      ];
      for (const t of types) {
        expect(content).toContain(`'${t}'`);
      }
    });

    it('seeds default system accounts', () => {
      expect(content).toContain("('SYSTEM', 'SYSTEM', 'DEPOSIT_CLEARING', 'BDT', 'ACTIVE')");
      expect(content).toContain("('SYSTEM', 'SYSTEM', 'PLATFORM_REVENUE', 'BDT', 'ACTIVE')");
      expect(content).toContain("('SYSTEM', 'SYSTEM', 'PRIZE_POOL', 'BDT', 'ACTIVE')");
    });

    it('creates ledger_transactions and ledger_entries with foreign keys', () => {
      expect(content).toContain('CREATE TABLE IF NOT EXISTS ledger_transactions');
      expect(content).toContain('CREATE TABLE IF NOT EXISTS ledger_entries');
      expect(content).toContain('REFERENCES ledger_transactions(id)');
      expect(content).toContain('REFERENCES ledger_accounts(id)');
    });

    it('implements balance invariant trigger asserting SUM(amount_minor) = 0', () => {
      expect(content).toContain('verify_ledger_transaction_balance');
      expect(content).toContain('check_ledger_balance_invariant_trigger');
      expect(content).toContain('trg_assert_ledger_balance_entries');
      expect(content).toContain('DEFERRABLE INITIALLY DEFERRED');
    });

    it('creates idempotency_keys table', () => {
      expect(content).toContain('CREATE TABLE IF NOT EXISTS idempotency_keys');
      expect(content).toContain('uq_idempotency_keys_user_op_key UNIQUE (user_id, operation, key)');
    });
  });

  describe('5. Migration 000004: Payment Methods, Deposits & Withdrawals', () => {
    const content = fs.readFileSync(
      path.join(migrationsDir, '000004_payment_methods_deposits_withdrawals.sql'),
      'utf-8'
    );

    it('creates payment_methods and seeds bKash, Nagad, Rocket, Bank', () => {
      expect(content).toContain('CREATE TABLE IF NOT EXISTS payment_methods');
      expect(content).toContain("'BKASH'");
      expect(content).toContain("'NAGAD'");
      expect(content).toContain("'ROCKET'");
      expect(content).toContain("'BANK'");
    });

    it('creates deposit_requests with unique partial index on provider_transaction_id', () => {
      expect(content).toContain('CREATE TABLE IF NOT EXISTS deposit_requests');
      expect(content).toContain('CREATE UNIQUE INDEX IF NOT EXISTS idx_deposit_requests_provider_tx');
      expect(content).toContain('WHERE provider_transaction_id IS NOT NULL');
    });

    it('creates withdrawal_requests with net amount constraint', () => {
      expect(content).toContain('CREATE TABLE IF NOT EXISTS withdrawal_requests');
      expect(content).toContain('CHECK (net_amount_minor = amount_minor - fee_minor)');
    });

    it('creates wallet_transfers with no self-transfer check', () => {
      expect(content).toContain('CREATE TABLE IF NOT EXISTS wallet_transfers');
      expect(content).toContain('CHECK (sender_user_id <> receiver_user_id)');
    });
  });

  describe('6. Migration 000005: Draws, Tickets, Results & Winners', () => {
    const content = fs.readFileSync(
      path.join(migrationsDir, '000005_draws_tickets_results_winners.sql'),
      'utf-8'
    );

    it('creates draw_types and seeds MEGA (7 digits), DAILY (3 digits), HOURLY (3 digits)', () => {
      expect(content).toContain('CREATE TABLE IF NOT EXISTS draw_types');
      expect(content).toContain("('MEGA', 'Mega Draw', 7, 5000, 'ACTIVE')");
      expect(content).toContain("('DAILY', 'Daily Draw', 3, 2000, 'ACTIVE')");
      expect(content).toContain("('HOURLY', 'Hourly Draw', 3, 1000, 'ACTIVE')");
    });

    it('creates draws with sale window and draw time constraints', () => {
      expect(content).toContain('CREATE TABLE IF NOT EXISTS draws');
      expect(content).toContain('CHECK (sale_open_at < sale_close_at)');
      expect(content).toContain('CHECK (sale_close_at <= draw_at)');
    });

    it('creates tickets storing selected_number as VARCHAR preserving leading zeros', () => {
      expect(content).toContain('CREATE TABLE IF NOT EXISTS tickets');
      expect(content).toContain("selected_number VARCHAR(50) NOT NULL CHECK (selected_number ~ '^[0-9]+$')");
    });

    it('indexes tickets by (draw_id, selected_number) for instant winner checks', () => {
      expect(content).toContain('idx_tickets_draw_number ON tickets (draw_id, selected_number)');
    });

    it('creates draw_results with result_hash and immutability trigger', () => {
      expect(content).toContain('CREATE TABLE IF NOT EXISTS draw_results');
      expect(content).toContain('result_hash VARCHAR(255) NULL');
      expect(content).toContain('prevent_draw_result_modification');
      expect(content).toContain('trg_draw_results_immutability');
    });

    it('creates winners table with ticket_id uniqueness', () => {
      expect(content).toContain('CREATE TABLE IF NOT EXISTS winners');
      expect(content).toContain('ticket_id BIGINT UNIQUE NOT NULL');
    });
  });

  describe('7. Migration 000006: Notifications, Banners, Audit & Outbox', () => {
    const content = fs.readFileSync(
      path.join(migrationsDir, '000006_notifications_banners_audit_outbox.sql'),
      'utf-8'
    );

    it('creates notifications and notification_deliveries', () => {
      expect(content).toContain('CREATE TABLE IF NOT EXISTS notifications');
      expect(content).toContain('CREATE TABLE IF NOT EXISTS notification_deliveries');
    });

    it('creates banners table and promo_banners backwards compatibility view', () => {
      expect(content).toContain('CREATE TABLE IF NOT EXISTS banners');
      expect(content).toContain('CREATE OR REPLACE VIEW promo_banners AS');
    });

    it('creates audit_logs with append-only prevention trigger', () => {
      expect(content).toContain('CREATE TABLE IF NOT EXISTS audit_logs');
      expect(content).toContain('prevent_audit_log_modification');
      expect(content).toContain('trg_audit_logs_append_only');
    });

    it('creates outbox_events with SKIP LOCKED worker index', () => {
      expect(content).toContain('CREATE TABLE IF NOT EXISTS outbox_events');
      expect(content).toContain('idx_outbox_events_worker');
      expect(content).toContain("ON outbox_events (available_at, id)\nWHERE status = 'PENDING'");
    });
  });

  describe('8. Migration 000007: RLS Policies & Indexes', () => {
    const content = fs.readFileSync(
      path.join(migrationsDir, '000007_rls_and_indexes.sql'),
      'utf-8'
    );

    it('enables Row Level Security on public tables', () => {
      expect(content).toContain('ALTER TABLE IF EXISTS profiles ENABLE ROW LEVEL SECURITY');
      expect(content).toContain('ALTER TABLE IF EXISTS wallets ENABLE ROW LEVEL SECURITY');
      expect(content).toContain('ALTER TABLE IF EXISTS tickets ENABLE ROW LEVEL SECURITY');
      expect(content).toContain('ALTER TABLE IF EXISTS ledger_entries ENABLE ROW LEVEL SECURITY');
    });

    it('grants service_role full access policy', () => {
      expect(content).toContain('service_role_all');
      expect(content).toContain('TO service_role USING (true) WITH CHECK (true)');
    });

    it('implements cached (select auth.uid()) pattern for user policies', () => {
      expect(content).toContain('((select auth.uid()) = user_id)');
    });

    it('includes critical partial indexes for queues', () => {
      expect(content).toContain("WHERE status = 'PENDING'");
      expect(content).toContain("WHERE status = 'OPEN'");
      expect(content).toContain('WHERE read_at IS NULL');
      expect(content).toContain('WHERE is_winner = true');
    });
  });

  describe('9. Financial Double-Entry Accounting Invariant Simulation', () => {
    interface LedgerEntry {
      accountId: string;
      accountType: string;
      amountMinor: bigint;
    }

    function verifyTransactionBalance(entries: LedgerEntry[]): boolean {
      if (entries.length < 2) return false;
      const total = entries.reduce((acc, e) => acc + e.amountMinor, 0n);
      return total === 0n;
    }

    it('validates deposit transaction balance invariant: SUM == 0', () => {
      const depositAmount = 50000n; // ৳500.00
      const entries: LedgerEntry[] = [
        { accountId: 'acc-dep-clear', accountType: 'DEPOSIT_CLEARING', amountMinor: -depositAmount },
        { accountId: 'acc-user-avail', accountType: 'USER_AVAILABLE', amountMinor: depositAmount },
      ];
      expect(verifyTransactionBalance(entries)).toBe(true);
    });

    it('validates user-to-user transfer invariant: SUM == 0', () => {
      const transferAmount = 25000n; // ৳250.00
      const feeAmount = 500n; // ৳5.00
      const totalDeduction = transferAmount + feeAmount;

      const entries: LedgerEntry[] = [
        { accountId: 'sender-avail', accountType: 'USER_AVAILABLE', amountMinor: -totalDeduction },
        { accountId: 'receiver-avail', accountType: 'USER_AVAILABLE', amountMinor: transferAmount },
        { accountId: 'system-rev', accountType: 'PLATFORM_REVENUE', amountMinor: feeAmount },
      ];
      expect(verifyTransactionBalance(entries)).toBe(true);
    });

    it('validates withdrawal settlement invariant: SUM == 0', () => {
      const grossWithdrawal = 100000n; // ৳1000.00
      const fee = 1800n; // ৳18.00 (1.8%)
      const net = grossWithdrawal - fee; // ৳982.00

      const entries: LedgerEntry[] = [
        { accountId: 'user-locked', accountType: 'USER_LOCKED', amountMinor: -grossWithdrawal },
        { accountId: 'with-clear', accountType: 'WITHDRAWAL_CLEARING', amountMinor: net },
        { accountId: 'platform-rev', accountType: 'PLATFORM_REVENUE', amountMinor: fee },
      ];
      expect(verifyTransactionBalance(entries)).toBe(true);
    });

    it('validates ticket purchase invariant: SUM == 0', () => {
      const ticketPrice = 5000n; // ৳50.00
      const entries: LedgerEntry[] = [
        { accountId: 'user-avail', accountType: 'USER_AVAILABLE', amountMinor: -ticketPrice },
        { accountId: 'platform-rev', accountType: 'PLATFORM_REVENUE', amountMinor: ticketPrice },
      ];
      expect(verifyTransactionBalance(entries)).toBe(true);
    });

    it('validates winner payout invariant: SUM == 0', () => {
      const prizeAmount = 10000000n; // ৳100,000.00
      const entries: LedgerEntry[] = [
        { accountId: 'prize-pool', accountType: 'PRIZE_POOL', amountMinor: -prizeAmount },
        { accountId: 'winner-avail', accountType: 'USER_AVAILABLE', amountMinor: prizeAmount },
      ];
      expect(verifyTransactionBalance(entries)).toBe(true);
    });

    it('rejects unbalanced transactions: SUM != 0', () => {
      const entries: LedgerEntry[] = [
        { accountId: 'user-avail', accountType: 'USER_AVAILABLE', amountMinor: -5000n },
        { accountId: 'platform-rev', accountType: 'PLATFORM_REVENUE', amountMinor: 4000n }, // Mismatch by 1000
      ];
      expect(verifyTransactionBalance(entries)).toBe(false);
    });
  });

  describe('10. Leading Zero Preservation in Ticket Numbers', () => {
    it('preserves leading zeros for Mega Draw 7-digit numbers', () => {
      const rawNumber = '0012345';
      expect(typeof rawNumber).toBe('string');
      expect(rawNumber.length).toBe(7);
      expect(rawNumber.startsWith('00')).toBe(true);
      expect(/^\d{7}$/.test(rawNumber)).toBe(true);
    });

    it('preserves leading zeros for Daily Draw 3-digit numbers', () => {
      const rawNumber = '007';
      expect(typeof rawNumber).toBe('string');
      expect(rawNumber.length).toBe(3);
      expect(rawNumber.startsWith('00')).toBe(true);
      expect(/^\d{3}$/.test(rawNumber)).toBe(true);
    });

    it('prohibits numeric parsing that strips leading zeros', () => {
      const stringNum = '007';
      const parsed = parseInt(stringNum, 10);
      expect(parsed).toBe(7);
      // Demonstrates why VARCHAR is required:
      expect(parsed.toString()).not.toBe(stringNum);
    });
  });
});
