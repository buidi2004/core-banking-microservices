package com.fintech.notification.service;

import com.fintech.common.audit.AuditEvent;
import com.fintech.notification.audit.AuditEventPublisher;
import com.fintech.notification.config.RabbitMqConfig;
import com.fintech.notification.dto.TestPushRequest;
import com.fintech.notification.entity.Notification;
import com.fintech.notification.kafka.KafkaConsumerConfig;
import com.fintech.notification.notification.FcmPushSender;
import com.fintech.notification.notification.NotificationPayload;
import com.fintech.notification.notification.WebSocketNotifier;
import com.fintech.notification.repository.DeviceTokenRepository;
import com.fintech.wallet.kafka.KafkaTopicConstants;
import com.google.firebase.FirebaseApp;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.core.Message;
import org.springframework.amqp.rabbit.core.RabbitAdmin;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.*;

@Slf4j
@Service
@RequiredArgsConstructor
public class NotificationOpsService {

    private final RabbitAdmin rabbitAdmin;
    private final RabbitTemplate rabbitTemplate;
    private final DeviceTokenRepository deviceTokenRepository;
    private final NotificationService notificationService;
    private final WebSocketNotifier webSocketNotifier;
    private final FcmPushSender fcmPushSender;
    private final AuditEventPublisher auditEventPublisher;

    public Map<String, Object> getDlqStats() {
        Map<String, Object> stats = new LinkedHashMap<>();

        // RabbitMQ DLQ inspection
        long dlqCount = 0L;
        long mainCount = 0L;
        boolean rabbitHealthy = false;

        try {
            Properties dlqProps = rabbitAdmin.getQueueProperties(RabbitMqConfig.DLQ_NOTIFICATION);
            if (dlqProps != null) {
                Object count = dlqProps.get(RabbitAdmin.QUEUE_MESSAGE_COUNT);
                if (count instanceof Number num) {
                    dlqCount = num.longValue();
                }
                rabbitHealthy = true;
            }

            Properties mainProps = rabbitAdmin.getQueueProperties(RabbitMqConfig.QUEUE_NOTIFICATION);
            if (mainProps != null) {
                Object count = mainProps.get(RabbitAdmin.QUEUE_MESSAGE_COUNT);
                if (count instanceof Number num) {
                    mainCount = num.longValue();
                }
            }
        } catch (Exception e) {
            log.warn("Cannot inspect RabbitMQ queues: {}", e.getMessage());
        }

        stats.put("rabbitMqHealthy", rabbitHealthy);
        stats.put("mainQueue", RabbitMqConfig.QUEUE_NOTIFICATION);
        stats.put("mainQueueMessageCount", mainCount);
        stats.put("dlqQueue", RabbitMqConfig.DLQ_NOTIFICATION);
        stats.put("dlqMessageCount", dlqCount);
        stats.put("dlqExchange", RabbitMqConfig.DLX_NAME);

        // Kafka DLT inspection
        stats.put("kafkaConsumerGroup", KafkaConsumerConfig.CONSUMER_GROUP_ID);
        stats.put("kafkaTopics", List.of(
                KafkaTopicConstants.TOPIC_PAYMENT_TRANSACTION_LIFECYCLE,
                KafkaTopicConstants.TOPIC_WALLET_BALANCE_CHANGED
        ));
        stats.put("kafkaDltTopic", KafkaTopicConstants.TOPIC_PAYMENT_TRANSACTION_LIFECYCLE + ".DLT");

        return stats;
    }

    public Map<String, Object> retryDlqMessages(int maxMessages, String actorId) {
        int safeLimit = Math.min(Math.max(1, maxMessages), 200);
        int reprocessed = 0;

        try {
            for (int i = 0; i < safeLimit; i++) {
                Message msg = rabbitTemplate.receive(RabbitMqConfig.DLQ_NOTIFICATION);
                if (msg == null) {
                    break;
                }
                rabbitTemplate.send(RabbitMqConfig.QUEUE_NOTIFICATION, msg);
                reprocessed++;
            }
        } catch (Exception e) {
            log.error("Error during DLQ retry: {}", e.getMessage(), e);
        }

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("reprocessedCount", reprocessed);

        long remaining = 0L;
        try {
            Properties props = rabbitAdmin.getQueueProperties(RabbitMqConfig.DLQ_NOTIFICATION);
            if (props != null && props.get(RabbitAdmin.QUEUE_MESSAGE_COUNT) instanceof Number n) {
                remaining = n.longValue();
            }
        } catch (Exception ignored) {}
        result.put("remainingCount", remaining);

        publishAudit("NOTIFICATION_DLQ_RETRY", "DLQ", actorId,
                "Đã chạy thử lại " + reprocessed + " tin nhắn từ " + RabbitMqConfig.DLQ_NOTIFICATION);

        log.info("DLQ retry completed by actor {}: reprocessed={}, remaining={}", actorId, reprocessed, remaining);
        return result;
    }

    public Map<String, Object> purgeDlq(String actorId) {
        boolean success = false;
        try {
            rabbitAdmin.purgeQueue(RabbitMqConfig.DLQ_NOTIFICATION, false);
            success = true;
        } catch (Exception e) {
            log.error("Error purging DLQ: {}", e.getMessage(), e);
        }

        publishAudit("NOTIFICATION_DLQ_PURGE", "DLQ", actorId,
                "Đã xóa sạch hàng đợi dead-letter " + RabbitMqConfig.DLQ_NOTIFICATION);

        log.info("DLQ purged by actor {}", actorId);
        return Map.of("purged", success, "queue", RabbitMqConfig.DLQ_NOTIFICATION);
    }

    public Map<String, Object> getProviderHealth() {
        Map<String, Object> health = new LinkedHashMap<>();

        // 1. FCM Provider
        Map<String, Object> fcm = new LinkedHashMap<>();
        boolean fcmInitialized = !FirebaseApp.getApps().isEmpty();
        fcm.put("status", fcmInitialized ? "UP" : "MOCK_FALLBACK");
        fcm.put("appCount", FirebaseApp.getApps().size());
        fcm.put("registeredDeviceTokens", deviceTokenRepository.countByActiveTrue());
        health.put("fcm", fcm);

        // 2. WebSocket STOMP Provider
        Map<String, Object> ws = new LinkedHashMap<>();
        ws.put("status", "UP");
        ws.put("brokerDestinations", List.of("/topic/wallets", "/topic/users", "/topic/admin", "/topic/transactions"));
        health.put("websocket", ws);

        // 3. RabbitMQ Broker
        Map<String, Object> rabbit = new LinkedHashMap<>();
        try {
            Properties props = rabbitAdmin.getQueueProperties(RabbitMqConfig.QUEUE_NOTIFICATION);
            rabbit.put("status", props != null ? "UP" : "DEGRADED");
        } catch (Exception e) {
            rabbit.put("status", "DOWN");
            rabbit.put("error", e.getMessage());
        }
        health.put("rabbitmq", rabbit);

        // 4. Kafka Listener
        Map<String, Object> kafka = new LinkedHashMap<>();
        kafka.put("status", "UP");
        kafka.put("consumerGroup", KafkaConsumerConfig.CONSUMER_GROUP_ID);
        health.put("kafka", kafka);

        return health;
    }

    public Map<String, Object> sendTestNotification(TestPushRequest request, String actorId) {
        String userId = request.userId().trim();
        String title = "[TEST] " + request.title().trim();
        String body = request.body().trim();
        String channel = request.channel() != null ? request.channel().trim().toUpperCase() : "ALL";

        List<String> deliveredChannels = new ArrayList<>();

        // In-App Notification
        if ("ALL".equals(channel) || "IN_APP".equals(channel)) {
            Notification n = Notification.create(userId, "SYSTEM", title, body, "IN_APP", "{\"test\":true}");
            notificationService.save(n);
            deliveredChannels.add("IN_APP");
        }

        // WebSocket
        if ("ALL".equals(channel) || "WEBSOCKET".equals(channel)) {
            NotificationPayload wsPayload = new NotificationPayload(
                    UUID.randomUUID().toString(),
                    "test-" + System.currentTimeMillis(),
                    "SYSTEM",
                    "SUCCESS",
                    userId,
                    null,
                    "VND",
                    null,
                    "VND",
                    Instant.now().toString(),
                    "Test Notification",
                    title,
                    body
            );
            webSocketNotifier.pushToUser(userId, wsPayload);
            webSocketNotifier.pushToAdmin(wsPayload);
            deliveredChannels.add("WEBSOCKET");
        }

        // FCM Push
        if ("ALL".equals(channel) || "FCM".equals(channel)) {
            fcmPushSender.sendPushNotification(userId, title, body, Map.of("test", "true"));
            deliveredChannels.add("FCM");
        }

        publishAudit("NOTIFICATION_TEST_SENT", userId, actorId,
                "Đã phát thông báo thử nghiệm tới " + userId + " qua các kênh: " + String.join(", ", deliveredChannels));

        return Map.of(
                "success", true,
                "targetUserId", userId,
                "channels", deliveredChannels,
                "sentAt", Instant.now().toString()
        );
    }

    private void publishAudit(String action, String resourceId, String actorId, String details) {
        if (auditEventPublisher != null) {
            try {
                auditEventPublisher.publish(new AuditEvent(
                        UUID.randomUUID(),
                        Instant.now(),
                        "notification-service",
                        action,
                        "NOTIFICATION_OPS",
                        resourceId,
                        actorId,
                        null,
                        null,
                        null,
                        null,
                        null,
                        null,
                        null,
                        details
                ));
            } catch (Exception e) {
                log.warn("Failed to publish audit event {}: {}", action, e.getMessage());
            }
        }
    }
}
