package com.fintech.wallet.domain.port.out;

import java.util.Map;

public interface FcmNotificationPort {

    void sendPushNotification(String userId, String title, String body);

    default void sendPushNotification(String userId, String title, String body, Map<String, String> data) {
        sendPushNotification(userId, title, body);
    }
}

