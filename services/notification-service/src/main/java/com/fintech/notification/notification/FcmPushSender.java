package com.fintech.notification.notification;

import com.fintech.notification.entity.DeviceToken;
import com.fintech.notification.repository.DeviceTokenRepository;
import com.google.firebase.FirebaseApp;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.MessagingErrorCode;
import com.google.firebase.messaging.Notification;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Component
public class FcmPushSender {

    private static final Logger log = LoggerFactory.getLogger(FcmPushSender.class);

    private final DeviceTokenRepository deviceTokenRepository;

    public FcmPushSender(DeviceTokenRepository deviceTokenRepository) {
        this.deviceTokenRepository = deviceTokenRepository;
    }

    @Transactional
    public void sendPushNotification(String userId, String title, String body, Map<String, String> data) {
        if (userId == null || userId.isBlank()) {
            log.warn("Cannot send FCM push: userId is blank");
            return;
        }

        List<DeviceToken> tokens = deviceTokenRepository.findByUserIdAndActiveTrue(userId);
        if (tokens.isEmpty()) {
            log.info("No active FCM device tokens for userId={}. Skipping push.", userId);
            return;
        }

        if (FirebaseApp.getApps().isEmpty()) {
            log.info("FirebaseApp not initialized. Mock FCM push to userId={} ({} tokens): [{}] {} | data={}",
                    userId, tokens.size(), title, body, data);
            return;
        }

        Notification notification = Notification.builder()
                .setTitle(title)
                .setBody(body)
                .build();

        for (DeviceToken deviceToken : tokens) {
            dispatch(deviceToken, notification, data);
        }
    }

    private void dispatch(DeviceToken deviceToken, Notification notification, Map<String, String> data) {
        String token = deviceToken.getToken();
        if (token == null || token.isBlank()) {
            return;
        }
        try {
            Message.Builder builder = Message.builder()
                    .setToken(token)
                    .setNotification(notification);
            if (data != null && !data.isEmpty()) {
                Map<String, String> safeData = new LinkedHashMap<>();
                data.forEach((k, v) -> {
                    if (k != null && v != null) {
                        safeData.put(k, v);
                    }
                });
                builder.putAllData(safeData);
            }
            String messageId = FirebaseMessaging.getInstance().send(builder.build());
            log.info("FCM push SUCCESS: userId={}, platform={}, messageId={}",
                    deviceToken.getUserId(), deviceToken.getPlatform(), messageId);
        } catch (FirebaseMessagingException e) {
            MessagingErrorCode errorCode = e.getMessagingErrorCode();
            log.warn("FCM push FAILED: userId={}, platform={}, error={} message={}",
                    deviceToken.getUserId(), deviceToken.getPlatform(), errorCode, e.getMessage());
            if (isUnregisteredOrInvalid(e)) {
                deviceTokenRepository.deleteByToken(token);
                log.info("Pruned unregistered/invalid FCM token for userId={}", deviceToken.getUserId());
            }
        } catch (Exception e) {
            log.error("Unexpected error sending FCM message (userId={})", deviceToken.getUserId(), e);
        }
    }

    private boolean isUnregisteredOrInvalid(FirebaseMessagingException e) {
        if (e.getMessagingErrorCode() == MessagingErrorCode.UNREGISTERED
                || e.getMessagingErrorCode() == MessagingErrorCode.INVALID_ARGUMENT) {
            return true;
        }
        String msg = e.getMessage() != null ? e.getMessage().toLowerCase() : "";
        return msg.contains("unregistered")
                || msg.contains("invalidregistration")
                || msg.contains("registration-token-not-registered")
                || msg.contains("invalid-registration-token");
    }
}
