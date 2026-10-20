-- ====================================================================
-- V8: Beneficiary details extension (bankCode, accountNumber, fullName)
-- ====================================================================

ALTER TABLE beneficiaries ADD COLUMN IF NOT EXISTS full_name VARCHAR(100);
ALTER TABLE beneficiaries ADD COLUMN IF NOT EXISTS bank_code VARCHAR(20);
ALTER TABLE beneficiaries ADD COLUMN IF NOT EXISTS account_number VARCHAR(50);
ALTER TABLE beneficiaries ADD COLUMN IF NOT EXISTS beneficiary_wallet_id VARCHAR(36);

