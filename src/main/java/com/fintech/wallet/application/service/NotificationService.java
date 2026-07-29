package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.model.DeviceToken;
import com.fintech.wallet.domain.model.NotificationInfo;
import com.fintech.wallet.domain.port.in.NotificationUseCase;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;

@Service
public class NotificationService implements NotificationUseCase {

    private static final Logger log = LoggerFactory.getLogger(NotificationService.class);

    private final List<NotificationInfo> notificationsStore = new ArrayList<>();
    private final List<DeviceToken> deviceTokensStore = new ArrayList<>();
    private final Map<String, Map<String, Boolean>> settingsStore = new ConcurrentHashMap<>();

    @Override
    public List<NotificationInfo> getNotifications(String userId, int page, int size) {
        return notificationsStore.stream()
                .filter(n -> n.getUserId().equals(userId))
                .sorted((a, b) -> b.getCreatedAt().compareTo(a.getCreatedAt()))
                .skip((long) page * size)
                .limit(size)
                .collect(Collectors.toList());
    }

    @Override
    public void markAsRead(String userId, String notificationId) {
        notificationsStore.stream()
                .filter(n -> n.getUserId().equals(userId) && n.getId().equals(notificationId))
                .findFirst()
                .ifPresent(NotificationInfo::markAsRead);
    }

    @Override
    public void markAllAsRead(String userId) {
        notificationsStore.stream()
                .filter(n -> n.getUserId().equals(userId))
                .forEach(NotificationInfo::markAsRead);
    }

    @Override
    public DeviceToken registerDeviceToken(String userId, String deviceId, String fcmToken) {
        deviceTokensStore.removeIf(d -> d.getUserId().equals(userId) && d.getDeviceId().equals(deviceId));
        DeviceToken token = DeviceToken.createNew(userId, deviceId, fcmToken);
        deviceTokensStore.add(token);
        log.info("Registered FCM device token for user={}, device={}", userId, deviceId);
        return token;
    }

    @Override
    public void unregisterDeviceToken(String userId, String deviceId) {
        deviceTokensStore.removeIf(d -> d.getUserId().equals(userId) && d.getDeviceId().equals(deviceId));
        log.info("Unregistered FCM device token for user={}, device={}", userId, deviceId);
    }

    @Override
    public void updateSettings(String userId, boolean transactionEnabled, boolean promoEnabled) {
        Map<String, Boolean> userSettings = settingsStore.computeIfAbsent(userId, k -> new ConcurrentHashMap<>());
        userSettings.put("TRANSACTION", transactionEnabled);
        userSettings.put("PROMO", promoEnabled);
        log.info("Updated notification settings for user={}: tx={}, promo={}", userId, transactionEnabled, promoEnabled);
    }

    public void addNotification(String userId, String title, String content, String type) {
        notificationsStore.add(NotificationInfo.createNew(userId, title, content, type));
    }
}
