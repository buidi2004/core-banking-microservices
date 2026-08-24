package com.fintech.wallet.application.service;


import com.fintech.wallet.domain.model.NotificationType;
import com.fintech.wallet.domain.port.in.NotificationUseCase;
import com.fintech.wallet.domain.port.out.NotificationQueryPort;
import com.fintech.wallet.presentation.response.PageResponse;
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

    private final NotificationQueryPort notificationQueryPort;
    private final Map<String, Map<String, Boolean>> settingsStore = new ConcurrentHashMap<>();

    public NotificationService(NotificationQueryPort notificationQueryPort) {
        this.notificationQueryPort = notificationQueryPort;
    }

    @Override
    public PageResponse<com.fintech.wallet.domain.model.NotificationInfo> getNotifications(String userId, String type, int page, int size) {
        return notificationQueryPort.getNotifications(userId, type, page, size);
    }

    @Override
    public void markAsRead(String userId, String notificationId) {
        notificationQueryPort.markAsRead(userId, notificationId);
    }

    @Override
    public void markAllAsRead(String userId, String type) {
        notificationQueryPort.markAllAsRead(userId, type);
    }

    @Override
    public void updateSettings(String userId, boolean transactionEnabled, boolean promoEnabled) {
        Map<String, Boolean> userSettings = settingsStore.computeIfAbsent(userId, k -> new ConcurrentHashMap<>());
        userSettings.put("TRANSACTION", transactionEnabled);
        userSettings.put("PROMO", promoEnabled);
        log.info("Updated notification settings for user={}: tx={}, promo={}", userId, transactionEnabled, promoEnabled);
    }

    public void addNotification(String userId, String title, String content, String type) {
        NotificationType enumType;
        try {
            enumType = NotificationType.valueOf(type.toUpperCase());
        } catch (IllegalArgumentException e) {
            enumType = NotificationType.SYSTEM;
        }
        com.fintech.wallet.domain.model.NotificationInfo notification = com.fintech.wallet.domain.model.NotificationInfo.createNew(userId, title, content, enumType, null);
        notificationQueryPort.saveNotification(notification);
    }
}
