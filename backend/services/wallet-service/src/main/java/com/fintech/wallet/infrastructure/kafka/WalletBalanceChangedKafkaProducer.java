package com.fintech.wallet.infrastructure.kafka;

import com.fintech.common.audit.AuditEvent;
import com.fintech.wallet.audit.AuditEventPublisher;
import com.fintech.wallet.kafka.KafkaEventEnvelope;
import com.fintech.wallet.kafka.KafkaTopicConstants;
import com.fintech.wallet.kafka.WalletBalanceChangedPayload;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;
import org.springframework.stereotype.Component;

import java.util.concurrent.CompletableFuture;

/**
 * Kafka Producer cho Wallet Service.
 * Publishes WalletBalanceChangedPayload vào topic
 * {@link KafkaTopicConstants#TOPIC_WALLET_BALANCE_CHANGED}.
 *
 * Partition Key = walletId → đảm bảo Strict Chronological Ordering
 * mọi biến động của cùng 1 ví đều nằm trong duy nhất 1 Partition.
 */
@Component
public class WalletBalanceChangedKafkaProducer {

    private static final Logger log = LoggerFactory.getLogger(WalletBalanceChangedKafkaProducer.class);

    private static final String SERVICE_NAME = "wallet-service";

    private final KafkaTemplate<String, Object> kafkaTemplate;
    private final AuditEventPublisher auditEventPublisher;

    // Chỉ giữ 1 constructor duy nhất để Spring tự resolve bean
    // (2 constructor không @Autowired gây "No default constructor found" khi boot context)
    public WalletBalanceChangedKafkaProducer(KafkaTemplate<String, Object> kafkaTemplate,
                                             AuditEventPublisher auditEventPublisher) {
        this.kafkaTemplate = kafkaTemplate;
        this.auditEventPublisher = auditEventPublisher;
    }

    /**
     * Publish balance change event.
     *
     * @param payload thông tin biến động số dư
     */
    public void publishBalanceChanged(WalletBalanceChangedPayload payload) {
        if (payload == null || payload.walletId() == null || payload.walletId().isBlank()) {
            log.warn("Bỏ qua publish: payload walletId trống");
            return;
        }

        KafkaEventEnvelope<WalletBalanceChangedPayload> envelope = KafkaEventEnvelope.of(
                SERVICE_NAME,
                KafkaTopicConstants.TOPIC_WALLET_BALANCE_CHANGED,
                payload
        );

        log.debug("Publishing balance changed: walletId={}, changeType={}, amount={}",
                payload.walletId(), payload.changeType(), payload.changeAmount());

        CompletableFuture<SendResult<String, Object>> future =
                kafkaTemplate.send(
                        KafkaTopicConstants.TOPIC_WALLET_BALANCE_CHANGED,
                        payload.walletId(),   // ← Partition Key = wallet_id
                        envelope
                );
        if (auditEventPublisher != null) {
            auditEventPublisher.publish(new AuditEvent(
                    java.util.UUID.randomUUID(), java.time.Instant.now(), SERVICE_NAME,
                    "WALLET_BALANCE_CHANGED", "WALLET", payload.walletId(),
                    null, null, null, payload.transactionId(), null, null,
                    null, null, null));
        }

        future.whenComplete((result, ex) -> {
            if (ex != null) {
                log.error("Kafka publish FAILED: walletId={}, topic={}, error={}",
                        payload.walletId(),
                        KafkaTopicConstants.TOPIC_WALLET_BALANCE_CHANGED,
                        ex.getMessage(), ex);
            } else {
                var recordMetadata = result.getRecordMetadata();
                log.info("Kafka publish OK: walletId={}, partition={}, offset={}, txId={}",
                        payload.walletId(),
                        recordMetadata.partition(),
                        recordMetadata.offset(),
                        payload.transactionId());
            }
        });
    }
}
