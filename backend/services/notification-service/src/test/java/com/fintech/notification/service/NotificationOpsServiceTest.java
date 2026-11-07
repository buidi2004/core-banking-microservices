package com.fintech.notification.service;

import com.fintech.notification.audit.AuditEventPublisher;
import com.fintech.notification.config.RabbitMqConfig;
import com.fintech.notification.dto.TestPushRequest;
import com.fintech.notification.notification.FcmPushSender;
import com.fintech.notification.notification.WebSocketNotifier;
import com.fintech.notification.repository.DeviceTokenRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.amqp.core.Message;
import org.springframework.amqp.rabbit.core.RabbitAdmin;
import org.springframework.amqp.rabbit.core.RabbitTemplate;

import java.util.Map;
import java.util.Properties;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class NotificationOpsServiceTest {

    @Mock
    private RabbitAdmin rabbitAdmin;

    @Mock
    private RabbitTemplate rabbitTemplate;

    @Mock
    private DeviceTokenRepository deviceTokenRepository;

    @Mock
    private NotificationService notificationService;

    @Mock
    private WebSocketNotifier webSocketNotifier;

    @Mock
    private FcmPushSender fcmPushSender;

    @Mock
    private AuditEventPublisher auditEventPublisher;

    @InjectMocks
    private NotificationOpsService opsService;

    @Test
    @DisplayName("Lấy thống kê hàng đợi DLQ thành công")
    void getDlqStats_success() {
        Properties dlqProps = new Properties();
        dlqProps.put(RabbitAdmin.QUEUE_MESSAGE_COUNT, 5);

        Properties mainProps = new Properties();
        mainProps.put(RabbitAdmin.QUEUE_MESSAGE_COUNT, 20);

        when(rabbitAdmin.getQueueProperties(RabbitMqConfig.DLQ_NOTIFICATION)).thenReturn(dlqProps);
        when(rabbitAdmin.getQueueProperties(RabbitMqConfig.QUEUE_NOTIFICATION)).thenReturn(mainProps);

        Map<String, Object> stats = opsService.getDlqStats();

        assertNotNull(stats);
        assertEquals(5L, stats.get("dlqMessageCount"));
        assertEquals(20L, stats.get("mainQueueMessageCount"));
        assertEquals("notification-service-dlq", stats.get("dlqQueue"));
        assertEquals("notification-push-group", stats.get("kafkaConsumerGroup"));
    }

    @Test
    @DisplayName("Thực hiện thử lại tin nhắn từ DLQ thành công")
    void retryDlqMessages_success() {
        Message mockMsg1 = mock(Message.class);
        Message mockMsg2 = mock(Message.class);

        when(rabbitTemplate.receive(RabbitMqConfig.DLQ_NOTIFICATION))
                .thenReturn(mockMsg1, mockMsg2, null);

        Properties dlqProps = new Properties();
        dlqProps.put(RabbitAdmin.QUEUE_MESSAGE_COUNT, 0);
        when(rabbitAdmin.getQueueProperties(RabbitMqConfig.DLQ_NOTIFICATION)).thenReturn(dlqProps);

        Map<String, Object> result = opsService.retryDlqMessages(10, "manager-01");

        assertNotNull(result);
        assertEquals(2, result.get("reprocessedCount"));
        assertEquals(0L, result.get("remainingCount"));

        verify(rabbitTemplate, times(2)).send(eq(RabbitMqConfig.QUEUE_NOTIFICATION), any(Message.class));
    }

    @Test
    @DisplayName("Xóa sạch DLQ (purge) thành công")
    void purgeDlq_success() {
        Map<String, Object> result = opsService.purgeDlq("manager-01");

        assertNotNull(result);
        assertEquals(true, result.get("purged"));
        verify(rabbitAdmin, times(1)).purgeQueue(RabbitMqConfig.DLQ_NOTIFICATION, false);
    }

    @Test
    @DisplayName("Kiểm tra sức khỏe các nhà cung cấp thông báo (Provider Health)")
    void getProviderHealth_success() {
        when(deviceTokenRepository.countByActiveTrue()).thenReturn(42L);
        when(rabbitAdmin.getQueueProperties(RabbitMqConfig.QUEUE_NOTIFICATION)).thenReturn(new Properties());

        Map<String, Object> health = opsService.getProviderHealth();

        assertNotNull(health);
        assertTrue(health.containsKey("fcm"));
        assertTrue(health.containsKey("websocket"));
        assertTrue(health.containsKey("rabbitmq"));
        assertTrue(health.containsKey("kafka"));

        @SuppressWarnings("unchecked")
        Map<String, Object> fcm = (Map<String, Object>) health.get("fcm");
        assertEquals(42L, fcm.get("registeredDeviceTokens"));
    }

    @Test
    @DisplayName("Gửi thông báo chẩn đoán thử nghiệm (Test Push)")
    void sendTestNotification_success() {
        TestPushRequest request = new TestPushRequest("user-01", "Kiểm tra", "Nội dung thử nghiệm", "ALL");

        Map<String, Object> result = opsService.sendTestNotification(request, "manager-01");

        assertNotNull(result);
        assertEquals(true, result.get("success"));
        assertEquals("user-01", result.get("targetUserId"));

        verify(notificationService, times(1)).save(any());
        verify(webSocketNotifier, times(1)).pushToUser(eq("user-01"), any());
        verify(fcmPushSender, times(1)).sendPushNotification(eq("user-01"), anyString(), anyString(), anyMap());
    }
}
