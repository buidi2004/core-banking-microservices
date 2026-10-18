-- V12__create_device_tokens_table.sql
CREATE TABLE device_tokens (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    fcm_token TEXT NOT NULL,
    device_type VARCHAR(20) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT uq_device_tokens_fcm_token UNIQUE (fcm_token)
);

CREATE INDEX idx_device_tokens_user_id ON device_tokens(user_id);
