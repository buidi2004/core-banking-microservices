package com.fintech.wallet.kafka;

import org.apache.kafka.common.TopicPartition;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.core.KafkaOperations;
import org.springframework.kafka.listener.DeadLetterPublishingRecoverer;
import org.springframework.kafka.listener.DefaultErrorHandler;
import org.springframework.util.backoff.BackOff;
import org.springframework.util.backoff.FixedBackOff;

/**
 * Factory cấu hình Base Error Handler và Dead Letter Topic (.DLT) cho Kafka Consumer.
 * Tự động retry với backoff và chuyển tiếp message lỗi sang topic .DLT tương ứng.
 */
public final class KafkaErrorHandlerFactory {

    private static final Logger log = LoggerFactory.getLogger(KafkaErrorHandlerFactory.class);

    private KafkaErrorHandlerFactory() {
    }

    /**
     * Tạo DefaultErrorHandler retry 3 lần (mỗi lần cách nhau 1000ms), sau đó forward sang DLT.
     */
    public static DefaultErrorHandler createDeadLetterErrorHandler(KafkaOperations<?, ?> kafkaOperations) {
        return createDeadLetterErrorHandler(kafkaOperations, new FixedBackOff(1000L, 3L));
    }

    /**
     * Tạo DefaultErrorHandler với chính sách BackOff tùy biến.
     */
    public static DefaultErrorHandler createDeadLetterErrorHandler(KafkaOperations<?, ?> kafkaOperations, BackOff backOff) {
        DeadLetterPublishingRecoverer recoverer = new DeadLetterPublishingRecoverer(kafkaOperations,
                (record, ex) -> {
                    String dltTopic = record.topic() + ".DLT";
                    log.error("Kafka consumer failed after retries. Forwarding to DLT: topic={}, partition={}, offset={}, key={}, reason={}",
                            dltTopic, record.partition(), record.offset(), record.key(), ex.getMessage());
                    return new TopicPartition(dltTopic, record.partition());
                });

        return new DefaultErrorHandler(recoverer, backOff);
    }
}
