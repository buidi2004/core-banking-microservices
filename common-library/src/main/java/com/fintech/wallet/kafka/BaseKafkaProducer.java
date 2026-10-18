package com.fintech.wallet.kafka;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;

import java.util.concurrent.CompletableFuture;

/**
 * Base Kafka Producer dùng chung cho các microservices (Wallet, Payment, v.v.).
 * Cung cấp phương thức send chuẩn hóa với partition key bắt buộc và wrapper {@link KafkaEventEnvelope}.
 */
public class BaseKafkaProducer {

    private static final Logger log = LoggerFactory.getLogger(BaseKafkaProducer.class);

    private final KafkaTemplate<String, Object> kafkaTemplate;

    public BaseKafkaProducer(KafkaTemplate<String, Object> kafkaTemplate) {
        this.kafkaTemplate = kafkaTemplate;
    }

    public <T> CompletableFuture<SendResult<String, Object>> send(String topic, String key, KafkaEventEnvelope<T> envelope) {
        log.debug("Sending Kafka event: topic={}, key={}, eventId={}, traceId={}",
                topic, key, envelope.eventId(), envelope.traceId());

        return kafkaTemplate.send(topic, key, envelope)
                .whenComplete((result, ex) -> {
                    if (ex == null) {
                        log.info("Kafka event published successfully: topic={}, partition={}, offset={}, key={}",
                                topic,
                                result.getRecordMetadata().partition(),
                                result.getRecordMetadata().offset(),
                                key);
                    } else {
                        log.error("Failed to publish Kafka event: topic={}, key={}, error={}",
                                topic, key, ex.getMessage(), ex);
                    }
                });
    }

    public KafkaTemplate<String, Object> getKafkaTemplate() {
        return kafkaTemplate;
    }
}
