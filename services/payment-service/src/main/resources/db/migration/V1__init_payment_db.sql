-- ============================================================================
-- PAYMENT & TRANSACTION SERVICE - V1__init_payment_db.sql
-- Database: ewallet_payment_db
-- Bảng: transactions, money_requests, banks, bank_accounts, funding_sources, beneficiaries, outbox_events
-- Cắt bỏ hoàn toàn FK sang wallets & users table
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. BẢNG TRANSACTIONS (Giao dịch chuyển tiền, nạp, rút, thanh toán)
CREATE TABLE IF NOT EXISTS transactions (
    id VARCHAR(36) PRIMARY KEY,
    transaction_code VARCHAR(50) NOT NULL UNIQUE,
    source_wallet_id VARCHAR(36),           -- Logical ID, không FK vật lý
    target_wallet_id VARCHAR(36),           -- Logical ID, không FK vật lý
    sender_id VARCHAR(36),                  -- Logical User ID
    receiver_id VARCHAR(36),                -- Logical User ID
    amount BIGINT NOT NULL CHECK (amount > 0),
    fee BIGINT NOT NULL DEFAULT 0,
    currency VARCHAR(10) NOT NULL DEFAULT 'VND',
    type VARCHAR(30) NOT NULL,              -- TRANSFER, TOPUP, WITHDRAW, PAYMENT
    status VARCHAR(30) NOT NULL,            -- INITIATED, PENDING_DEBIT, DEBITED, PENDING_CREDIT, SUCCESS, FAILED, REVERSED
    idempotency_key VARCHAR(100) UNIQUE,
    failure_reason TEXT,
    note TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_transactions_source_wallet ON transactions(source_wallet_id);
CREATE INDEX IF NOT EXISTS idx_transactions_target_wallet ON transactions(target_wallet_id);
CREATE INDEX IF NOT EXISTS idx_transactions_sender ON transactions(sender_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_receiver ON transactions(receiver_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_status ON transactions(status);

-- 2. BẢNG OUTBOX_EVENTS (Mẫu Transactional Outbox đảm bảo gửi sự kiện tin cậy)
CREATE TABLE IF NOT EXISTS outbox_events (
    id VARCHAR(36) PRIMARY KEY,
    aggregate_type VARCHAR(50) NOT NULL,    -- TRANSACTION, PAYMENT, SAGA
    aggregate_id VARCHAR(36) NOT NULL,      -- Transaction ID
    event_type VARCHAR(100) NOT NULL,       -- TransactionInitiatedEvent, TransactionCompletedEvent, TransactionReversedEvent
    payload JSONB NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING', -- PENDING, PUBLISHED, FAILED
    retry_count INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    published_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX IF NOT EXISTS idx_outbox_status_created ON outbox_events(status, created_at);
CREATE INDEX IF NOT EXISTS idx_outbox_aggregate ON outbox_events(aggregate_type, aggregate_id);

-- 3. BẢNG BANKS & BANK_ACCOUNTS (Liên kết ngân hàng)
CREATE TABLE IF NOT EXISTS banks (
    id VARCHAR(36) PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,       -- VCB, MBB, TCB, VPB
    name VARCHAR(100) NOT NULL,
    short_name VARCHAR(50) NOT NULL,
    bin VARCHAR(10) NOT NULL UNIQUE,
    logo_url VARCHAR(255),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS bank_accounts (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,           -- Logical User ID
    bank_id VARCHAR(36) NOT NULL REFERENCES banks(id),
    account_number VARCHAR(50) NOT NULL,
    account_holder_name VARCHAR(100) NOT NULL,
    is_verified BOOLEAN NOT NULL DEFAULT FALSE,
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_bank_accounts_user ON bank_accounts(user_id);

-- 4. BẢNG FUNDING_SOURCES (Nguồn tiền thanh toán: Ví, Thẻ, Tài khoản NH)
CREATE TABLE IF NOT EXISTS funding_sources (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    source_type VARCHAR(30) NOT NULL,       -- WALLET, LINKED_BANK, CREDIT_CARD
    source_ref_id VARCHAR(36) NOT NULL,     -- Wallet ID hoặc Bank Account ID
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    priority INT NOT NULL DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_funding_sources_user ON funding_sources(user_id);

-- 5. BẢNG BENEFICIARIES & MONEY_REQUESTS (Người thụ hưởng & Yêu cầu chia tiền)
CREATE TABLE IF NOT EXISTS beneficiaries (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    beneficiary_user_id VARCHAR(36),
    beneficiary_phone VARCHAR(15),
    nickname VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS money_requests (
    id VARCHAR(36) PRIMARY KEY,
    requester_id VARCHAR(36) NOT NULL,
    target_user_id VARCHAR(36) NOT NULL,
    amount BIGINT NOT NULL CHECK (amount > 0),
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING', -- PENDING, ACCEPTED, REJECTED, EXPIRED
    note TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL
);
