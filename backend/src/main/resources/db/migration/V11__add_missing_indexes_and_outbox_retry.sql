CREATE INDEX IF NOT EXISTS idx_transactions_source_wallet ON transactions (source_wallet_id);
CREATE INDEX IF NOT EXISTS idx_transactions_target_wallet ON transactions (target_wallet_id, created_at);

ALTER TABLE outbox_events ADD COLUMN retry_count INT DEFAULT 0 NOT NULL;
