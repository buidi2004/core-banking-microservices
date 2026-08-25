-- V3__add_session_table.sql
CREATE TABLE device_sessions (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    device_id VARCHAR(100) NOT NULL,
    fcm_token VARCHAR(255),
    refresh_token VARCHAR(255),
    ip_address VARCHAR(50),
    user_agent VARCHAR(255),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    last_active_at TIMESTAMP WITH TIME ZONE NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT uq_user_device UNIQUE (user_id, device_id)
);

CREATE INDEX idx_device_sessions_user_id ON device_sessions(user_id);
CREATE INDEX idx_device_sessions_refresh_token ON device_sessions(refresh_token);
