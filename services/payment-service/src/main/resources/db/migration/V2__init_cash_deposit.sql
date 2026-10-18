-- ==============================================================================
-- MIGRATION V2: KHỞI TẠO BẢNG QUẢN LÝ NẠP TIỀN QUẦY (CASH DEPOSIT & MAKER-CHECKER)
-- Database: ewallet_payment_db
-- ==============================================================================

CREATE TABLE IF NOT EXISTS cash_deposits (
    id VARCHAR(36) PRIMARY KEY,
    deposit_code VARCHAR(50) UNIQUE NOT NULL,
    account_number VARCHAR(50) NOT NULL,
    customer_name VARCHAR(100) NOT NULL,
    amount BIGINT NOT NULL CHECK (amount > 0),
    currency VARCHAR(10) NOT NULL DEFAULT 'VND',
    maker_id VARCHAR(36) NOT NULL,
    checker_id VARCHAR(36),
    branch_id VARCHAR(50) NOT NULL DEFAULT 'BR_Q1',
    status VARCHAR(30) NOT NULL DEFAULT 'PENDING_APPROVAL', -- PENDING_APPROVAL, APPROVED, REJECTED, COMPLETED
    idempotency_key VARCHAR(100) UNIQUE NOT NULL,
    rejection_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    approved_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT chk_maker_checker CHECK (
        status != 'APPROVED' AND status != 'COMPLETED' OR maker_id != checker_id
    )
);

CREATE INDEX IF NOT EXISTS idx_cash_deposits_maker ON cash_deposits(maker_id);
CREATE INDEX IF NOT EXISTS idx_cash_deposits_status ON cash_deposits(status);
CREATE INDEX IF NOT EXISTS idx_cash_deposits_branch ON cash_deposits(branch_id);

-- Cấu hình Hạn mức tự duyệt
CREATE TABLE IF NOT EXISTS deposit_limits (
    id SERIAL PRIMARY KEY,
    branch_id VARCHAR(50) UNIQUE NOT NULL,
    max_auto_approve_amount BIGINT NOT NULL DEFAULT 50000000, -- 50,000,000 VND
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO deposit_limits (branch_id, max_auto_approve_amount)
VALUES ('BR_Q1', 50000000), ('BR_HK', 50000000)
ON CONFLICT (branch_id) DO NOTHING;
