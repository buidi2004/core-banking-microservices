package com.fintech.wallet.kafka;

import org.apache.kafka.clients.producer.RecordMetadata;
import org.apache.kafka.common.TopicPartition;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.kafka.core.KafkaOperations;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.listener.DefaultErrorHandler;
import org.springframework.kafka.support.SendResult;

import java.math.BigDecimal;
import java.util.UUID;
import java.util.concurrent.CompletableFuture;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class KafkaCommonLibraryTest {

    @Mock
    private KafkaTemplate<String, Object> kafkaTemplate;

    @Mock
    private KafkaOperations<Object, Object> kafkaOperations;

    @Test
    @DisplayName("KafkaEventEnvelope tạo đúng metadata (eventId, traceId, timestamp, payload)")
    void testKafkaEventEnvelope() {
        String producer = "wallet-service";
        String topic = KafkaTopicConstants.TOPIC_WALLET_BALANCE_CHANGED;
        String payload = "test-payload";

        KafkaEventEnvelope<String> envelope = KafkaEventEnvelope.of(producer, topic, payload);

        assertNotNull(envelope.eventId());
        assertNotNull(envelope.traceId());
        assertNotNull(envelope.timestamp());
        assertEquals(producer, envelope.producerService());
        assertEquals(topic, envelope.topic());
        assertEquals(payload, envelope.payload());
    }

    @Test
    @DisplayName("WalletBalanceChangedPayload tính toán chính xác số dư khi debit và credit")
    void testWalletBalanceChangedPayload() {
        String walletId = "w-100";
        BigDecimal previous = new BigDecimal("1000000");
        BigDecimal amount = new BigDecimal("200000");

        WalletBalanceChangedPayload debit = WalletBalanceChangedPayload.debit(walletId, previous, amount, "VND", "tx-1");
        assertEquals(walletId, debit.walletId());
        assertEquals(new BigDecimal("-200000"), debit.changeAmount());
        assertEquals(new BigDecimal("800000"), debit.newBalance());
        assertEquals("WITHDRAWAL", debit.changeType());

        WalletBalanceChangedPayload credit = WalletBalanceChangedPayload.credit(walletId, previous, amount, "VND", "tx-2");
        assertEquals(new BigDecimal("200000"), credit.changeAmount());
        assertEquals(new BigDecimal("1200000"), credit.newBalance());
        assertEquals("DEPOSIT", credit.changeType());
    }

    @Test
    @DisplayName("PaymentTransactionLifecyclePayload tạo đúng dữ liệu lifecycle trạng thái Saga")
    void testPaymentTransactionLifecyclePayload() {
        PaymentTransactionLifecyclePayload payload = PaymentTransactionLifecyclePayload.of(
                "tx-999",
                "trace-123",
                PaymentTransactionLifecyclePayload.LifecycleStatus.INITIATED,
                "w-src",
                "w-tgt",
                new BigDecimal("500000"),
                BigDecimal.ZERO,
                "VND",
                "SAGA_INITIATED",
                null
        );

        assertEquals("tx-999", payload.transactionId());
        assertEquals("trace-123", payload.traceId());
        assertEquals("INITIATED", payload.status());
        assertEquals("w-src", payload.sourceWalletId());
        assertEquals("w-tgt", payload.targetWalletId());
        assertNotNull(payload.occurredAt());
    }

    @Test
    @DisplayName("BaseKafkaProducer gửi event bọc trong envelope thành công")
    void testBaseKafkaProducer() {
        BaseKafkaProducer producer = new BaseKafkaProducer(kafkaTemplate);

        String topic = KafkaTopicConstants.TOPIC_WALLET_BALANCE_CHANGED;
        String key = "wallet-123";
        KafkaEventEnvelope<String> envelope = KafkaEventEnvelope.of("wallet-service", topic, "hello");

        RecordMetadata metadata = new RecordMetadata(new TopicPartition(topic, 0), 0, 0, 0, 0, 0);
        SendResult<String, Object> sendResult = new SendResult<>(null, metadata);
        CompletableFuture<SendResult<String, Object>> future = CompletableFuture.completedFuture(sendResult);

        when(kafkaTemplate.send(eq(topic), eq(key), eq(envelope))).thenReturn(future);

        CompletableFuture<SendResult<String, Object>> resultFuture = producer.send(topic, key, envelope);

        assertNotNull(resultFuture);
        verify(kafkaTemplate).send(topic, key, envelope);
    }

    @Test
    @DisplayName("KafkaErrorHandlerFactory khởi tạo DefaultErrorHandler có cấu hình DLT")
    void testKafkaErrorHandlerFactory() {
        DefaultErrorHandler errorHandler = KafkaErrorHandlerFactory.createDeadLetterErrorHandler(kafkaOperations);
        assertNotNull(errorHandler);
    }
}
