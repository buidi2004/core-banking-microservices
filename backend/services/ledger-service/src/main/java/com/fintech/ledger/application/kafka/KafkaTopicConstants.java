package com.fintech.ledger.application.kafka;

/**
 * Hợp đồng topic Kafka dùng chung (khớp KafkaTopicConstants của Agent 1 trong common-library;
 * khi Agent 1 merge phiên bản chính thức thì thay bằng import từ common-library).
 */
public final class KafkaTopicConstants {

    public static final String TOPIC_WALLET_BALANCE_CHANGED = "banking.wallet.balance-changed.v1";
    public static final String TOPIC_PAYMENT_TRANSACTION_LIFECYCLE = "banking.payment.transaction-lifecycle.v1";
    public static final String TOPIC_CASH_DEPOSIT_COMPLETED = "banking.cash.deposit-completed.v1";

    public static final String DEAD_LETTER_SUFFIX = ".DLT";

    private KafkaTopicConstants() {
    }
}
