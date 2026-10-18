-- ============================================================================
-- WALLET CORE SERVICE - V1__init_wallet_db.sql
-- Database: ewallet_wallet_db
-- Bảng: wallets (Tối ưu hóa I/O, khóa bi quan SELECT FOR UPDATE)
-- Không có Foreign Key vật lý sang users table (Logical user_id VARCHAR(36))
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS wallets (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL UNIQUE,
    balance BIGINT NOT NULL DEFAULT 0 CHECK (balance >= 0),
    reserved_balance BIGINT NOT NULL DEFAULT 0 CHECK (reserved_balance >= 0),
    currency VARCHAR(10) NOT NULL DEFAULT 'VND',
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE', -- ACTIVE, LOCKED, SUSPENDED, CLOSED
    daily_limit BIGINT NOT NULL DEFAULT 50000000, -- 50 triệu/ngày
    daily_spent BIGINT NOT NULL DEFAULT 0,
    last_reset_date DATE DEFAULT CURRENT_DATE,
    version BIGINT NOT NULL DEFAULT 0,            -- Optimistic locking fallback
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Chỉ mục tối ưu hóa tìm kiếm ví theo user_id trong < 1ms
CREATE UNIQUE INDEX IF NOT EXISTS idx_wallets_user_id ON wallets(user_id);
CREATE INDEX IF NOT EXISTS idx_wallets_status ON wallets(status);

-- Trigger tự động cập nhật updated_at
CREATE OR REPLACE FUNCTION update_wallet_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_wallets_updated_at ON wallets;
CREATE TRIGGER trg_wallets_updated_at
BEFORE UPDATE ON wallets
FOR EACH ROW EXECUTE FUNCTION update_wallet_timestamp();
