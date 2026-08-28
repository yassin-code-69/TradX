-- ============================================================================
-- TRADEX DATABASE MIGRATION SUITE
-- Migration: 000001_core_profiles_auth.sql
-- Description: Core Profiles, Auth Identity Reference, Media Assets, and User KYC
-- ============================================================================

-- 1. Required Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Supabase Auth already provides auth.users.


-- 2. Generic Reusable updated_at Trigger Function
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Media Assets Table
-- Authoritative metadata for media stored in external CDN (Cloudinary).
-- PostgreSQL stores metadata and URLs only; binaries are NEVER stored in the DB.
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

-- 4. Profiles Table
-- Direct 1-to-1 extension of Supabase Auth user identity
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

-- Case-insensitive lowercase unique index on username (normalized lookup)
CREATE UNIQUE INDEX IF NOT EXISTS idx_profiles_username_lower ON profiles (lower(username)) WHERE username IS NOT NULL;

-- Phone indexing (E.164 canonical format)
CREATE INDEX IF NOT EXISTS idx_profiles_phone ON profiles (phone) WHERE phone IS NOT NULL;

-- Email lowercase indexing
CREATE INDEX IF NOT EXISTS idx_profiles_email_lower ON profiles (lower(email)) WHERE email IS NOT NULL;

-- Referral and relationship indexing
CREATE INDEX IF NOT EXISTS idx_profiles_referred_by ON profiles (referred_by) WHERE referred_by IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_profiles_status ON profiles (status);
CREATE INDEX IF NOT EXISTS idx_profiles_public_id ON profiles (public_id);

-- Updated_at trigger
DROP TRIGGER IF EXISTS trg_profiles_updated_at ON profiles;
CREATE TRIGGER trg_profiles_updated_at
BEFORE UPDATE ON profiles
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

-- 5. User KYC Table
-- Detailed identity verification documents, status, and audit review fields
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

-- KYC Indexes
CREATE INDEX IF NOT EXISTS idx_user_kyc_user ON user_kyc (user_id);
CREATE INDEX IF NOT EXISTS idx_user_kyc_status ON user_kyc (status);
CREATE INDEX IF NOT EXISTS idx_user_kyc_reviewed_by ON user_kyc (reviewed_by);
CREATE INDEX IF NOT EXISTS idx_user_kyc_front_asset ON user_kyc (front_asset_id);
CREATE INDEX IF NOT EXISTS idx_user_kyc_back_asset ON user_kyc (back_asset_id);
CREATE INDEX IF NOT EXISTS idx_user_kyc_selfie_asset ON user_kyc (selfie_asset_id);
CREATE INDEX IF NOT EXISTS idx_user_kyc_pending ON user_kyc (submitted_at DESC) WHERE status = 'PENDING';

-- Updated_at trigger
DROP TRIGGER IF EXISTS trg_user_kyc_updated_at ON user_kyc;
CREATE TRIGGER trg_user_kyc_updated_at
BEFORE UPDATE ON user_kyc
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();
