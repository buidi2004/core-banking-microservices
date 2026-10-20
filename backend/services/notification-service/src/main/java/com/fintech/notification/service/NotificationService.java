package com.fintech.notification.service;

import com.fintech.notification.dto.PageResponse;
import com.fintech.notification.entity.Notification;
import com.fintech.notification.repository.NotificationRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class NotificationService {

    private static final Logger log = LoggerFactory.getLogger(NotificationService.class);

    private final NotificationRepository notificationRepository;
    private final Map<String, Map<String, Boolean>> settingsStore = new ConcurrentHashMap<>();

    public NotificationService(NotificationRepository notificationRepository) {
        this.notificationRepository = notificationRepository;
    }

    public PageResponse<Notification> getNotifications(String userId, String type, int page, int size) {
        PageRequest pageRequest = PageRequest.of(Math.max(page, 0), size > 0 ? size : 20,
                Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<Notification> result = (type != null && !type.isBlank())
                ? notificationRepository.findByUserIdAndType(userId, type, pageRequest)
                : notificationRepository.findByUserId(userId, pageRequest);
        return PageResponse.of(result.getContent(), page, pageRequest.getPageSize(), result.getTotalElements());
    }

    @Transactional
    public void markAsRead(String userId, String notificationId) {
        notificationRepository.markAsRead(userId, UUID.fromString(notificationId), Instant.now());
    }

    @Transactional
    public void markAllAsRead(String userId, String type) {
        String filter = (type == null || type.isBlank()) ? null : type;
        notificationRepository.markAllAsRead(userId, filter, Instant.now());
    }

    /** Kiểm tra notification của giao dịch đã tồn tại chưa (chống trùng khi Rabbit/Kafka cùng giao). */
    public boolean existsForTransaction(String userId, String transactionId, String status) {
        if (userId == null || userId.isBlank() || transactionId == null || transactionId.isBlank()) {
            return false;
        }
        return notificationRepository.countByUserAndTransaction(userId, transactionId,
                (status == null || status.isBlank()) ? "SUCCESS" : status.toUpperCase()) > 0;
    }

    @Transactional
    public Notification save(Notification notification) {
        return notificationRepository.save(notification);
    }

    public long countUnread(String userId) {
        return notificationRepository.countByUserIdAndReadFalse(userId);
    }

    public void updateSettings(String userId, boolean transactionEnabled, boolean promoEnabled) {
        Map<String, Boolean> userSettings = settingsStore.computeIfAbsent(userId, k -> new ConcurrentHashMap<>());
        userSettings.put("TRANSACTION", transactionEnabled);
        userSettings.put("PROMO", promoEnabled);
        log.info("Updated notification settings for user={}: transaction={}, promo={}",
                userId, transactionEnabled, promoEnabled);
    }
}
