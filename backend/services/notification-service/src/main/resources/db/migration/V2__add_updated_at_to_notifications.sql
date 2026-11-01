-- ============================================================================
-- NOTIFICATION SERVICE - V2__add_updated_at_to_notifications.sql
-- Thêm cột updated_at cho bảng notifications để tương thích với trigger set_notifications_updated_at
-- ============================================================================
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;

