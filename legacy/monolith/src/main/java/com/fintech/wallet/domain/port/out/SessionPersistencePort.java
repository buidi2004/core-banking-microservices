package com.fintech.wallet.domain.port.out;

import com.fintech.wallet.domain.model.DeviceSession;
import java.util.List;
import java.util.Optional;

public interface SessionPersistencePort {
    void save(DeviceSession session);
    Optional<DeviceSession> findByUserIdAndDeviceId(String userId, String deviceId);
    Optional<DeviceSession> findByRefreshToken(String refreshToken);
    List<DeviceSession> findActiveSessionsByUserId(String userId);
    void revokeAllSessionsForUser(String userId);
}
