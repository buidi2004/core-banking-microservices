-- V2 Database Schema for Extended Modules

-- Module 2: Notification Center
CREATE TABLE notifications (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    type VARCHAR(20) NOT NULL, -- ENUM: 'BALANCE', 'PROMOTION', 'SYSTEM'
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL,
    metadata JSON
);

CREATE INDEX idx_notifications_user_id_type ON notifications(user_id, type);
