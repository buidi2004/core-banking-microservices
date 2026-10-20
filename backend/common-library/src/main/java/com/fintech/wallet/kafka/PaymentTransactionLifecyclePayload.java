package com.fintech.wallet.kafka;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * Payload chứa thông tin vòng đời giao dịch Saga chuyển tiền, được publish vào topic
 * {@link KafkaTopicConstants#TOPIC_PAYMENT_TRANSACTION_LIFECYCLE}.
 *
 * Partition key: transactionId (đảm bảo toàn bộ lifecycle của 1 transaction nằm cùng 1 partition).
 */
public record PaymentTransactionLifecyclePayload(
        String transactionId,
        String traceId,
        String status,
        String sourceWalletId,
        String targetWalletId,
        BigDecimal amount,
        BigDecimal feeAmount,
        String currency,
        String step,
        String errorMessage,
        Instant occurredAt
) {
    public enum LifecycleStatus {
        INITIATED,
        FUNDS_LOCKED,
        COMPLETED,
        REVERSED,
        FAILED
    }

    public static PaymentTransactionLifecyclePayload of(
            String transactionId,
            String traceId,
            LifecycleStatus status,
            String sourceWalletId,
            String targetWalletId,
            BigDecimal amount,
            BigDecimal feeAmount,
            String currency,
            String step,
            String errorMessage) {
        return new PaymentTransactionLifecyclePayload(
                transactionId,
                traceId,
                status.name(),
                sourceWalletId,
                targetWalletId,
                amount,
                feeAmount,
                currency != null ? currency : "VND",
                step,
                errorMessage,
                Instant.now()
        );
    }
}
