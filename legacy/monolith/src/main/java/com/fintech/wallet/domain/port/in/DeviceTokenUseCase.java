package com.fintech.wallet.domain.port.in;

import com.fintech.wallet.domain.model.DeviceToken;

public interface DeviceTokenUseCase {

    DeviceToken registerDeviceToken(String userId, String fcmToken, String deviceType);

    void unregisterDeviceToken(String userId, String fcmToken);
}
