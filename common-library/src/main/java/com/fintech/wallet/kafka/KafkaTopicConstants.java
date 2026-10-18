package com.fintech.wallet.kafka;

/**
 * Các hằng định nghĩa Topic Kafka hệ thống Core Banking.
 * (Theo spec AGENT 1 - common-library cung cấp cấu hình chuẩn dùng chung).
 *
 * Quy tắc đặt tên: banking.{service-name}.{entity}.{version}
 * Mỗi topic được cấu hình 6 partitions để đảm bảo throughput cao và phân vùng theo Partition Key:
 *   - TOPIC_WALLET_BALANCE_CHANGED: Partition Key = wallet_id
 *   - TOPIC_PAYMENT_TRANSACTION_LIFECYCLE: Partition Key = transaction_id
 */
public final class KafkaTopicConstants {

    // ── Wallet Service Topic ──────────────────────────────────────────────────
    public static final String TOPIC_WALLET_BALANCE_CHANGED = "banking.wallet.balance-changed.v1";

    // ── Payment Service Topic ─────────────────────────────────────────────────
    public static final String TOPIC_PAYMENT_TRANSACTION_LIFECYCLE = "banking.payment.transaction-lifecycle.v1";

    // ── Dead Letter Topics (.DLT) ─────────────────────────────────────────────
    public static final String DLT_WALLET_BALANCE_CHANGED = TOPIC_WALLET_BALANCE_CHANGED + ".DLT";
    public static final String DLT_PAYMENT_TRANSACTION_LIFECYCLE = TOPIC_PAYMENT_TRANSACTION_LIFECYCLE + ".DLT";

    // ── Cấu hình mặc định ─────────────────────────────────────────────────────
    public static final int DEFAULT_PARTITIONS = 6;
    public static final short DEFAULT_REPLICATION_FACTOR = 1;

    private KafkaTopicConstants() {
    }
}
