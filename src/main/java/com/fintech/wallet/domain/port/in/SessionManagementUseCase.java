package com.fintech.wallet.domain.port.in;

import com.fintech.wallet.domain.model.DeviceSession;
import java.util.List;
import java.util.Optional;

public interface SessionManagementUseCase {
    DeviceSession createOrUpdateSession(String userId, String deviceId, String ipAddress, String userAgent);
    Optional<DeviceSession> validateSession(String userId, String deviceId);
    DeviceSession refreshSession(String refreshToken, String ipAddress);
    void revokeSession(String userId, String deviceId);
    void revokeAllSessions(String userId);
    List<DeviceSession> getActiveSessions(String userId);
    void updateFcmToken(String userId, String deviceId, String fcmToken);
}
