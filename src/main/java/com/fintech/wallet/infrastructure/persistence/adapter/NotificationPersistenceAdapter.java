package com.fintech.wallet.infrastructure.persistence.adapter;

import com.fintech.wallet.domain.model.NotificationInfo;
import com.fintech.wallet.domain.model.NotificationType;
import com.fintech.wallet.domain.port.out.NotificationQueryPort;
import com.fintech.wallet.infrastructure.persistence.entity.NotificationEntity;
import com.fintech.wallet.infrastructure.persistence.repository.SpringDataNotificationRepository;
import com.fintech.wallet.presentation.response.PageResponse;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.stream.Collectors;

@Component
public class NotificationPersistenceAdapter implements NotificationQueryPort {

    private final SpringDataNotificationRepository repository;

    public NotificationPersistenceAdapter(SpringDataNotificationRepository repository) {
        this.repository = repository;
    }

    @Override
    public PageResponse<NotificationInfo> getNotifications(String userId, String type, int page, int size) {
        PageRequest pageRequest = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<NotificationEntity> entityPage;
        
        if (type != null && !type.isBlank()) {
            entityPage = repository.findByUserIdAndType(userId, type, pageRequest);
        } else {
            entityPage = repository.findByUserId(userId, pageRequest);
        }

        List<NotificationInfo> content = entityPage.getContent().stream()
                .map(this::mapToDomain)
                .collect(Collectors.toList());

        return PageResponse.of(content, page, size, entityPage.getTotalElements());
    }

    @Override
    public void saveNotification(NotificationInfo notification) {
        NotificationEntity entity = new NotificationEntity(
                notification.getId(),
                notification.getUserId(),
                notification.getType().name(),
                notification.getTitle(),
                notification.getContent(),
                notification.isRead(),
                notification.getCreatedAt(),
                notification.getMetadata()
        );
        repository.save(entity);
    }

    @Override
    public void markAsRead(String userId, String notificationId) {
        repository.markAsRead(userId, notificationId);
    }

    @Override
    public void markAllAsRead(String userId, String type) {
        repository.markAllAsRead(userId, type);
    }

    private NotificationInfo mapToDomain(NotificationEntity entity) {
        NotificationType enumType;
        try {
            enumType = NotificationType.valueOf(entity.getType());
        } catch (IllegalArgumentException e) {
            enumType = NotificationType.SYSTEM;
        }

        return new NotificationInfo(
                entity.getId(),
                entity.getUserId(),
                entity.getTitle(),
                entity.getBody(),
                enumType,
                entity.isRead(),
                entity.getCreatedAt(),
                entity.getMetadata()
        );
    }
}
