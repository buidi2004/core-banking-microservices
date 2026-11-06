-- ============================================================================
-- WALLET CORE SERVICE - V2__add_overdraft_limit.sql
-- Tính năng 4.1: Hạn Mức Thấu Chi Tài Khoản Thanh Toán (Overdraft Limit)
--
-- Nghiệp vụ:
--  - Cho phép số dư khả dụng âm tới một mức hạn mức được cấp (VD: -20.000.000 VND).
--  - Ràng buộc `balance + overdraft_limit >= 0` được kiểm soát ở tầng dịch vụ
--    (WalletGrpcService / WalletInternalApplicationService) cùng pessimistic lock,
--    vì lãi vay thấu chi trừ trực tiếp và có thể làm dư nợ phát triển vượt hạn mức gốc.
--  - Lãi thấu chi tính theo ngày trên phần dư nợ âm qua API batch admin
--    (POST /api/v1/wallets/admin/overdraft-interest/accrue).
-- ============================================================================

-- 1) Thêm cột hạn mức thấu chi (mặc định 0 = không cho thấu chi, tương thích backward)
ALTER TABLE wallets
    ADD COLUMN IF NOT EXISTS overdraft_limit BIGINT NOT NULL DEFAULT 0
    CHECK (overdraft_limit >= 0);

-- 2) Bỏ CHECK "balance >= 0" của V1 (tên constraint ngầm định do PostgreSQL sinh)
--    để cho phép số dư âm thuộc dư nợ thấu chi.
ALTER TABLE wallets
    DROP CONSTRAINT IF EXISTS wallets_balance_check;

COMMENT ON COLUMN wallets.overdraft_limit IS
    'Hạn mức thấu chi cấp cho ví (VND). Số dư khả dụng = balance + overdraft_limit - reserved_balance. 0 = không thấu chi.';
