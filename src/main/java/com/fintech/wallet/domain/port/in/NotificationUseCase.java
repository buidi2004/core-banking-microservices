package com.fintech.wallet.domain.port.in;

import com.fintech.wallet.domain.model.DeviceToken;
import com.fintech.wallet.domain.model.NotificationInfo;

import java.util.List;

public interface NotificationUseCase {
    List<NotificationInfo> getNotifications(String userId, int page, int size);
    void markAsRead(String userId, String notificationId);
    void markAllAsRead(String userId);
    DeviceToken registerDeviceToken(String userId, String deviceId, String fcmToken);
    void unregisterDeviceToken(String userId, String deviceId);
    void updateSettings(String userId, boolean transactionEnabled, boolean promoEnabled);
}
