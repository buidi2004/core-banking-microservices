-- ====================================================================
-- V7: Utility Bill Payment & Telco Topup Core Banking Tables
-- ====================================================================

CREATE TABLE IF NOT EXISTS bills (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36),
    bill_id VARCHAR(64) NOT NULL UNIQUE,
    service_type VARCHAR(30) NOT NULL,
    provider_code VARCHAR(50) NOT NULL,
    customer_code VARCHAR(50) NOT NULL,
    customer_name VARCHAR(100) NOT NULL,
    customer_address VARCHAR(255),
    period VARCHAR(30) NOT NULL,
    amount NUMERIC(19, 4) NOT NULL,
    fee NUMERIC(19, 4) NOT NULL DEFAULT 0,
    due_date DATE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'UNPAID',
    paid_at TIMESTAMP WITH TIME ZONE,
    paid_by_user_id VARCHAR(36),
    transaction_id VARCHAR(36),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_bills_customer ON bills(customer_code, status);
CREATE INDEX IF NOT EXISTS idx_bills_bill_id ON bills(bill_id);

CREATE TABLE IF NOT EXISTS telco_topups (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    telco_code VARCHAR(30) NOT NULL,
    topup_amount NUMERIC(19, 4) NOT NULL,
    discount_amount NUMERIC(19, 4) NOT NULL DEFAULT 0,
    net_amount NUMERIC(19, 4) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'SUCCESS',
    transaction_id VARCHAR(36),
    serial_number VARCHAR(64),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_telco_topups_user ON telco_topups(user_id);

