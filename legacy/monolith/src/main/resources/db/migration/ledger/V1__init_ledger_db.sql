-- ============================================================================
-- LEDGER SERVICE - V1__init_ledger_db.sql
-- Database: ewallet_ledger_db
-- Mô tả: Khởi tạo schema sổ kế toán kép, append-only (chỉ INSERT/SELECT).
-- ============================================================================

-- Bảng ledger_accounts: tài khoản kế toán (tài sản, nguồn vốn, thu nhập, chi phí)
CREATE TABLE IF NOT EXISTS ledger_accounts (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code            VARCHAR(20) UNIQUE NOT NULL,          -- Mã tài khoản (VD: 1111, 3111)
    name            VARCHAR(255) NOT NULL,
    type            VARCHAR(20) NOT NULL,                 -- 'ASSET' | 'LIABILITY' | 'EQUITY' | 'REVENUE' | 'EXPENSE'
    parent_id       UUID REFERENCES ledger_accounts(id) ON DELETE SET NULL,
    balance         BIGINT NOT NULL DEFAULT 0,             -- Đơn vị tiểu đơn vị (vND/satoshi)
    currency        VARCHAR(3) NOT NULL DEFAULT 'VND',
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    description     TEXT,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_ledger_accounts_code ON ledger_accounts(code);
CREATE INDEX idx_ledger_accounts_type ON ledger_accounts(type, is_active);
CREATE INDEX idx_ledger_accounts_parent ON ledger_accounts(parent_id);

-- Bảng journal_entries: chứng từ ghi sổ (tổng hợp các dòng debit/credit)
CREATE TABLE IF NOT EXISTS journal_entries (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id      VARCHAR(36) NOT NULL,              -- Logical ID từ Payment Service
    entry_number        BIGSERIAL NOT NULL,
    entry_date          DATE NOT NULL DEFAULT CURRENT_DATE,
    description         TEXT NOT NULL,
    reference_number    VARCHAR(100),                      -- Số hiệu chứng từ gốc
    status              VARCHAR(20) NOT NULL DEFAULT 'POSTED',  -- 'DRAFT' | 'POSTED' | 'REVERSED'
    posted_by           VARCHAR(36),
    posted_at           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reversed_at         TIMESTAMP,
    reversed_reason     TEXT,
    metadata_json       JSONB DEFAULT '{}',
    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX idx_journal_entries_transaction_id ON journal_entries(transaction_id, entry_number);
CREATE INDEX idx_journal_entries_entry_date ON journal_entries(entry_date DESC);
CREATE INDEX idx_journal_entries_status ON journal_entries(status);

-- Bảng ledger_postings: dòng bút toán Nợ/Có (mỗi giao dịch >= 2 dòng)
CREATE TABLE IF NOT EXISTS ledger_postings (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    journal_entry_id    UUID NOT NULL REFERENCES ledger_accounts(id),
    account_id          UUID NOT NULL REFERENCES ledger_accounts(id),
    side                VARCHAR(10) NOT NULL,              -- 'DEBIT' | 'CREDIT'
    amount              BIGINT NOT NULL,                    -- Đơn vị tiểu đơn vị
    currency            VARCHAR(3) NOT NULL DEFAULT 'VND',
    description         TEXT,
    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (amount > 0),
    CHECK (side IN ('DEBIT', 'CREDIT'))
);

CREATE INDEX idx_ledger_postings_journal_entry ON ledger_postings(journal_entry_id);
CREATE INDEX idx_ledger_postings_account ON ledger_postings(account_id);
CREATE INDEX idx_ledger_postings_transaction ON ledger_postings(journal_entry_id, account_id);

-- Bảng audit_logs: nhật ký kiểm toán (bất biến, không thể sửa/xóa)
CREATE TABLE IF NOT EXISTS audit_logs (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type          VARCHAR(50) NOT NULL,              -- 'JOURNAL_CREATED' | 'JOURNAL_POSTED' | 'JOURNAL_REVERSED'
    entity_type         VARCHAR(50) NOT NULL,              -- 'JOURNAL_ENTRY' | 'LEDGER_ACCOUNT'
    entity_id           VARCHAR(36) NOT NULL,
    action              VARCHAR(20) NOT NULL,              -- 'INSERT' | 'UPDATE' | 'DELETE'
    performed_by        VARCHAR(36),                       -- User ID thực hiện
    performed_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    old_values_json     JSONB,
    new_values_json     JSONB,
    ip_address          VARCHAR(45),
    user_agent          VARCHAR(512),
    reason              TEXT
);

CREATE INDEX idx_audit_logs_entity ON audit_logs(entity_type, entity_id);
CREATE INDEX idx_audit_logs_performed_at ON audit_logs(performed_at DESC);
CREATE INDEX idx_audit_logs_event_type ON audit_logs(event_type);

-- Trigger: Tự động cập nhật balance của ledger_accounts khi có posting mới
CREATE OR REPLACE FUNCTION recalculate_account_balance()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.side = 'DEBIT' THEN
        UPDATE ledger_accounts
        SET balance = balance + NEW.amount
        WHERE id = NEW.account_id;
    ELSIF NEW.side = 'CREDIT' THEN
        UPDATE ledger_accounts
        SET balance = balance - NEW.amount
        WHERE id = NEW.account_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_recalculate_account_balance
    AFTER INSERT ON ledger_postings
    FOR EACH ROW EXECUTE FUNCTION recalculate_account_balance();

-- Trigger: Cập nhật updated_at cho ledger_accounts
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'set_ledger_accounts_updated_at') THEN
        CREATE TRIGGER set_ledger_accounts_updated_at
            BEFORE UPDATE ON ledger_accounts
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
END
$$;
