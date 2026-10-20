package com.fintech.ledger.infrastructure.kafka;

import com.fintech.ledger.application.kafka.KafkaEventEnvelope;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.config.ConcurrentKafkaListenerContainerFactory;
import org.springframework.kafka.core.ConsumerFactory;
import org.springframework.kafka.core.KafkaOperations;
import org.springframework.kafka.listener.DeadLetterPublishingRecoverer;
import org.springframework.kafka.listener.DefaultErrorHandler;
import org.springframework.util.backoff.FixedBackOff;

/**
 * Cấu hình Kafka cho Ledger (Agent 4):
 * - group-id: ledger-posting-group, auto-offset-reset: earliest, enable-auto-commit: false (@see application.yml)
 * - ack MANUAL_IMMEDIATE sau khi hạch toán DB thành công
 * - Concurrency mặc định = 3; thứ tự theo key (wallet_id / transaction_id) luôn bảo toàn trong partition
 * - DefaultErrorHandler: retry 3 lần (backoff 1s) rồi đẩy topic + ".DLT"
 */
@Configuration
@EnableKafka
public class KafkaTopicConfig {

    public static final String LEDGER_POSTING_GROUP = "ledger-posting-group";
    public static final String TOPIC_WALLET_BALANCE_CHANGED =
            com.fintech.ledger.application.kafka.KafkaTopicConstants.TOPIC_WALLET_BALANCE_CHANGED;
    public static final String TOPIC_PAYMENT_TRANSACTION_LIFECYCLE =
            com.fintech.ledger.application.kafka.KafkaTopicConstants.TOPIC_PAYMENT_TRANSACTION_LIFECYCLE;
    public static final String TOPIC_CASH_DEPOSIT_COMPLETED =
            com.fintech.ledger.application.kafka.KafkaTopicConstants.TOPIC_CASH_DEPOSIT_COMPLETED;

    private static final Logger log = LoggerFactory.getLogger(KafkaTopicConfig.class);

    @Value("${ledger.kafka.consumer-concurrency:3}")
    private int concurrency;

    @SuppressWarnings({"unchecked", "rawtypes"})
    @Bean
    public ConcurrentKafkaListenerContainerFactory<String, KafkaEventEnvelope> ledgerKafkaListenerContainerFactory(
            ConsumerFactory consumerFactory,
            KafkaOperations deadLetterKafkaTemplate) {

        ConcurrentKafkaListenerContainerFactory<String, KafkaEventEnvelope> factory =
                new ConcurrentKafkaListenerContainerFactory<>();
        factory.setConsumerFactory(consumerFactory);
        factory.setConcurrency(concurrency);
        factory.getContainerProperties().setAckMode(org.springframework.kafka.listener.ContainerProperties.AckMode.MANUAL_IMMEDIATE);

        DefaultErrorHandler errorHandler = new DefaultErrorHandler(
                new DeadLetterPublishingRecoverer(deadLetterKafkaTemplate),
                new FixedBackOff(1000L, 3L));
        // Retry 3 lần (backoff 1s) rồi đẩy topic + ".DLT"

        factory.setCommonErrorHandler(errorHandler);
        return factory;
    }
}
