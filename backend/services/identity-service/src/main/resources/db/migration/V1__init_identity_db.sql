-- ============================================================================
-- IDENTITY & AUTH SERVICE - V1__init_identity_db.sql
-- Database: ewallet_identity_db
-- Các bảng: users, user_profiles, user_kycs, user_sessions
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. BẢNG USERS (Tài khoản chính, xác thực)
CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(36) PRIMARY KEY,
    phone_number VARCHAR(15) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100),
    email VARCHAR(100) UNIQUE,
    role VARCHAR(20) NOT NULL DEFAULT 'ROLE_USER',
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    kyc_tier VARCHAR(20) NOT NULL DEFAULT 'UNVERIFIED', -- UNVERIFIED, BASIC, VERIFIED, ENTERPRISE
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone_number);
CREATE INDEX IF NOT EXISTS idx_users_status ON users(status);

-- 2. BẢNG USER_PROFILES (Thông tin cá nhân mở rộng)
CREATE TABLE IF NOT EXISTS user_profiles (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    avatar_url VARCHAR(255),
    date_of_birth DATE,
    address TEXT,
    gender VARCHAR(10),
    identity_card_number VARCHAR(20) UNIQUE,
    identity_card_issued_date DATE,
    identity_card_issued_place VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_profiles_user_id ON user_profiles(user_id);

-- 3. BẢNG USER_KYCS (Hồ sơ eKYC & OCR xác minh danh tính)
CREATE TABLE IF NOT EXISTS user_kycs (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    document_type VARCHAR(20) NOT NULL, -- ID_CARD, PASSPORT, DRIVER_LICENSE
    document_number VARCHAR(50) NOT NULL,
    front_image_url VARCHAR(255) NOT NULL,
    back_image_url VARCHAR(255),
    face_image_url VARCHAR(255) NOT NULL,
    ocr_extracted_data JSONB,
    verification_status VARCHAR(20) NOT NULL DEFAULT 'PENDING', -- PENDING, APPROVED, REJECTED
    reject_reason TEXT,
    verified_by VARCHAR(36),
    verified_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_kycs_user_id ON user_kycs(user_id);
CREATE INDEX IF NOT EXISTS idx_kycs_status ON user_kycs(verification_status);

-- 4. BẢNG USER_SESSIONS (Quản lý phiên đăng nhập thiết bị)
CREATE TABLE IF NOT EXISTS user_sessions (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id VARCHAR(100) NOT NULL,
    device_name VARCHAR(100),
    device_os VARCHAR(50),
    ip_address VARCHAR(45),
    user_agent TEXT,
    refresh_token_hash VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    is_revoked BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_accessed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON user_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_token_hash ON user_sessions(refresh_token_hash);
