package com.fintech.notification.service;

import com.fintech.notification.entity.DeviceToken;
import com.fintech.notification.repository.DeviceTokenRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

@Service
public class DeviceTokenService {

    private static final Logger log = LoggerFactory.getLogger(DeviceTokenService.class);

    private final DeviceTokenRepository deviceTokenRepository;

    public DeviceTokenService(DeviceTokenRepository deviceTokenRepository) {
        this.deviceTokenRepository = deviceTokenRepository;
    }

    @Transactional
    public DeviceToken registerDeviceToken(String userId, String fcmToken, String deviceType,
                                           String deviceModel, String appVersion) {
        if (userId == null || userId.isBlank()) {
            throw new IllegalArgumentException("userId must not be blank");
        }
        if (fcmToken == null || fcmToken.isBlank()) {
            throw new IllegalArgumentException("fcmToken must not be blank");
        }
        String platform = (deviceType != null && !deviceType.isBlank())
                ? deviceType.toUpperCase()
                : "FCM";

        Optional<DeviceToken> existingOpt = deviceTokenRepository.findByToken(fcmToken);
        if (existingOpt.isPresent()) {
            DeviceToken existing = existingOpt.get();
            log.info("FCM token already registered. Reassigning owner from userId={} to userId={}",
                    existing.getUserId(), userId);
            existing.assignTo(userId, platform);
            return deviceTokenRepository.save(existing);
        }

        DeviceToken created = DeviceToken.create(userId, platform, fcmToken, deviceModel, appVersion);
        return deviceTokenRepository.save(created);
    }

    @Transactional
    public void unregisterDeviceToken(String userId, String fcmToken) {
        if (fcmToken == null || fcmToken.isBlank()) {
            log.warn("Cannot unregister empty FCM token for userId={}", userId);
            return;
        }
        deviceTokenRepository.findByToken(fcmToken)
                .filter(t -> t.getUserId().equals(userId))
                .ifPresent(deviceTokenRepository::delete);
    }
}
