package com.fintech.payment.kafka;

import com.fintech.common.audit.AuditEvent;
import com.fintech.payment.audit.AuditEventPublisher;
import com.fintech.wallet.kafka.KafkaEventEnvelope;
import com.fintech.wallet.kafka.KafkaTopicConstants;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;
import org.springframework.stereotype.Component;

import java.util.concurrent.CompletableFuture;

/**
 * Producer stream Saga Transaction Lifecycle lên Kafka.
 * Message Key = transaction_id để đảm bảo tất cả sự kiện của 1 giao dịch
 * rơi vào cùng 1 Partition (strict chronological ordering theo ví/giao dịch).
 */
@Component
@Slf4j
public class PaymentKafkaProducer {

    private final KafkaTemplate<String, Object> kafkaTemplate;
    private final AuditEventPublisher auditEventPublisher;

    public PaymentKafkaProducer(KafkaTemplate<String, Object> kafkaTemplate) {
        this(kafkaTemplate, null);
    }

    // @Autowired bắt buộc khi có 2 constructor, nếu không Spring sẽ
    // "No default constructor found" khi boot context (Xem WalletBalanceChangedKafkaProducer)
    @org.springframework.beans.factory.annotation.Autowired
    public PaymentKafkaProducer(KafkaTemplate<String, Object> kafkaTemplate,
                                AuditEventPublisher auditEventPublisher) {
        this.kafkaTemplate = kafkaTemplate;
        this.auditEventPublisher = auditEventPublisher;
    }

    /**
     * Gửi sự kiện vòng đời Saga (INITIATED, DEBITED, CREDITED, SUCCESS, FAILED, REVERSED).
     *
     * @param transactionId id giao dịch - dùng làm Kafka message key (partition key)
     * @param eventType     loại sự kiện Saga
     * @param payload       nội dung sự kiện (đã serialize sẵn hoặc đối tượng business)
     */
    public CompletableFuture<SendResult<String, Object>> sendLifecycleEvent(String transactionId,
                                                                           String eventType,
                                                                           Object payload) {
        KafkaEventEnvelope<Object> envelope = KafkaEventEnvelope.of(
                transactionId,
                "payment-service",
                KafkaTopicConstants.TOPIC_PAYMENT_TRANSACTION_LIFECYCLE,
                payload
        );

        CompletableFuture<SendResult<String, Object>> future =
                kafkaTemplate.send(KafkaTopicConstants.TOPIC_PAYMENT_TRANSACTION_LIFECYCLE,
                        transactionId, envelope);
        publishAudit(transactionId, eventType);

        future.whenComplete((result, ex) -> {
            if (ex != null) {
                log.error("Kafka lifecycle event failed: topic={} key={} eventType={} error={}",
                        KafkaTopicConstants.TOPIC_PAYMENT_TRANSACTION_LIFECYCLE, transactionId, eventType,
                        ex.getMessage(), ex);
            } else if (result != null && result.getRecordMetadata() != null) {
                log.debug("Kafka lifecycle event sent: topic={} key={} eventType={} partition={} offset={}",
                        KafkaTopicConstants.TOPIC_PAYMENT_TRANSACTION_LIFECYCLE, transactionId, eventType,
                        result.getRecordMetadata().partition(), result.getRecordMetadata().offset());
            }
        });

        return future;
    }

    public static final String TOPIC_CASH_DEPOSIT_COMPLETED = "banking.cash.deposit-completed.v1";

    /**
     * Gửi sự kiện nạp tiền mặt tại quầy đã hoàn tất sang Kafka (cho Ledger Service & Notification Service).
     */
    public void sendCashDepositCompleted(String depositCode, String accountNumber, String customerName, Long amount, String branchId) {
        try {
            java.util.Map<String, Object> payload = new java.util.HashMap<>();
            payload.put("eventType", "DepositCompletedEvent");
            payload.put("depositCode", depositCode);
            payload.put("accountNumber", accountNumber);
            payload.put("customerName", customerName);
            payload.put("amount", amount);
            payload.put("branchId", branchId);
            payload.put("timestamp", System.currentTimeMillis());

            kafkaTemplate.send(TOPIC_CASH_DEPOSIT_COMPLETED, accountNumber, payload);
            publishAudit(depositCode, "CASH_DEPOSIT_COMPLETED");
            log.info("Kafka cash deposit completed event sent: topic={} depositCode={}", TOPIC_CASH_DEPOSIT_COMPLETED, depositCode);
        } catch (Exception e) {
            log.warn("Kafka cash deposit event send failed for depositCode={}: {}", depositCode, e.getMessage());
        }
    }

    private void publishAudit(String resourceId, String action) {
            if (auditEventPublisher != null) {
                auditEventPublisher.publish(new AuditEvent(
                        java.util.UUID.randomUUID(), java.time.Instant.now(), "payment-service",
                        action, "PAYMENT", resourceId, null, null, null, null,
                        null, null, null, null, null));
        }
    }
}
