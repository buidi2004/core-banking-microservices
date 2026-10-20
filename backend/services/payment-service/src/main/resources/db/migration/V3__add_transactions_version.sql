-- Add version column to transactions table for optimistic locking
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS version BIGINT NOT NULL DEFAULT 0;

