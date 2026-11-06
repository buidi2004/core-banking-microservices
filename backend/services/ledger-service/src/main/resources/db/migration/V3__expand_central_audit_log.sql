ALTER TABLE audit_logs
    ADD COLUMN IF NOT EXISTS service_name VARCHAR(80) NOT NULL DEFAULT 'ledger-service',
    ADD COLUMN IF NOT EXISTS actor_role VARCHAR(80),
    ADD COLUMN IF NOT EXISTS branch_id VARCHAR(80),
    ADD COLUMN IF NOT EXISTS correlation_id VARCHAR(120),
    ADD COLUMN IF NOT EXISTS client_ip VARCHAR(64),
    ADD COLUMN IF NOT EXISTS device_id VARCHAR(160),
    ADD COLUMN IF NOT EXISTS reason TEXT;

CREATE INDEX IF NOT EXISTS idx_audit_logs_actor ON audit_logs(performed_by, performed_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_branch ON audit_logs(branch_id, performed_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_correlation ON audit_logs(correlation_id);
