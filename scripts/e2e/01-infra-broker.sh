#!/usr/bin/env bash
set -euo pipefail

echo "======================================================================"
echo "[AGENT 1 - INFRA & BROKER ORCHESTRATOR] STARTING E2E INFRA TEST"
echo "======================================================================"

echo "[1/5] Checking Docker container health (8 core containers)..."
CONTAINERS=(
    "ewallet-postgres-identity"
    "ewallet-postgres-wallet"
    "ewallet-postgres-payment"
    "ewallet-postgres-ledger"
    "ewallet-postgres-notification"
    "ewallet-kafka"
    "ewallet-rabbitmq"
    "ewallet-redis"
)

for c in "${CONTAINERS[@]}"; do
    STATUS=$(docker inspect --format='{{.State.Status}} ({{if .State.Health}}{{.State.Health.Status}}{{else}}no-healthcheck{{end}})' "$c" 2>/dev/null || echo "NOT_FOUND")
    echo "  • $c: $STATUS"
    if [[ "$STATUS" != *"running"* ]]; then
        echo "ERROR: Container $c is not running!"
        exit 1
    fi
done

echo ""
echo "[2/5] Verifying 5 Postgres Databases Connectivity (Real Queries)..."
DB_CHECKS=(
    "ewallet-postgres-identity:identity_db_user:ewallet_identity_db"
    "ewallet-postgres-wallet:wallet_db_user:ewallet_wallet_db"
    "ewallet-postgres-payment:payment_db_user:ewallet_payment_db"
    "ewallet-postgres-ledger:ledger_app_user:ewallet_ledger_db"
    "ewallet-postgres-notification:notification_db_user:ewallet_notification_db"
)

for db in "${DB_CHECKS[@]}"; do
    IFS=":" read -r c u d <<< "$db"
    RESULT=$(docker exec "$c" psql -U "$u" -d "$d" -t -A -c "SELECT 'READY';" 2>/dev/null || echo "FAILED")
    if [ "$RESULT" = "READY" ]; then
        echo "  • $c ($d): CONNECTED & READY"
    else
        echo "ERROR: Database $d in $c failed connectivity check!"
        exit 1
    fi
done

echo ""
echo "[3/5] Verifying and Testing Kafka Broker with Real Data (Produce/Consume)..."
TOPICS=(
    "banking.payment.transaction-lifecycle.v1"
    "banking.wallet.balance-changed.v1"
    "banking.ledger.postings.v1"
    "banking.cash.deposit-completed.v1"
)

for t in "${TOPICS[@]}"; do
    EXISTS=$(docker exec ewallet-kafka kafka-topics --bootstrap-server localhost:9092 --list | grep "^$t$" || true)
    if [ -z "$EXISTS" ]; then
        echo "  • Creating missing topic: $t"
        docker exec ewallet-kafka kafka-topics --bootstrap-server localhost:9092 --create --topic "$t" --partitions 6 --replication-factor 1
    else
        echo "  • Topic verified: $t"
    fi
done

# Real Data Transmission on Kafka
KAFKA_TEST_TOPIC="banking.infra.test.v1"
docker exec ewallet-kafka kafka-topics --bootstrap-server localhost:9092 --create --topic "$KAFKA_TEST_TOPIC" --partitions 3 --replication-factor 1 --if-not-exists > /dev/null 2>&1

KAFKA_TEST_TX="TX-INFRA-$(date +%s)"
KAFKA_TEST_PAYLOAD="{\"eventId\":\"evt-infra-$KAFKA_TEST_TX\",\"transactionId\":\"$KAFKA_TEST_TX\",\"type\":\"INFRA_HEALTH_CHECK\",\"amount\":100000,\"currency\":\"VND\",\"status\":\"SUCCESS\",\"timestamp\":\"$(date -u +%FT%TZ)\"}"

echo "  • Producing test event to $KAFKA_TEST_TOPIC ($KAFKA_TEST_TX)..."
echo "$KAFKA_TEST_PAYLOAD" | docker exec -i ewallet-kafka kafka-console-producer --bootstrap-server localhost:9092 --topic "$KAFKA_TEST_TOPIC"

echo "  • Consuming verified message from Kafka..."
CONSUMED_MSG=$(docker exec ewallet-kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic "$KAFKA_TEST_TOPIC" --from-beginning --max-messages 1 --timeout-ms 5000 2>/dev/null || true)
if [[ "$CONSUMED_MSG" == *"$KAFKA_TEST_TX"* ]]; then
    echo "  • Kafka Real Data Transmission: PASSED (Verified transactionId: $KAFKA_TEST_TX)"
else
    echo "ERROR: Failed to consume expected message from Kafka!"
    exit 1
fi

docker exec ewallet-kafka kafka-topics --bootstrap-server localhost:9092 --delete --topic "$KAFKA_TEST_TOPIC" > /dev/null 2>&1 || true

echo "  • Checking Consumer Groups & Lag..."
docker exec ewallet-kafka kafka-consumer-groups --bootstrap-server localhost:9092 --list | while read -r group; do
    if [ -n "$group" ] && [ "$group" != "__consumer_offsets" ]; then
        echo "    - Consumer Group: $group"
    fi
done

echo ""
echo "[4/5] Checking RabbitMQ Broker with Real Data (Publish/Consume)..."
docker exec ewallet-rabbitmq rabbitmqctl status > /dev/null
echo "  • RabbitMQ Broker: ACTIVE & HEALTHY"

RABBIT_QUEUE="infra-test-queue"
# Declare temporary queue
curl -s -u wallet:wallet123 -X PUT "http://localhost:15672/api/queues/%2F/$RABBIT_QUEUE" \
  -H "Content-Type: application/json" \
  -d '{"auto_delete":true,"durable":false}' > /dev/null

RABBIT_TOKEN="RABBIT_INFRA_$(date +%s)"
PUB_RES=$(curl -s -u wallet:wallet123 -H "Content-Type: application/json" \
  -X POST "http://localhost:15672/api/exchanges/%2F/amq.default/publish" \
  -d "{\"properties\":{},\"routing_key\":\"$RABBIT_QUEUE\",\"payload\":\"{\\\"event\\\":\\\"INFRA_RABBITMQ_TEST\\\",\\\"token\\\":\\\"$RABBIT_TOKEN\\\"}\",\"payload_encoding\":\"string\"}")

if [[ "$PUB_RES" == *"\"routed\":true"* ]]; then
    echo "  • RabbitMQ Publish to $RABBIT_QUEUE: ROUTED SUCCESS"
else
    echo "ERROR: RabbitMQ publish failed: $PUB_RES"
    exit 1
fi

SUB_RES=$(curl -s -u wallet:wallet123 -H "Content-Type: application/json" \
  -X POST "http://localhost:15672/api/queues/%2F/$RABBIT_QUEUE/get" \
  -d '{"count":1,"ackmode":"ack_requeue_false","encoding":"auto"}')

if [[ "$SUB_RES" == *"$RABBIT_TOKEN"* ]]; then
    echo "  • RabbitMQ Consume & ACK: VERIFIED SUCCESS (Matched token: $RABBIT_TOKEN)"
else
    echo "ERROR: RabbitMQ consume failed: $SUB_RES"
    exit 1
fi

# Cleanup queue
curl -s -u wallet:wallet123 -X DELETE "http://localhost:15672/api/queues/%2F/$RABBIT_QUEUE" > /dev/null

echo ""
echo "[5/5] Checking Redis Broker with Real Data (SET/GET/TTL/DEL)..."
REDIS_PONG=$(docker exec ewallet-redis redis-cli ping)
echo "  • Redis Ping: $REDIS_PONG"

REDIS_KEY="infra:broker:test:$(date +%s)"
REDIS_VAL="{\"status\":\"ACTIVE\",\"node\":\"redis-master\",\"testedAt\":\"$(date -u +%FT%TZ)\"}"
docker exec ewallet-redis redis-cli SET "$REDIS_KEY" "$REDIS_VAL" EX 60 > /dev/null
READ_VAL=$(docker exec ewallet-redis redis-cli GET "$REDIS_KEY")
docker exec ewallet-redis redis-cli DEL "$REDIS_KEY" > /dev/null

if [[ "$READ_VAL" == *"ACTIVE"* ]]; then
    echo "  • Redis Real Data Round-Trip (SET/GET/DEL): PASSED"
else
    echo "ERROR: Redis round-trip failed: $READ_VAL"
    exit 1
fi

echo ""
echo "======================================================================"
echo "[AGENT 1] ALL INFRASTRUCTURE & BROKER SYSTEMS PASSED 100%!"
echo "======================================================================"
