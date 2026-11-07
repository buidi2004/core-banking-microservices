-- ============================================================================
-- LEDGER SERVICE - V4__add_eod_batches.sql
-- Database: ewallet_ledger_db
-- Mô tả: Thêm bảng lưu vết lịch sử các phiên khóa sổ kế toán cuối ngày (EOD/COB)
-- ============================================================================

CREATE TABLE IF NOT EXISTS eod_batches (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id            VARCHAR(64) UNIQUE NOT NULL,
    value_date          DATE NOT NULL,
    next_value_date     DATE NOT NULL,
    total_debit         NUMERIC(19,2) NOT NULL,
    total_credit        NUMERIC(19,2) NOT NULL,
    delta               NUMERIC(19,2) NOT NULL DEFAULT 0,
    is_balanced         BOOLEAN NOT NULL,
    total_entries       BIGINT NOT NULL,
    total_postings      BIGINT NOT NULL,
    checksum_passed     BOOLEAN NOT NULL DEFAULT TRUE,
    corrupted_accounts  INT NOT NULL DEFAULT 0,
    maker_checker_pending INT NOT NULL DEFAULT 0,
    outbox_pending      INT NOT NULL DEFAULT 0,
    status              VARCHAR(30) NOT NULL,
    executed_by         VARCHAR(64) NOT NULL,
    notes               TEXT,
    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_eod_batches_value_date ON eod_batches(value_date DESC);
CREATE INDEX IF NOT EXISTS idx_eod_batches_status ON eod_batches(status);
