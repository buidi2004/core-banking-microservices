-- V6__add_account_alias.sql
-- Thêm cột account_alias (biệt danh / tài khoản số đẹp theo phong thủy / shop VietQR)

ALTER TABLE users ADD COLUMN IF NOT EXISTS account_alias VARCHAR(50) UNIQUE;
CREATE INDEX IF NOT EXISTS idx_users_account_alias ON users (account_alias);

