package com.fintech.wallet.infrastructure.notification;

import com.fintech.wallet.domain.port.out.FcmNotificationPort;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.util.Map;

@Component
public class MockFcmNotificationAdapter implements FcmNotificationPort {

    private static final Logger log = LoggerFactory.getLogger(MockFcmNotificationAdapter.class);

    @Override
    public void sendPushNotification(String userId, String title, String body) {
        log.info("Mock FCM Push Notification to userId={}: [{}] - {}", userId, title, body);
    }

    @Override
    public void sendPushNotification(String userId, String title, String body, Map<String, String> data) {
        log.info("Mock FCM Push Notification to userId={}: [{}] - {} | data={}", userId, title, body, data);
    }
}

