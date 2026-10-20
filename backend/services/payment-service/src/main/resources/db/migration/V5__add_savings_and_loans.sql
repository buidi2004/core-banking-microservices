-- ==============================================================================
-- MIGRATION V5: KHỞI TẠO BẢNG SỔ TIẾT KIỆM (SAVINGS) & VAY TIÊU DÙNG (QUICK LOANS)
-- Database: ewallet_payment_db
-- ==============================================================================

CREATE TABLE IF NOT EXISTS savings_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(36) NOT NULL,
    wallet_id VARCHAR(36) NOT NULL,
    account_number VARCHAR(50) UNIQUE NOT NULL,
    product_type VARCHAR(50) NOT NULL,
    product_name VARCHAR(100) NOT NULL,
    principal NUMERIC(19, 2) NOT NULL,
    interest_rate NUMERIC(5, 2) NOT NULL,
    term_months INT NOT NULL,
    expected_interest NUMERIC(19, 2) NOT NULL,
    accrued_interest NUMERIC(19, 2) DEFAULT 0,
    rollover_type VARCHAR(30) DEFAULT 'AUTO_ROLLOVER_ALL',
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    start_date DATE NOT NULL,
    maturity_date DATE NOT NULL,
    settled_date TIMESTAMP WITH TIME ZONE,
    settled_amount NUMERIC(19, 2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_savings_user ON savings_accounts(user_id);
CREATE INDEX IF NOT EXISTS idx_savings_status ON savings_accounts(status);

CREATE TABLE IF NOT EXISTS loan_contracts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(36) NOT NULL,
    wallet_id VARCHAR(36) NOT NULL,
    contract_number VARCHAR(50) UNIQUE NOT NULL,
    product_type VARCHAR(50) NOT NULL,
    product_name VARCHAR(100) NOT NULL,
    principal_amount NUMERIC(19, 2) NOT NULL,
    annual_interest_rate NUMERIC(5, 2) NOT NULL,
    term_months INT NOT NULL,
    total_interest NUMERIC(19, 2) NOT NULL,
    total_repayment NUMERIC(19, 2) NOT NULL,
    remaining_principal NUMERIC(19, 2) NOT NULL,
    monthly_payment NUMERIC(19, 2) NOT NULL,
    purpose VARCHAR(255),
    status VARCHAR(20) NOT NULL DEFAULT 'DISBURSED',
    disbursed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    first_due_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_loan_user ON loan_contracts(user_id);
CREATE INDEX IF NOT EXISTS idx_loan_status ON loan_contracts(status);

CREATE TABLE IF NOT EXISTS loan_schedule_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    loan_contract_id UUID NOT NULL REFERENCES loan_contracts(id) ON DELETE CASCADE,
    term_number INT NOT NULL,
    due_date DATE NOT NULL,
    principal_amount NUMERIC(19, 2) NOT NULL,
    interest_amount NUMERIC(19, 2) NOT NULL,
    total_amount NUMERIC(19, 2) NOT NULL,
    remaining_balance NUMERIC(19, 2) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'UPCOMING',
    paid_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_loan_schedule_contract ON loan_schedule_items(loan_contract_id);
CREATE INDEX IF NOT EXISTS idx_loan_schedule_due ON loan_schedule_items(due_date);

