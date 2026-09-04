package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.model.DeviceToken;
import com.fintech.wallet.domain.port.in.DeviceTokenUseCase;
import com.fintech.wallet.domain.port.out.DeviceTokenPersistencePort;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

@Service
public class DeviceTokenService implements DeviceTokenUseCase {

    private static final Logger log = LoggerFactory.getLogger(DeviceTokenService.class);

    private final DeviceTokenPersistencePort deviceTokenPersistencePort;

    public DeviceTokenService(DeviceTokenPersistencePort deviceTokenPersistencePort) {
        this.deviceTokenPersistencePort = deviceTokenPersistencePort;
    }

    @Override
    @Transactional
    public DeviceToken registerDeviceToken(String userId, String fcmToken, String deviceType) {
        if (userId == null || userId.isBlank()) {
            throw new IllegalArgumentException("userId must not be blank");
        }
        if (fcmToken == null || fcmToken.isBlank()) {
            throw new IllegalArgumentException("fcmToken must not be blank");
        }
        String normalizedType = (deviceType != null && !deviceType.isBlank()) ? deviceType.toUpperCase() : "ANDROID";

        Optional<DeviceToken> existingOpt = deviceTokenPersistencePort.findByFcmToken(fcmToken);
        if (existingOpt.isPresent()) {
            DeviceToken existing = existingOpt.get();
            log.info("FCM token already exists. Updating owner from userId={} to userId={}, deviceType={}",
                    existing.getUserId(), userId, normalizedType);
            DeviceToken updated = existing.updateOwner(userId, normalizedType);
            return deviceTokenPersistencePort.save(updated);
        } else {
            log.info("Registering new FCM token for userId={}, deviceType={}", userId, normalizedType);
            DeviceToken newToken = DeviceToken.createNew(userId, fcmToken, normalizedType);
            return deviceTokenPersistencePort.save(newToken);
        }
    }

    @Override
    @Transactional
    public void unregisterDeviceToken(String userId, String fcmToken) {
        if (fcmToken == null || fcmToken.isBlank()) {
            log.warn("Cannot unregister empty FCM token for userId={}", userId);
            return;
        }
        log.info("Unregistering FCM token for userId={}", userId);
        deviceTokenPersistencePort.deleteByFcmToken(fcmToken);
    }
}
