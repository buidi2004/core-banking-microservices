package com.fintech.wallet.domain.port.out;

import com.fintech.wallet.domain.model.DeviceToken;

import java.util.List;
import java.util.Optional;

public interface DeviceTokenPersistencePort {

    DeviceToken save(DeviceToken deviceToken);

    Optional<DeviceToken> findByFcmToken(String fcmToken);

    List<DeviceToken> findByUserId(String userId);

    void deleteByFcmToken(String fcmToken);

    void deleteByUserIdAndFcmToken(String userId, String fcmToken);
}
