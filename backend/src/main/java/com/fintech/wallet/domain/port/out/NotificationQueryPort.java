package com.fintech.wallet.domain.port.out;

import com.fintech.wallet.domain.model.NotificationInfo;
import com.fintech.wallet.presentation.response.PageResponse;

public interface NotificationQueryPort {
    PageResponse<NotificationInfo> getNotifications(String userId, String type, int page, int size);
    void saveNotification(NotificationInfo notification);
    void markAsRead(String userId, String notificationId);
    void markAllAsRead(String userId, String type);
}
