CREATE TABLE IF NOT EXISTS lottery_draws (
    id VARCHAR(36) PRIMARY KEY,
    game_name VARCHAR(50) NOT NULL,
    draw_period VARCHAR(50) NOT NULL,
    draw_date VARCHAR(50) NOT NULL,
    winning_numbers VARCHAR(100) NOT NULL,
    special_number INT,
    jackpot1_amount BIGINT NOT NULL DEFAULT 12000000000,
    jackpot2_amount BIGINT,
    winners_j1 INT NOT NULL DEFAULT 0,
    winners_j2 INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS lottery_tickets (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    ticket_code VARCHAR(50) NOT NULL UNIQUE,
    game_name VARCHAR(50) NOT NULL,
    draw_period VARCHAR(50) NOT NULL,
    selected_numbers VARCHAR(100) NOT NULL,
    amount BIGINT NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    status VARCHAR(50) NOT NULL DEFAULT 'PENDING_DRAW',
    winning_amount BIGINT NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_lottery_tickets_user ON lottery_tickets(user_id);
CREATE INDEX IF NOT EXISTS idx_lottery_tickets_period ON lottery_tickets(draw_period);

