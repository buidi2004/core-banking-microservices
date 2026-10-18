package com.fintech.notification.amqp;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fintech.notification.config.RabbitMqConfig;
import com.fintech.notification.entity.Notification;
import com.fintech.notification.repository.NotificationRepository;
import com.fintech.wallet.domain.event.TransactionEvent;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.containers.RabbitMQContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.awaitility.Awaitility.await;

@Testcontainers(disabledWithoutDocker = true)
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class NotificationConsumerIntegrationTest {

    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16");

    @Container
    static final RabbitMQContainer RABBITMQ = new RabbitMQContainer("rabbitmq:3-management-alpine");

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
    }

    @Autowired
    private RabbitTemplate rabbitTemplate;

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
        event.setNote("integration transfer");
        event.setOccurredAt(Instant.parse("2026-10-18T05:00:00Z"));
        return event;
    }

    private void publish(TransactionEvent event) {
        rabbitTemplate.convertAndSend(RabbitMqConfig.EXCHANGE_NAME, "transaction.completed", event);
    }

    @Test
    void consumesEventFromRabbitAndPersistsNotifications() throws Exception {
        publish(transferEvent("evt-it-1", "tx-it-1"));

        await().atMost(Duration.ofSeconds(20))
                .until(() -> notificationRepository.count() == 2);

        List<Notification> notifications = notificationRepository.findAll();
        assertThat(notifications)
                .extracting(Notification::getUserId)
                .containsExactlyInAnyOrder("user-001", "user-002");

        List<String> payloadTypes = new java.util.ArrayList<>();
        for (Notification notification : notifications) {
            assertThat(notification.getType()).isEqualTo("BALANCE");
            assertThat(notification.getChannel()).isEqualTo("FCM");
            assertThat(notification.isRead()).isFalse();

            Map<String, String> payload = objectMapper.readValue(
                    notification.getDataPayload(), new TypeReference<Map<String, String>>() { });
            assertThat(payload).containsEntry("transactionId", "tx-it-1");
            payloadTypes.add(payload.get("type"));
        }

        assertThat(payloadTypes).containsExactlyInAnyOrder("TRANSFER_OUT", "TRANSFER_IN");
    }

    @Test
    void duplicateEventIsConsumedOnlyOnce() {
        TransactionEvent event = transferEvent("evt-it-dup", "tx-it-dup");

        publish(event);
        await().atMost(Duration.ofSeconds(20))
                .until(() -> notificationRepository.count() == 2);

        publish(event);

        await().pollDelay(Duration.ofSeconds(2))
                .atMost(Duration.ofSeconds(6))
                .untilAsserted(() -> assertThat(notificationRepository.count()).isEqualTo(2));
    }

    @Test
    void ignoresEventWithoutWalletInformation() {
        TransactionEvent event = new TransactionEvent();
        event.setEventId("evt-it-empty");
        event.setTransactionId("tx-it-empty");
        event.setType("TRANSFER");
        event.setAmount(BigDecimal.TEN);
        event.setCurrency("VND");

        publish(event);

        await().pollDelay(Duration.ofSeconds(2))
                .atMost(Duration.ofSeconds(5))
                .untilAsserted(() -> assertThat(notificationRepository.count()).isZero());
    }
}
