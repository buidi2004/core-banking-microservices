package com.fintech.wallet.infrastructure.notification;

import com.fintech.wallet.domain.model.DeviceToken;
import com.fintech.wallet.domain.port.out.DeviceTokenPersistencePort;
import com.fintech.wallet.domain.port.out.FcmNotificationPort;
import com.google.firebase.FirebaseApp;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.MessagingErrorCode;
import com.google.firebase.messaging.Notification;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Primary;
import org.springframework.stereotype.Component;

import java.util.Collections;
import java.util.List;
import java.util.Map;

@Component
@Primary
public class FirebaseFcmNotificationAdapter implements FcmNotificationPort {

    private static final Logger log = LoggerFactory.getLogger(FirebaseFcmNotificationAdapter.class);

    private final DeviceTokenPersistencePort deviceTokenPersistencePort;
    private final com.fintech.wallet.domain.port.out.SessionPersistencePort sessionPersistencePort;

    public FirebaseFcmNotificationAdapter(DeviceTokenPersistencePort deviceTokenPersistencePort,
                                          com.fintech.wallet.domain.port.out.SessionPersistencePort sessionPersistencePort) {
        this.deviceTokenPersistencePort = deviceTokenPersistencePort;
        this.sessionPersistencePort = sessionPersistencePort;
    }

    @Override
    public void sendPushNotification(String userId, String title, String body) {
        sendPushNotification(userId, title, body, Collections.emptyMap());
    }

    @Override
    public void sendPushNotification(String userId, String title, String body, Map<String, String> data) {
        if (userId == null || userId.isBlank()) {
            log.warn("Cannot send FCM push: userId is blank");
            return;
        }

        // 1. Collect tokens from device_tokens table
        java.util.Map<String, String> tokenToDeviceType = new java.util.LinkedHashMap<>();
        try {
            for (DeviceToken dt : deviceTokenPersistencePort.findByUserId(userId)) {
                if (dt.getFcmToken() != null && !dt.getFcmToken().isBlank()) {
                    tokenToDeviceType.put(dt.getFcmToken(), dt.getDeviceType());
                }
            }
        } catch (Exception e) {
            log.error("Failed to query device tokens for userId={}", userId, e);
        }

        // 2. Also collect tokens from active device sessions (for backward-compatibility with /sessions/{deviceId}/fcm)
        try {
            for (com.fintech.wallet.domain.model.DeviceSession s : sessionPersistencePort.findActiveSessionsByUserId(userId)) {
                if (s.getFcmToken() != null && !s.getFcmToken().isBlank()) {
                    tokenToDeviceType.putIfAbsent(s.getFcmToken(), "ANDROID");
                }
            }
        } catch (Exception e) {
            log.error("Failed to query device sessions for userId={}", userId, e);
        }

        if (tokenToDeviceType.isEmpty()) {
            log.info("No registered FCM device tokens found for userId={}. Skipping push notification.", userId);
            return;
        }

        if (FirebaseApp.getApps().isEmpty()) {
            log.warn("FirebaseApp is not initialized. Mocking FCM Push to userId={} (found {} device tokens): [{}] {} | data={}",
                    userId, tokenToDeviceType.size(), title, body, data);
            return;
        }

        Notification notification = Notification.builder()
                .setTitle(title)
                .setBody(body)
                .build();

        for (Map.Entry<String, String> entry : tokenToDeviceType.entrySet()) {
            String token = entry.getKey();
            String deviceType = entry.getValue();
            try {
                Message.Builder messageBuilder = Message.builder()
                        .setToken(token)
                        .setNotification(notification);

                if (data != null && !data.isEmpty()) {
                    data.forEach((k, v) -> {
                        if (k != null && v != null) {
                            messageBuilder.putData(k, v);
                        }
                    });
                }

                Message message = messageBuilder.build();
                String messageId = FirebaseMessaging.getInstance().send(message);
                log.info("FCM push SUCCESS: token={} (deviceType={}, userId={}) messageId={}",
                        token, deviceType, userId, messageId);

            } catch (FirebaseMessagingException e) {
                MessagingErrorCode errorCode = e.getMessagingErrorCode();
                log.warn("FCM push FAILED for token={} (userId={}): [{}] {}", token, userId, errorCode, e.getMessage());

                if (isUnregisteredOrInvalid(e)) {
                    log.info("Pruning unregistered/invalid FCM token={} for userId={}", token, userId);
                    try {
                        deviceTokenPersistencePort.deleteByFcmToken(token);
                    } catch (Exception ex) {
                        log.error("Failed to delete stale FCM token={}", token, ex);
                    }
                }
            } catch (Exception e) {
                log.error("Unexpected error sending FCM message to token={} (userId={})", token, userId, e);
            }
        }
    }

    private boolean isUnregisteredOrInvalid(FirebaseMessagingException e) {
        if (e.getMessagingErrorCode() == MessagingErrorCode.UNREGISTERED) {
            return true;
        }
        if (e.getMessagingErrorCode() == MessagingErrorCode.INVALID_ARGUMENT) {
            return true;
        }
        String msg = e.getMessage() != null ? e.getMessage().toLowerCase() : "";
        return msg.contains("unregistered")
                || msg.contains("invalidregistration")
                || msg.contains("registration-token-not-registered")
                || msg.contains("invalid-registration-token");
    }
}

