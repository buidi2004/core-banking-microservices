-- ============================================================================
-- NOTIFICATION SERVICE - V1__init_notification_db.sql
-- Database: ewallet_notification_db
-- Mô tả: Khởi tạo toàn bộ schema cho Notification Service, cắt bỏ FK liên service.
-- ============================================================================

-- Bảng device_tokens: lưu token thiết bị FCM/APNs của người dùng
CREATE TABLE IF NOT EXISTS device_tokens (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       VARCHAR(36) NOT NULL,  -- Logical ID, không FK
    platform      VARCHAR(20) NOT NULL,  -- 'FCM' | 'APNS' | 'WEB'
    token         VARCHAR(512) NOT NULL,
    device_model  VARCHAR(255),
    app_version   VARCHAR(50),
    is_active     BOOLEAN NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_device_tokens_user_id ON device_tokens(user_id);
CREATE INDEX idx_device_tokens_token ON device_tokens(token);
CREATE INDEX idx_device_tokens_platform ON device_tokens(platform, is_active);

-- Bảng notifications: lịch sử thông báo push/in-app/email
CREATE TABLE IF NOT EXISTS notifications (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         VARCHAR(36) NOT NULL,  -- Logical ID, không FK
    type            VARCHAR(50) NOT NULL,  -- 'TRANSFER' | 'TOPUP' | 'KYC_APPROVED' | 'PROMOTION' | 'SYSTEM'
    title           VARCHAR(255) NOT NULL,
    body            TEXT NOT NULL,
    channel         VARCHAR(20) NOT NULL DEFAULT 'FCM',  -- 'FCM' | 'WEBSOCKET' | 'EMAIL' | 'SMS'
    data_payload    JSONB DEFAULT '{}',
    is_read         BOOLEAN NOT NULL DEFAULT FALSE,
    sent_at         TIMESTAMP,
    delivered_at    TIMESTAMP,
    read_at         TIMESTAMP,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notifications_user_id_created ON notifications(user_id, created_at DESC);
CREATE INDEX idx_notifications_type ON notifications(type);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);

-- Bảng vouchers: mã giảm giá / quà tặng
CREATE TABLE IF NOT EXISTS vouchers (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code                VARCHAR(50) UNIQUE NOT NULL,
    title               VARCHAR(255) NOT NULL,
    description         TEXT,
    discount_type       VARCHAR(20) NOT NULL,  -- 'PERCENT' | 'FIXED'
    discount_value      BIGINT NOT NULL,        -- đơn vị tiểu đơn vị (satoshis/vND)
    min_order_amount    BIGINT DEFAULT 0,
    max_discount_amount BIGINT DEFAULT 0,
    valid_from          TIMESTAMP NOT NULL,
    valid_until         TIMESTAMP NOT NULL,
    usage_limit         INTEGER DEFAULT 0,       -- 0 = vô hạn
    used_count          INTEGER NOT NULL DEFAULT 0,
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_vouchers_code ON vouchers(code);
CREATE INDEX idx_vouchers_valid ON vouchers(valid_from, valid_until, is_active);

-- Bảng promotions: chiến dịch khuyến mãi
CREATE TABLE IF NOT EXISTS promotions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(255) NOT NULL,
    description     TEXT,
    type            VARCHAR(50) NOT NULL,  -- 'CASHBACK' | 'BONUS_TRANSFER' | 'WAIVE_FEE'
    target_amount   BIGINT DEFAULT 0,
    reward_amount   BIGINT DEFAULT 0,
    max_reward_per_user BIGINT DEFAULT 0,
    total_reward_budget BIGINT DEFAULT 0,
    reward_claimed  BIGINT NOT NULL DEFAULT 0,
    participant_limit INTEGER DEFAULT 0,   -- 0 = vô hạn
    participants_count INTEGER NOT NULL DEFAULT 0,
    start_date      TIMESTAMP NOT NULL,
    end_date        TIMESTAMP NOT NULL,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    rules_json      JSONB DEFAULT '{}',
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_promotions_active ON promotions(is_active, start_date, end_date);

-- Bảng support_tickets: phiếu hỗ trợ khách hàng
CREATE TABLE IF NOT EXISTS support_tickets (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         VARCHAR(36) NOT NULL,  -- Logical ID, không FK
    subject         VARCHAR(255) NOT NULL,
    description     TEXT NOT NULL,
    category        VARCHAR(50) NOT NULL,  -- 'TRANSFER' | 'ACCOUNT' | 'KYC' | 'OTHER'
    status          VARCHAR(20) NOT NULL DEFAULT 'OPEN',  -- 'OPEN' | 'IN_PROGRESS' | 'CLOSED' | 'RESOLVED'
    priority        VARCHAR(20) NOT NULL DEFAULT 'NORMAL',  -- 'LOW' | 'NORMAL' | 'HIGH' | 'URGENT'
    messages_json   JSONB DEFAULT '[]',
    resolved_at     TIMESTAMP,
    resolved_by     VARCHAR(36),
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_support_tickets_user_id ON support_tickets(user_id);
CREATE INDEX idx_support_tickets_status ON support_tickets(status, created_at DESC);

-- Bảng feedbacks: phản hồi từ người dùng
CREATE TABLE IF NOT EXISTS feedbacks (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         VARCHAR(36) NOT NULL,  -- Logical ID, không FK
    feedback_type   VARCHAR(50) NOT NULL,  -- 'BUG' | 'FEATURE_REQUEST' | 'COMPLIMENT' | 'COMPLAINT'
    subject         VARCHAR(255) NOT NULL,
    content         TEXT NOT NULL,
    rating          SMALLINT,               -- 1-5
    screenshots_json JSONB DEFAULT '[]',
    status          VARCHAR(20) NOT NULL DEFAULT 'NEW',  -- 'NEW' | 'UNDER_REVIEW' | 'RESPONDED' | 'CLOSED'
    response        TEXT,
    responded_by    VARCHAR(36),
    responded_at    TIMESTAMP,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_feedbacks_user_id ON feedbacks(user_id);
CREATE INDEX idx_feedbacks_status ON feedbacks(status, created_at DESC);

-- Bảng referrals: hệ thống giới thiệu
CREATE TABLE IF NOT EXISTS referrals (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    referrer_user_id    VARCHAR(36) NOT NULL,  -- Logical ID, không FK
    referee_user_id     VARCHAR(36) NOT NULL,  -- Logical ID, không FK
    referral_code       VARCHAR(50) NOT NULL,
    reward_amount       BIGINT DEFAULT 0,
    reward_claimed      BOOLEAN NOT NULL DEFAULT FALSE,
    status              VARCHAR(20) NOT NULL DEFAULT 'PENDING',  -- 'PENDING' | 'ACCEPTED' | 'REJECTED' | 'REWARDED'
    registered_at       TIMESTAMP,
    reward_granted_at   TIMESTAMP,
    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(referral_code)
);

CREATE INDEX idx_referrals_referrer ON referrals(referrer_user_id);
CREATE INDEX idx_referrals_referee ON referrals(referee_user_id);
CREATE INDEX idx_referrals_code ON referrals(referral_code);

-- Trigger hàm cập nhật updated_at tự động
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

DO $$
BEGIN
    -- device_tokens
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'set_device_tokens_updated_at') THEN
        CREATE TRIGGER set_device_tokens_updated_at
            BEFORE UPDATE ON device_tokens
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;

    -- notifications
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'set_notifications_updated_at') THEN
        CREATE TRIGGER set_notifications_updated_at
            BEFORE UPDATE ON notifications
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;

    -- vouchers
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'set_vouchers_updated_at') THEN
        CREATE TRIGGER set_vouchers_updated_at
            BEFORE UPDATE ON vouchers
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;

    -- promotions
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'set_promotions_updated_at') THEN
        CREATE TRIGGER set_promotions_updated_at
            BEFORE UPDATE ON promotions
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;

    -- support_tickets
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'set_support_tickets_updated_at') THEN
        CREATE TRIGGER set_support_tickets_updated_at
            BEFORE UPDATE ON support_tickets
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;

    -- feedbacks
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'set_feedbacks_updated_at') THEN
        CREATE TRIGGER set_feedbacks_updated_at
            BEFORE UPDATE ON feedbacks
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;

    -- referrals
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'set_referrals_updated_at') THEN
        CREATE TRIGGER set_referrals_updated_at
            BEFORE UPDATE ON referrals
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
END
$$;
