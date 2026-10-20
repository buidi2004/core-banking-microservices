-- ==============================================================================
-- MIGRATION V3: BỔ SUNG CỘT USERNAME VÀ CẬP NHẬT TÀI KHOẢN CÁN BỘ / NGƯỜI DÙNG
-- Service: identity-service
-- ==============================================================================

ALTER TABLE users ADD COLUMN IF NOT EXISTS username VARCHAR(50) UNIQUE;

-- Cập nhật username và mật khẩu chuẩn cho 3 cán bộ
UPDATE users SET username = 'teller1', password_hash = '$2a$10$Bcg3rjT7oYME6TAZkU8yiuHtvX01FWxsKYWWV/Zl3vuQdHgRxciZy' WHERE id = 't0000001-0000-0000-0000-000000000001' OR phone_number = '0911000001';
UPDATE users SET username = 'teller2', password_hash = '$2a$10$Bcg3rjT7oYME6TAZkU8yiuHtvX01FWxsKYWWV/Zl3vuQdHgRxciZy' WHERE id = 't0000002-0000-0000-0000-000000000002' OR phone_number = '0911000002';
UPDATE users SET username = 'manager1', password_hash = '$2a$10$Bcg3rjT7oYME6TAZkU8yiuHtvX01FWxsKYWWV/Zl3vuQdHgRxciZy' WHERE id = 'm0000001-0000-0000-0000-000000000001' OR phone_number = '0911000003';

-- Cập nhật username cho tài khoản khách hàng mặc định
UPDATE users SET username = 'alice' WHERE phone_number = '0901234567';
UPDATE users SET username = 'bob' WHERE phone_number = '0909876543';
