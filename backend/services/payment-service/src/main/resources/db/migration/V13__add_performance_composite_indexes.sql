-- ==============================================================================
-- MIGRATION V13: BỔ SUNG CÁC CHỈ MỤC HIỆU NĂNG CAO (HIGH PERFORMANCE COMPOSITE INDEXES)
-- Database: ewallet_payment_db
-- ==============================================================================

-- 1. Tối ưu hàng đợi duyệt nạp tiền tại quầy Teller Portal & Maker-Checker
CREATE INDEX IF NOT EXISTS idx_cash_deposits_status_created 
    ON cash_deposits(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_cash_deposits_account 
    ON cash_deposits(account_number);

-- 2. Tối ưu tra cứu danh mục Sổ tiết kiệm theo người dùng & trạng thái
CREATE INDEX IF NOT EXISTS idx_savings_user_status 
    ON savings_accounts(user_id, status);

-- 3. Tối ưu tra cứu hợp đồng Vay tiêu dùng & lịch trả nợ từng kỳ
CREATE INDEX IF NOT EXISTS idx_loan_user_status 
    ON loan_contracts(user_id, status);
CREATE INDEX IF NOT EXISTS idx_loan_schedule_contract_term 
    ON loan_schedule_items(loan_contract_id, term_number);

-- 4. Tối ưu chuyển mạch Switchboard & danh sách thẻ thanh toán
CREATE INDEX IF NOT EXISTS idx_cards_user_status 
    ON cards(user_id, status);

-- 5. Tối ưu hóa hóa đơn đã thanh toán theo người dùng
CREATE INDEX IF NOT EXISTS idx_bills_paid_by_user 
    ON bills(paid_by_user_id, status);

-- 6. Tối ưu danh bạ người thụ hưởng theo thời gian tạo
CREATE INDEX IF NOT EXISTS idx_beneficiaries_user_created 
    ON beneficiaries(user_id, created_at DESC);

