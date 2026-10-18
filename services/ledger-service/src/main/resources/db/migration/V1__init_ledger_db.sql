-- ============================================================================
-- LEDGER SERVICE - V1__init_ledger_db.sql
-- Database: ewallet_ledger_db
-- Mô tả: Khởi tạo schema sổ kế toán kép (double-entry), Append-Only
--        (chỉ INSERT/SELECT - cấm UPDATE/DELETE ở cấp quyền DB user).
-- Idempotency: journal_entries.reference_number (mỗi event chỉ ghi 1 lần).
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Bảng ledger_accounts: tài khoản kế toán (tài sản, nguồn vốn, doanh thu, chi phí)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ledger_accounts (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code        VARCHAR(20) UNIQUE NOT NULL,           -- Mã tài khoản (VD: 'BANK_SETTLEMENT', 'W:a1b2c3d4')
    name        VARCHAR(255) NOT NULL,                 -- Tên đầy đủ (VD: 'CUSTOMER_DEPOSITS:<walletId>')
    type        VARCHAR(20) NOT NULL                   -- 'ASSET' | 'LIABILITY' | 'EQUITY' | 'REVENUE' | 'EXPENSE'
                    CHECK (type IN ('ASSET', 'LIABILITY', 'EQUITY', 'REVENUE', 'EXPENSE')),
    parent_id   UUID REFERENCES ledger_accounts(id) ON DELETE SET NULL,
    balance     NUMERIC(19,2) NOT NULL DEFAULT 0,      -- Số dư do trigger duy trì (ASSET/EXPENSE: Debit(+); còn lại: Credit(+))
    currency    VARCHAR(3) NOT NULL DEFAULT 'VND'      -- Số dư lịch sử được bảo toàn theo công thức chuẩn kế toán
                    CHECK (currency ~ '^[A-Z]{3}$'),
    is_active   BOOLEAN NOT NULL DEFAULT TRUE,
    description TEXT,
    created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_ledger_accounts_code ON ledger_accounts(code);
CREATE INDEX IF NOT EXISTS idx_ledger_accounts_type ON ledger_accounts(type, is_active);
CREATE INDEX IF NOT EXISTS idx_ledger_accounts_name ON ledger_accounts(name);

-- ---------------------------------------------------------------------------
-- Bảng journal_entries: chứng từ ghi sổ (header - tổng hợp các dòng Nợ/Có)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS journal_entries (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id   VARCHAR(36) NOT NULL,                  -- Logical ID từ Payment Service (không FK)
    entry_number     BIGSERIAL NOT NULL,                    -- Số chứng từ tăng dần
    entry_date       DATE NOT NULL DEFAULT CURRENT_DATE,
    description      TEXT NOT NULL,
    reference_number VARCHAR(64),                           -- eventId (idempotency của consumer)
    status           VARCHAR(20) NOT NULL DEFAULT 'POSTED'  -- 'POSTED' | 'REVERSAL' (bút toán bù, append-only)
                        CHECK (status IN ('POSTED', 'REVERSAL')),
    reversal_of      UUID REFERENCES journal_entries(id),   -- Chứng từ gốc mà chứng từ bù này hoàn lại
    metadata_json    JSONB DEFAULT '{}',
    posted_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_journal_entries_transaction_id ON journal_entries(transaction_id);
CREATE INDEX IF NOT EXISTS idx_journal_entries_entry_date ON journal_entries(entry_date DESC);
CREATE INDEX IF NOT EXISTS idx_journal_entries_status ON journal_entries(status);

-- Idempotency cấp DB: mỗi eventId chỉ được ghi 1 chứng từ
CREATE UNIQUE INDEX IF NOT EXISTS uq_journal_entries_reference
    ON journal_entries(reference_number) WHERE reference_number IS NOT NULL;
-- 1 giao dịch chỉ có 1 chứng từ gốc trạng thái POSTED (chứng từ bù dùng status REVERSAL)
CREATE UNIQUE INDEX IF NOT EXISTS uq_journal_entries_transaction_posted
    ON journal_entries(transaction_id) WHERE status = 'POSTED';

-- ---------------------------------------------------------------------------
-- Bảng ledger_postings: dòng bút toán Nợ/Có (mỗi chứng từ >= 2 dòng, Debit = Credit)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ledger_postings (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    journal_entry_id UUID NOT NULL REFERENCES journal_entries(id),
    account_id       UUID NOT NULL REFERENCES ledger_accounts(id),
    side             VARCHAR(10) NOT NULL,                  -- 'DEBIT' | 'CREDIT'
                        CHECK (side IN ('DEBIT', 'CREDIT')),
    amount           NUMERIC(19,2) NOT NULL                 -- Số tiền dương (bên Nợ/Có quyết định chiều)
                        CHECK (amount > 0),
    currency         VARCHAR(3) NOT NULL DEFAULT 'VND'
                        CHECK (currency ~ '^[A-Z]{3}$'),
    description      TEXT,
    created_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_ledger_postings_journal_entry ON ledger_postings(journal_entry_id);
CREATE INDEX IF NOT EXISTS idx_ledger_postings_account ON ledger_postings(account_id, side);

-- ---------------------------------------------------------------------------
-- Bảng audit_logs: nhật ký kiểm toán (bất biến, chỉ INSERT/SELECT)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS audit_logs (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type      VARCHAR(50) NOT NULL,                   -- 'JOURNAL_POSTED' | 'JOURNAL_REVERSAL'
    entity_type     VARCHAR(50) NOT NULL,                   -- 'JOURNAL_ENTRY' | 'LEDGER_ACCOUNT'
    entity_id       VARCHAR(36) NOT NULL,
    description     TEXT,
    performed_by    VARCHAR(36) DEFAULT 'LEDGER_SERVICE',
    performed_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    detail_json     JSONB DEFAULT '{}'
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_entity ON audit_logs(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_performed_at ON audit_logs(performed_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_event_type ON audit_logs(event_type);

-- ---------------------------------------------------------------------------
-- Trigger: duy trì số dư ledger_accounts khi INSERT posting mới.
-- Chạy SECURITY DEFINER (owner) để ledger_app_user (không có quyền UPDATE)
-- vẫn cập nhật được số dư mà không phá vỡ ràng buộc Append-Only.
-- Công thức chuẩn kế toán:
--   ASSET / EXPENSE : Debit(+), Credit(-)
--   LIABILITY / EQUITY / REVENUE : Credit(+), Debit(-)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION recalculate_account_balance()
RETURNS TRIGGER AS $$
DECLARE
    account_type VARCHAR;
BEGIN
    SELECT type INTO account_type FROM ledger_accounts WHERE id = NEW.account_id;
    IF account_type IS NULL THEN
        RAISE EXCEPTION 'Ledger account % not found', NEW.account_id;
    END IF;

    IF account_type IN ('ASSET', 'EXPENSE') THEN
        UPDATE ledger_accounts
        SET balance = balance + (CASE WHEN NEW.side = 'DEBIT' THEN NEW.amount ELSE -NEW.amount END)
        WHERE id = NEW.account_id;
    ELSE
        UPDATE ledger_accounts
        SET balance = balance + (CASE WHEN NEW.side = 'CREDIT' THEN NEW.amount ELSE -NEW.amount END)
        WHERE id = NEW.account_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_recalculate_account_balance ON ledger_postings;
CREATE TRIGGER trg_recalculate_account_balance
    AFTER INSERT ON ledger_postings
    FOR EACH ROW EXECUTE FUNCTION recalculate_account_balance();
