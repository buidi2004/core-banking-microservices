package com.fintech.wallet.infrastructure.notification;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

@Component
public class MockFcmNotificationAdapter {

    private static final Logger log = LoggerFactory.getLogger(MockFcmNotificationAdapter.class);

    public void sendPushNotification(String userId, String title, String body) {
        log.info("Mock FCM Push Notification to userId={}: [{}] - {}", userId, title, body);
    }
}
