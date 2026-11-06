-- ==============================================================================
-- MIGRATION V5: BỔ SUNG CÁC CHỈ MỤC HIỆU NĂNG CHO IDENTITY SERVICE
-- Database: ewallet_identity_db
-- ==============================================================================

-- 1. Tối ưu hàng đợi duyệt hồ sơ eKYC (Chỉ index bản ghi PENDING)
CREATE INDEX IF NOT EXISTS idx_kycs_pending_created 
    ON user_kycs(created_at ASC) 
    WHERE verification_status = 'PENDING';

-- 2. Tối ưu truy vấn danh sách người dùng theo chi nhánh & vai trò
CREATE INDEX IF NOT EXISTS idx_users_branch_role 
    ON users(branch_id, role);

