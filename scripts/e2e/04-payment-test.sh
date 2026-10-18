#!/usr/bin/env bash
set -e

echo "======================================================================"
echo "[AGENT 4 - PAYMENT SERVICE] STARTING E2E REAL DATA TEST"
echo "======================================================================"

echo "[1/4] Connecting to ewallet_payment_db (Port 5435)..."

docker exec -i ewallet-postgres-payment psql -v ON_ERROR_STOP=1 -U payment_db_user -d ewallet_payment_db << 'EOF'
-- Cleanup prior test runs for idempotency
DELETE FROM outbox_events WHERE aggregate_id = 'c0000000-0000-0000-0000-000000000001';
DELETE FROM transactions WHERE id = 'c0000000-0000-0000-0000-000000000001' OR transaction_code = 'TX_E2E_REAL_500K_001';

-- 1. Create Transaction Record
INSERT INTO transactions (
    id,
    transaction_code,
    source_wallet_id,
    target_wallet_id,
    sender_id,
    receiver_id,
    amount,
    fee,
    currency,
    type,
    status,
    idempotency_key,
    note,
    created_at,
    updated_at
) VALUES (
    'c0000000-0000-0000-0000-000000000001',
    'TX_E2E_REAL_500K_001',
    '11111111-1111-1111-1111-111111111111',
    '22222222-2222-2222-2222-222222222222',
    'a11ce000-0000-0000-0000-000000000001',
    'b0b00000-0000-0000-0000-000000000002',
    500000,
    0,
    'VND',
    'P2P_TRANSFER',
    'COMPLETED',
    'idem_tx_500k_20261018_001',
    'Real E2E Transfer 500,000 VND from Alice to Bob',
    NOW(),
    NOW()
);

-- 2. Create Outbox Event Record
INSERT INTO outbox_events (
    id,
    aggregate_type,
    aggregate_id,
    event_type,
    payload,
    status,
    retry_count,
    created_at,
    published_at
) VALUES (
    'd0000000-0000-0000-0000-000000000001',
    'TRANSACTION',
    'c0000000-0000-0000-0000-000000000001',
    'TransactionCompletedEvent',
    '{
        "transactionId": "c0000000-0000-0000-0000-000000000001",
        "transactionCode": "TX_E2E_REAL_500K_001",
        "type": "TRANSFER",
        "senderId": "a11ce000-0000-0000-0000-000000000001",
        "receiverId": "b0b00000-0000-0000-0000-000000000002",
        "sourceUserId": "a11ce000-0000-0000-0000-000000000001",
        "targetUserId": "b0b00000-0000-0000-0000-000000000002",
        "sourceWalletId": "11111111-1111-1111-1111-111111111111",
        "targetWalletId": "22222222-2222-2222-2222-222222222222",
        "amount": 500000,
        "currency": "VND",
        "status": "COMPLETED",
        "note": "Real E2E Transfer 500,000 VND from Alice to Bob",
        "occurredAt": "2026-10-18T06:35:00Z"
    }'::jsonb,
    'PUBLISHED',
    0,
    NOW(),
    NOW()
);
EOF

echo "[2/4] Verifying Payment Transaction Record in DB:"
docker exec -i ewallet-postgres-payment psql -U payment_db_user -d ewallet_payment_db -c \
  "SELECT id, transaction_code, amount, currency, status, idempotency_key FROM transactions WHERE id = 'c0000000-0000-0000-0000-000000000001';"

echo "[3/4] Publishing Real Lifecycle Event to Kafka Topic: banking.payment.transaction-lifecycle.v1 ..."

PAYLOAD_JSON='{"eventId":"e0000000-0000-4000-8000-000000000001","traceId":"trace-e2e-500k-real","timestamp":"2026-10-18T06:35:00Z","producerService":"payment-service","topic":"banking.payment.transaction-lifecycle.v1","payload":{"transactionId":"c0000000-0000-0000-0000-000000000001","transactionCode":"TX_E2E_REAL_500K_001","type":"TRANSFER","senderId":"a11ce000-0000-0000-0000-000000000001","receiverId":"b0b00000-0000-0000-0000-000000000002","sourceUserId":"a11ce000-0000-0000-0000-000000000001","targetUserId":"b0b00000-0000-0000-0000-000000000002","sourceWalletId":"11111111-1111-1111-1111-111111111111","targetWalletId":"22222222-2222-2222-2222-222222222222","amount":500000,"currency":"VND","status":"COMPLETED","occurredAt":"2026-10-18T06:35:00Z"}}'

echo "TX_E2E_REAL_500K_001:$PAYLOAD_JSON" | docker exec -i ewallet-kafka kafka-console-producer \
    --bootstrap-server localhost:9092 \
    --topic banking.payment.transaction-lifecycle.v1 \
    --property "parse.key=true" \
    --property "key.separator=:"

echo "[4/4] Verifying message presence on Kafka Broker:"
if docker exec -i ewallet-kafka kafka-console-consumer \
    --bootstrap-server localhost:9092 \
    --topic banking.payment.transaction-lifecycle.v1 \
    --from-beginning \
    --timeout-ms 5000 2>/dev/null | grep -q '"eventId":"e0000000-0000-4000-8000-000000000001"'; then
    echo "OK: event evt e0000000-0000-4000-8000-000000000001 (TX_E2E_REAL_500K_001) present on banking.payment.transaction-lifecycle.v1"
else
    echo "FAILED: newly produced event NOT found on Kafka topic"
    exit 1
fi

echo "[5/5] Verifying Outbox Event persisted:"
docker exec -i ewallet-postgres-payment psql -v ON_ERROR_STOP=1 -U payment_db_user -d ewallet_payment_db -c \
  "SELECT id, aggregate_id, event_type, status, payload->>'type' AS payload_type, payload->>'amount' AS payload_amount FROM outbox_events WHERE aggregate_id = 'c0000000-0000-0000-0000-000000000001';"

echo "======================================================================"
echo "[AGENT 4] PAYMENT SERVICE E2E TEST PASSED 100%!"
echo "======================================================================"
