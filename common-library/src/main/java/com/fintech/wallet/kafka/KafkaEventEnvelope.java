package com.fintech.wallet.kafka;

import java.time.Instant;
import java.util.UUID;

/**
 * Envelope đóng gói tất cả event Kafka trong hệ thống với metadata chuẩn ngân hàng.
 * Bắt buộc có khi publish event để Ledger Service (Agent 4) thực hiện idempotent consume.
 *
 * Metadata bao gồm:
 *  - eventId: UUID duy nhất dùng cho dedup / idempotency
 *  - traceId: ID phân tán dùng để đối soát và trace log toàn trình E2E
 *  - timestamp: Thời điểm phát sinh sự kiện
 *  - producerService: Dịch vụ gốc phát hành sự kiện
 *  - topic: Kafka Topic đích
 *  - payload: Dữ liệu nghiệp vụ chi tiết
 *
 * @param <T> Loại payload thực tế (WalletBalanceChangedPayload, PaymentTransactionLifecyclePayload, ...)
 */
public record KafkaEventEnvelope<T>(
        UUID eventId,
        String traceId,
        Instant timestamp,
        String producerService,
        String topic,
        T payload
) {
    /**
     * Constructor tương thích ngược cho phép gọi không truyền traceId.
     */
    public KafkaEventEnvelope(UUID eventId, Instant timestamp, String producerService, String topic, T payload) {
        this(eventId, UUID.randomUUID().toString(), timestamp, producerService, topic, payload);
    }

    public static <T> KafkaEventEnvelope<T> of(String producerService, String topic, T payload) {
        return new KafkaEventEnvelope<>(
                UUID.randomUUID(),
                UUID.randomUUID().toString(),
                Instant.now(),
                producerService,
                topic,
                payload
        );
    }

    public static <T> KafkaEventEnvelope<T> of(String traceId, String producerService, String topic, T payload) {
        return new KafkaEventEnvelope<>(
                UUID.randomUUID(),
                traceId != null && !traceId.isBlank() ? traceId : UUID.randomUUID().toString(),
                Instant.now(),
                producerService,
                topic,
                payload
        );
    }
}
