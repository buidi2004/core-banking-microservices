-- ====================================================================
-- V6: Card Management System (CMS) & Physical/Virtual Cards
-- ====================================================================

CREATE TABLE IF NOT EXISTS cards (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    card_number VARCHAR(19) NOT NULL,
    masked_number VARCHAR(25) NOT NULL,
    card_holder VARCHAR(100) NOT NULL,
    card_type VARCHAR(20) NOT NULL,
    card_tier VARCHAR(50) NOT NULL,
    scheme VARCHAR(20) NOT NULL,
    expiry_date VARCHAR(10) NOT NULL,
    cvv VARCHAR(4) NOT NULL,
    credit_limit NUMERIC(19, 4) NOT NULL DEFAULT 0,
    available_limit NUMERIC(19, 4) NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    color_scheme VARCHAR(30) NOT NULL DEFAULT 'platinum',
    is_physical BOOLEAN NOT NULL DEFAULT FALSE,
    delivery_address VARCHAR(255),
    online_payment BOOLEAN NOT NULL DEFAULT TRUE,
    intl_payment BOOLEAN NOT NULL DEFAULT TRUE,
    contactless BOOLEAN NOT NULL DEFAULT TRUE,
    atm_withdraw BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_cards_user ON cards(user_id);

