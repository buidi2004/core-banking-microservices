CREATE TABLE banks (
    id VARCHAR(36) PRIMARY KEY,
    bank_code VARCHAR(50) UNIQUE NOT NULL,
    bank_name VARCHAR(255) NOT NULL,
    logo_url VARCHAR(500),
    is_internal BOOLEAN NOT NULL DEFAULT FALSE
);

INSERT INTO banks (id, bank_code, bank_name, logo_url, is_internal) VALUES
('b1-senhong', 'SENHONG', 'Sen Hồng Bank', 'https://example.com/senhong.png', TRUE),
('b2-vcb', 'VCB', 'Vietcombank', 'https://example.com/vcb.png', FALSE),
('b3-tcb', 'TCB', 'Techcombank', 'https://example.com/tcb.png', FALSE),
('b4-bidv', 'BIDV', 'BIDV', 'https://example.com/bidv.png', FALSE);

ALTER TABLE transactions ADD COLUMN bank_code VARCHAR(50);
ALTER TABLE transactions ADD COLUMN fee_amount DECIMAL(19, 4);
ALTER TABLE transactions ADD COLUMN balance_after DECIMAL(19, 4);
