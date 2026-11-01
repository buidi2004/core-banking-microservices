-- ==============================================================================
-- MIGRATION V10: BỔ SUNG TRƯỜNG PHÊ DUYỆT CÁN BỘ QUẦY CHO HỒ SƠ VAY (LOANS)
-- Database: ewallet_payment_db
-- ==============================================================================

ALTER TABLE loan_contracts ADD COLUMN IF NOT EXISTS approved_by VARCHAR(50);
ALTER TABLE loan_contracts ADD COLUMN IF NOT EXISTS approved_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE loan_contracts ADD COLUMN IF NOT EXISTS reject_reason VARCHAR(255);
