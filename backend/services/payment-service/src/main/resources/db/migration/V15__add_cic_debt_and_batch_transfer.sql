-- ==============================================================================
-- V15: CIC 5-Group Debt Classification, Cash in Transit (CIT), & Bill Subscriptions
-- Tuân thủ Thông tư 11/2021/TT-NHNN (CIC) & Vận hành Két Quỹ / Trích Nợ Tự Động
-- ==============================================================================

-- 1. Thêm các trường phân loại nợ CIC 5 nhóm vào hợp đồng vay (LoanContract)
ALTER TABLE loan_contracts ADD COLUMN IF NOT EXISTS cic_group INT DEFAULT 1;
ALTER TABLE loan_contracts ADD COLUMN IF NOT EXISTS cic_group_name VARCHAR(100) DEFAULT 'Nhóm 1 - Nợ đủ tiêu chuẩn';
ALTER TABLE loan_contracts ADD COLUMN IF NOT EXISTS overdue_days INT DEFAULT 0;
ALTER TABLE loan_contracts ADD COLUMN IF NOT EXISTS risk_provision_amount NUMERIC(19, 2) DEFAULT 0.00;

CREATE INDEX IF NOT EXISTS idx_loan_contracts_cic ON loan_contracts(cic_group);

-- 2. Bảng quản lý Lệnh điều chuyển tiền mặt két quỹ (Cash in Transit - CIT)
CREATE TABLE IF NOT EXISTS cash_in_transit_orders (
    id UUID PRIMARY KEY,
    order_code VARCHAR(50) NOT NULL UNIQUE,
    from_branch_id VARCHAR(50) NOT NULL,
    to_branch_id VARCHAR(50) NOT NULL,
    amount NUMERIC(19, 2) NOT NULL,
    currency VARCHAR(10) NOT NULL DEFAULT 'VND',
    transport_staff_name VARCHAR(100) NOT NULL,
    seal_number VARCHAR(100) NOT NULL,
    note VARCHAR(255),
    status VARCHAR(30) NOT NULL DEFAULT 'PENDING_APPROVAL',
    created_by VARCHAR(50) NOT NULL,
    approved_by VARCHAR(50),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    approved_at TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_cit_status ON cash_in_transit_orders(status);
CREATE INDEX IF NOT EXISTS idx_cit_branches ON cash_in_transit_orders(from_branch_id, to_branch_id);

-- 3. Bảng quản lý Ủy thác trích nợ tự động hóa đơn (Auto-Debit Bill Subscriptions)
CREATE TABLE IF NOT EXISTS bill_subscriptions (
    id UUID PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    wallet_id VARCHAR(36) NOT NULL,
    bill_type VARCHAR(50) NOT NULL,
    customer_code VARCHAR(100) NOT NULL,
    provider_code VARCHAR(50) NOT NULL,
    auto_debit_day INT NOT NULL DEFAULT 5,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    last_deducted_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_bill_sub_user ON bill_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_bill_sub_status_day ON bill_subscriptions(status, auto_debit_day);

