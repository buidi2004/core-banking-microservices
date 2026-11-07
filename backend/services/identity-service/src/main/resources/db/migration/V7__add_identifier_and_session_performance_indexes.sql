-- ==============================================================================
-- MIGRATION V7: CHỈ MỤC TỐI ƯU HÓA HIỆU NĂNG TÌM KIẾM ĐỊNH DANH & PHIÊN ĐĂNG NHẬP
-- Database: ewallet_identity_db
-- ==============================================================================

-- 1. Functional indexes cho tìm kiếm đăng nhập không phân biệt chữ hoa/thường
CREATE INDEX IF NOT EXISTS idx_users_lower_username ON users (LOWER(username));
CREATE INDEX IF NOT EXISTS idx_users_lower_email ON users (LOWER(email));

-- 2. Tối ưu quét xóa phiên đăng nhập hết hạn (Cleanup Cron / Scheduler)
CREATE INDEX IF NOT EXISTS idx_sessions_expires_at ON user_sessions (expires_at);
