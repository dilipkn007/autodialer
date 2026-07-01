-- Migration: Add login tracking columns to access_token for multi-use time-based tokens
-- Tokens are now valid for a time period (not one-time use)

ALTER TABLE access_token ADD COLUMN IF NOT EXISTS login_count INTEGER NOT NULL DEFAULT 0;
ALTER TABLE access_token ADD COLUMN IF NOT EXISTS last_login_at TIMESTAMPTZ;
