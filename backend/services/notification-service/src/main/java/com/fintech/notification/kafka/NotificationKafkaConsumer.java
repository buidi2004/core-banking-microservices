package com.fintech.notification.kafka;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fintech.notification.amqp.NotificationConsumer;
import com.fintech.wallet.domain.event.TransactionEvent;
import com.fintech.wallet.kafka.KafkaTopicConstants;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.stereotype.Component;

@Component
public class NotificationKafkaConsumer {

    private static final Logger log = LoggerFactory.getLogger(NotificationKafkaConsumer.class);

    private final NotificationConsumer notificationConsumer;
    private final ObjectMapper objectMapper;

    public NotificationKafkaConsumer(NotificationConsumer notificationConsumer, ObjectMapper objectMapper) {
        this.notificationConsumer = notificationConsumer;
        this.objectMapper = objectMapper;
    }

    @KafkaListener(
            topics = {
                    KafkaTopicConstants.TOPIC_PAYMENT_TRANSACTION_LIFECYCLE,
                    KafkaTopicConstants.TOPIC_WALLET_BALANCE_CHANGED
            },
            groupId = KafkaConsumerConfig.CONSUMER_GROUP_ID,
            containerFactory = KafkaConsumerConfig.LISTENER_CONTAINER_FACTORY)
    public void onTransactionEvent(ConsumerRecord<String, String> record, Acknowledgment acknowledgment) {
        TransactionEvent event = parse(record.value());
        notificationConsumer.onTransactionEvent(event);
        acknowledgment.acknowledge();
        log.info("Kafka notification event consumed: topic={} partition={} offset={} key={} txId={}",
                record.topic(), record.partition(), record.offset(), record.key(), event.getTransactionId());
    }

    private TransactionEvent parse(String payload) {
        if (payload == null || payload.isBlank()) {
            throw new IllegalArgumentException("Empty Kafka transaction event payload");
        }
        try {
            JsonNode root = objectMapper.readTree(payload);
            JsonNode eventNode = root.hasNonNull("payload") ? root.get("payload") : root;
            return objectMapper.treeToValue(eventNode, TransactionEvent.class);
        } catch (Exception e) {
            throw new IllegalArgumentException("Cannot deserialize Kafka transaction event", e);
        }
    }
}
