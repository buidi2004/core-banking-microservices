package com.fintech.notification.kafka;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fintech.notification.entity.Notification;
import com.fintech.notification.repository.NotificationRepository;
import com.fintech.wallet.domain.event.TransactionEvent;
import com.fintech.wallet.kafka.KafkaTopicConstants;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.containers.RabbitMQContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.kafka.KafkaContainer;
import org.testcontainers.utility.DockerImageName;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.TimeUnit;

import static org.assertj.core.api.Assertions.assertThat;
import static org.awaitility.Awaitility.await;

@Testcontainers(disabledWithoutDocker = true)
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class NotificationKafkaConsumerIntegrationTest {

    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16");

    @Container
    static final RabbitMQContainer RABBITMQ = new RabbitMQContainer("rabbitmq:3-management-alpine");

    @Container
    static final KafkaContainer KAFKA = new KafkaContainer(DockerImageName.parse("apache/kafka:3.7.0"));

    @DynamicPropertySource
    static void registerProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        registry.add("spring.datasource.username", POSTGRES::getUsername);
        registry.add("spring.datasource.password", POSTGRES::getPassword);
        registry.add("spring.datasource.driver-class-name", () -> "org.postgresql.Driver");

        registry.add("spring.rabbitmq.host", RABBITMQ::getHost);
        registry.add("spring.rabbitmq.port", () -> RABBITMQ.getAmqpPort());
        registry.add("spring.rabbitmq.username", RABBITMQ::getAdminUsername);
        registry.add("spring.rabbitmq.password", RABBITMQ::getAdminPassword);

        registry.add("spring.kafka.bootstrap-servers", KAFKA::getBootstrapServers);
    }

    @Autowired
    private KafkaTemplate<String, String> notificationKafkaTemplate;

    @Autowired
    private NotificationRepository notificationRepository;

    @Autowired
    private ObjectMapper objectMapper;

    @BeforeEach
    void cleanDatabase() {
        notificationRepository.deleteAll();
    }

    private TransactionEvent transferEvent(String eventId, String transactionId) {
        TransactionEvent event = new TransactionEvent();
        event.setEventId(eventId);
        event.setTransactionId(transactionId);
        event.setType("TRANSFER");
        event.setStatus("SUCCESS");
        event.setSourceWalletId("wallet-A");
        event.setTargetWalletId("wallet-B");
        event.setSourceUserId("user-001");
        event.setTargetUserId("user-002");
        event.setSourcePhone("0900000001");
        event.setTargetPhone("0900000002");
        event.setAmount(BigDecimal.valueOf(150000));
        event.setFeeAmount(BigDecimal.valueOf(5000));
        event.setCurrency("VND");
        event.setSourceBalanceAfter(BigDecimal.valueOf(850000));
        event.setTargetBalanceAfter(BigDecimal.valueOf(150000));
        event.setNote("kafka integration transfer");
        event.setOccurredAt(Instant.parse("2026-10-18T05:00:00Z"));
        return event;
    }

    private void publish(String topic, String key, Object payload) throws Exception {
        String json = payload instanceof String value ? value : objectMapper.writeValueAsString(payload);
        notificationKafkaTemplate.send(topic, key, json).get(15, TimeUnit.SECONDS);
    }

    private long countForTx(String transactionId) {
        return notificationRepository.findAll().stream()
                .filter(n -> n.getDataPayload() != null && n.getDataPayload().contains(transactionId))
                .count();
    }

    private void awaitNotificationsForTx(String transactionId, long expected) {
        await().atMost(Duration.ofSeconds(30))
                .until(() -> countForTx(transactionId) == expected);
    }

    @Test
    void consumesPaymentLifecycleEventFromKafkaAndPushesNotifications() throws Exception {
        TransactionEvent event = transferEvent("evt-kafka-1", "tx-kafka-1");
        publish(KafkaTopicConstants.TOPIC_PAYMENT_TRANSACTION_LIFECYCLE, event.getTransactionId(), event);

        awaitNotificationsForTx("tx-kafka-1", 2);

        List<Notification> notifications = notificationRepository.findAll().stream()
                .filter(n -> n.getDataPayload() != null && n.getDataPayload().contains("tx-kafka-1"))
                .toList();
        assertThat(notifications)
                .extracting(Notification::getUserId)
                .containsExactlyInAnyOrder("user-001", "user-002");

        assertThat(notifications).allSatisfy(notification -> {
            assertThat(notification.getType()).isEqualTo("BALANCE");
            assertThat(notification.getChannel()).isEqualTo("FCM");
            assertThat(notification.isRead()).isFalse();
        });

        List<String> payloadTypes = notifications.stream()
                .map(n -> n.getDataPayload())
                .map(this::extractType)
                .toList();
        assertThat(payloadTypes).containsExactlyInAnyOrder("TRANSFER_OUT", "TRANSFER_IN");
    }

    @Test
    void consumesWalletBalanceChangedTopic() throws Exception {
        TransactionEvent event = transferEvent("evt-kafka-wallet", "tx-kafka-wallet");
        publish(KafkaTopicConstants.TOPIC_WALLET_BALANCE_CHANGED, event.getSourceWalletId(), event);

        awaitNotificationsForTx("tx-kafka-wallet", 2);
    }

    @Test
    void toleratesEnvelopeWrappedPayload() throws Exception {
        TransactionEvent event = transferEvent("evt-kafka-env", "tx-kafka-env");
        Map<String, Object> envelope = new LinkedHashMap<>();
        envelope.put("eventId", "evt-kafka-env");
        envelope.put("traceId", "trace-kafka-1");
        envelope.put("producerService", "payment-service");
        envelope.put("timestamp", Instant.parse("2026-10-18T05:00:00Z").toString());
        envelope.put("payload", event);

        publish(KafkaTopicConstants.TOPIC_PAYMENT_TRANSACTION_LIFECYCLE, event.getTransactionId(), envelope);

        awaitNotificationsForTx("tx-kafka-env", 2);
    }

    @Test
    void duplicateKafkaEventIsProcessedOnlyOnce() throws Exception {
        TransactionEvent event = transferEvent("evt-kafka-dup", "tx-kafka-dup");
        String json = objectMapper.writeValueAsString(event);

        publish(KafkaTopicConstants.TOPIC_PAYMENT_TRANSACTION_LIFECYCLE, event.getTransactionId(), json);
        awaitNotificationsForTx("tx-kafka-dup", 2);

        publish(KafkaTopicConstants.TOPIC_PAYMENT_TRANSACTION_LIFECYCLE, event.getTransactionId(), json);

        await().pollDelay(Duration.ofSeconds(3))
                .atMost(Duration.ofSeconds(8))
                .untilAsserted(() -> assertThat(countForTx("tx-kafka-dup")).isEqualTo(2));
    }

    private String extractType(String dataPayload) {
        try {
            return objectMapper.readTree(dataPayload).path("type").asText();
        } catch (Exception e) {
            throw new IllegalStateException("Cannot read notification payload", e);
        }
    }
}
