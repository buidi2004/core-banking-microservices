-- ============================================================================
-- V4: Bổ sung snapshot số dư sau giao dịch cho lịch sử biến động số dư
-- Phục vụ API GET /api/v1/transactions (mobile hiển thị runningBalance).
-- ============================================================================

ALTER TABLE transactions ADD COLUMN IF NOT EXISTS source_balance_after BIGINT;
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS target_balance_after BIGINT;

COMMENT ON COLUMN transactions.source_balance_after IS 'Số dư ví nguồn sau giao dịch (snapshot từ Wallet Service)';
COMMENT ON COLUMN transactions.target_balance_after IS 'Số dư ví đích sau giao dịch (snapshot từ Wallet Service)';
