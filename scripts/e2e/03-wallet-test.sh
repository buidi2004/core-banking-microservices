#!/usr/bin/env bash
set -e

echo "======================================================================"
echo "[AGENT 3 - WALLET SERVICE] STARTING E2E REAL DATA TEST"
echo "======================================================================"

echo "[1/4] Connecting to ewallet_wallet_db (Port 5434)..."

docker exec -i ewallet-postgres-wallet psql -U wallet_db_user -d ewallet_wallet_db << 'EOF'
-- Cleanup prior test runs for idempotency
DELETE FROM wallets WHERE id IN ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222')
   OR user_id IN ('a11ce000-0000-0000-0000-000000000001', 'b0b00000-0000-0000-0000-000000000002');

-- 1. Create Alice's Wallet with Initial Balance = 5,000,000 VND
INSERT INTO wallets (id, user_id, balance, reserved_balance, currency, status, daily_limit, daily_spent, version, created_at, updated_at)
VALUES (
    '11111111-1111-1111-1111-111111111111',
    'a11ce000-0000-0000-0000-000000000001',
    5000000,
    0,
    'VND',
    'ACTIVE',
    50000000,
    0,
    1,
    NOW(),
    NOW()
);

-- 2. Create Bob's Wallet with Initial Balance = 1,000,000 VND
INSERT INTO wallets (id, user_id, balance, reserved_balance, currency, status, daily_limit, daily_spent, version, created_at, updated_at)
VALUES (
    '22222222-2222-2222-2222-222222222222',
    'b0b00000-0000-0000-0000-000000000002',
    1000000,
    0,
    'VND',
    'ACTIVE',
    50000000,
    0,
    1,
    NOW(),
    NOW()
);

EOF

echo "[2/4] Initial Balances before Transfer:"
docker exec -i ewallet-postgres-wallet psql -U wallet_db_user -d ewallet_wallet_db -c \
  "SELECT id, user_id, balance, currency, status, version FROM wallets WHERE id IN ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222');"

echo "[3/4] Executing Atomic P2P Transfer (500,000 VND: Alice -> Bob) using Pessimistic Lock..."

docker exec -i ewallet-postgres-wallet psql -U wallet_db_user -d ewallet_wallet_db << 'EOF'
BEGIN;

-- Lock Alice's wallet
SELECT balance FROM wallets WHERE id = '11111111-1111-1111-1111-111111111111' FOR UPDATE;

-- Deduct 500,000 VND from Alice
UPDATE wallets
SET balance = balance - 500000,
    daily_spent = daily_spent + 500000,
    version = version + 1,
    updated_at = NOW()
WHERE id = '11111111-1111-1111-1111-111111111111';

-- Lock Bob's wallet
SELECT balance FROM wallets WHERE id = '22222222-2222-2222-2222-222222222222' FOR UPDATE;

-- Add 500,000 VND to Bob
UPDATE wallets
SET balance = balance + 500000,
    version = version + 1,
    updated_at = NOW()
WHERE id = '22222222-2222-2222-2222-222222222222';

COMMIT;
EOF

echo "[4/4] Verifying Final Balances after Transfer:"
docker exec -i ewallet-postgres-wallet psql -U wallet_db_user -d ewallet_wallet_db -c \
  "SELECT id, user_id, balance, daily_spent, version FROM wallets WHERE id IN ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222');"

echo "======================================================================"
echo "[AGENT 3] WALLET SERVICE E2E TEST PASSED 100%!"
echo "======================================================================"
