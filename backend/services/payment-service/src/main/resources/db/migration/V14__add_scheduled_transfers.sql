-- V14__add_scheduled_transfers.sql
-- Quản lý chuyển tiền đặt lịch và định kỳ tự động (Recurring & Scheduled Transfers)

CREATE TABLE IF NOT EXISTS scheduled_transfers (
    id VARCHAR(36) PRIMARY KEY,
    source_user_id VARCHAR(36) NOT NULL,
    target_user_id VARCHAR(36) NOT NULL,
    target_phone_number VARCHAR(20),
    target_customer_name VARCHAR(100),
    amount BIGINT NOT NULL,
    currency VARCHAR(10) NOT NULL DEFAULT 'VND',
    note VARCHAR(255),
    frequency VARCHAR(20) NOT NULL DEFAULT 'ONCE', -- ONCE, DAILY, WEEKLY, MONTHLY
    day_of_month INT, -- 1..31
    next_execution_at TIMESTAMP WITH TIME ZONE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE', -- ACTIVE, COMPLETED, CANCELLED, FAILED
    last_executed_at TIMESTAMP WITH TIME ZONE,
    last_transaction_id VARCHAR(36),
    failure_reason VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_sched_next_exec ON scheduled_transfers (status, next_execution_at);
CREATE INDEX IF NOT EXISTS idx_sched_source_user ON scheduled_transfers (source_user_id);

