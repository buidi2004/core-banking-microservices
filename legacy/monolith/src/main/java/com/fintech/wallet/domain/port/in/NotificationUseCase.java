package com.fintech.wallet.domain.port.in;

import com.fintech.wallet.domain.model.DeviceToken;
import com.fintech.wallet.domain.model.NotificationInfo;

import java.util.List;

import com.fintech.wallet.presentation.response.PageResponse;

public interface NotificationUseCase {
    PageResponse<NotificationInfo> getNotifications(String userId, String type, int page, int size);
    void markAsRead(String userId, String notificationId);
    void markAllAsRead(String userId, String type);

    void updateSettings(String userId, boolean transactionEnabled, boolean promoEnabled);
}
