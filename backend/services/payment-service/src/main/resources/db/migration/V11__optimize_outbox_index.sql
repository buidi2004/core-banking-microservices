-- ==============================================================================
-- MIGRATION V11: TỐI ƯU HÓA PARTIAL INDEX CHO OUTBOX RELAY
-- Database: ewallet_payment_db
-- Mục tiêu: Tối ưu truy vấn poll outbox events (chỉ index các bản ghi PENDING)
-- ==============================================================================

CREATE INDEX IF NOT EXISTS idx_outbox_pending_relay 
ON outbox_events(created_at ASC) 
WHERE status = 'PENDING';

