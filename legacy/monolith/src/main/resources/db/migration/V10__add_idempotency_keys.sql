ALTER TABLE journal_entries ADD COLUMN idempotency_key VARCHAR(255);
ALTER TABLE journal_entries ADD CONSTRAINT uk_journal_entries_idempotency UNIQUE (idempotency_key);

ALTER TABLE audit_logs ADD COLUMN idempotency_key VARCHAR(255);
ALTER TABLE audit_logs ADD CONSTRAINT uk_audit_logs_idempotency UNIQUE (idempotency_key);
