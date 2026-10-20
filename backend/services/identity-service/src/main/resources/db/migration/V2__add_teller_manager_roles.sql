-- ==============================================================================
-- MIGRATION V2: BỔ SUNG PHÂN QUYỀN GIAO DỊCH VIÊN (TELLER) & KIỂM SOÁT VIÊN (MANAGER)
-- Service: identity-service
-- ==============================================================================

-- 1. Thêm cột branch_id và username cho cán bộ chi nhánh
ALTER TABLE users ADD COLUMN IF NOT EXISTS branch_id VARCHAR(50) DEFAULT 'BR_MAIN';
ALTER TABLE users ADD COLUMN IF NOT EXISTS username VARCHAR(50) UNIQUE;

-- 2. Seed 3 tài khoản Demo chuẩn ngân hàng
-- Mật khẩu mặc định: DemoPass#2026! (Bcrypt hash: $2a$10$Bcg3rjT7oYME6TAZkU8yiuHtvX01FWxsKYWWV/Zl3vuQdHgRxciZy)

-- TELLER 1 (Chi nhánh Quận 1)
INSERT INTO users (id, username, phone_number, password_hash, full_name, email, role, status, kyc_tier, branch_id, created_at, updated_at)
VALUES (
    't0000001-0000-0000-0000-000000000001',
    'teller1',
    '0911000001',
    '$2a$10$Bcg3rjT7oYME6TAZkU8yiuHtvX01FWxsKYWWV/Zl3vuQdHgRxciZy',
    'Teller Nguyễn Văn A',
    'teller1@banking.example.com',
    'ROLE_TELLER',
    'ACTIVE',
    'VERIFIED',
    'BR_Q1',
    NOW(),
    NOW()
) ON CONFLICT (phone_number) DO UPDATE 
SET username = 'teller1', role = 'ROLE_TELLER', full_name = 'Teller Nguyễn Văn A', branch_id = 'BR_Q1',
    password_hash = '$2a$10$Bcg3rjT7oYME6TAZkU8yiuHtvX01FWxsKYWWV/Zl3vuQdHgRxciZy';

-- TELLER 2 (Chi nhánh Hoàn Kiếm)
INSERT INTO users (id, username, phone_number, password_hash, full_name, email, role, status, kyc_tier, branch_id, created_at, updated_at)
VALUES (
    't0000002-0000-0000-0000-000000000002',
    'teller2',
    '0911000002',
    '$2a$10$Bcg3rjT7oYME6TAZkU8yiuHtvX01FWxsKYWWV/Zl3vuQdHgRxciZy',
    'Teller Trần Thị B',
    'teller2@banking.example.com',
    'ROLE_TELLER',
    'ACTIVE',
    'VERIFIED',
    'BR_HK',
    NOW(),
    NOW()
) ON CONFLICT (phone_number) DO UPDATE 
SET username = 'teller2', role = 'ROLE_TELLER', full_name = 'Teller Trần Thị B', branch_id = 'BR_HK',
    password_hash = '$2a$10$Bcg3rjT7oYME6TAZkU8yiuHtvX01FWxsKYWWV/Zl3vuQdHgRxciZy';

-- MANAGER 1 (Kiểm soát viên Chi nhánh Quận 1)
INSERT INTO users (id, username, phone_number, password_hash, full_name, email, role, status, kyc_tier, branch_id, created_at, updated_at)
VALUES (
    'm0000001-0000-0000-0000-000000000001',
    'manager1',
    '0911000003',
    '$2a$10$Bcg3rjT7oYME6TAZkU8yiuHtvX01FWxsKYWWV/Zl3vuQdHgRxciZy',
    'Manager Lê Hoàng C',
    'manager1@banking.example.com',
    'ROLE_MANAGER',
    'ACTIVE',
    'VERIFIED',
    'BR_Q1',
    NOW(),
    NOW()
) ON CONFLICT (phone_number) DO UPDATE 
SET username = 'manager1', role = 'ROLE_MANAGER', full_name = 'Manager Lê Hoàng C', branch_id = 'BR_Q1',
    password_hash = '$2a$10$Bcg3rjT7oYME6TAZkU8yiuHtvX01FWxsKYWWV/Zl3vuQdHgRxciZy';
