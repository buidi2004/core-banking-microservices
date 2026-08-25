package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.model.DeviceSession;
import com.fintech.wallet.domain.port.in.SessionManagementUseCase;
import com.fintech.wallet.domain.port.out.SessionPersistencePort;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
public class SessionService implements SessionManagementUseCase {

    private final SessionPersistencePort sessionPersistencePort;

    public SessionService(SessionPersistencePort sessionPersistencePort) {
        this.sessionPersistencePort = sessionPersistencePort;
    }

    @Override
    public DeviceSession createOrUpdateSession(String userId, String deviceId, String ipAddress, String userAgent) {
        Optional<DeviceSession> existingOpt = sessionPersistencePort.findByUserIdAndDeviceId(userId, deviceId);
        
        DeviceSession session;
        if (existingOpt.isPresent()) {
            session = existingOpt.get();
            session.markActive();
        } else {
            Instant expiresAt = Instant.now().plus(30, ChronoUnit.DAYS); // 30 days expiry for refresh token
            session = DeviceSession.createNew(userId, deviceId, ipAddress, userAgent, expiresAt);
        }
        
        session.assignRefreshToken(UUID.randomUUID().toString());
        sessionPersistencePort.save(session);
        return session;
    }

    @Override
    public Optional<DeviceSession> validateSession(String userId, String deviceId) {
        return sessionPersistencePort.findByUserIdAndDeviceId(userId, deviceId)
                .filter(DeviceSession::isActive);
    }

    @Override
    public DeviceSession refreshSession(String refreshToken, String ipAddress) {
        Optional<DeviceSession> sessionOpt = sessionPersistencePort.findByRefreshToken(refreshToken);
        if (sessionOpt.isEmpty()) {
            throw new IllegalArgumentException("Invalid refresh token");
        }
        
        DeviceSession session = sessionOpt.get();
        if (!session.isActive()) {
            throw new IllegalStateException("Session is expired or revoked");
        }
        
        // Rotate refresh token
        session.assignRefreshToken(UUID.randomUUID().toString());
        session.markActive();
        sessionPersistencePort.save(session);
        return session;
    }

    @Override
    public void revokeSession(String userId, String deviceId) {
        sessionPersistencePort.findByUserIdAndDeviceId(userId, deviceId).ifPresent(session -> {
            session.revoke();
            sessionPersistencePort.save(session);
        });
    }

    @Override
    public void revokeAllSessions(String userId) {
        sessionPersistencePort.revokeAllSessionsForUser(userId);
    }

    @Override
    public List<DeviceSession> getActiveSessions(String userId) {
        return sessionPersistencePort.findActiveSessionsByUserId(userId);
    }

    @Override
    public void updateFcmToken(String userId, String deviceId, String fcmToken) {
        sessionPersistencePort.findByUserIdAndDeviceId(userId, deviceId).ifPresent(session -> {
            session.updateFcmToken(fcmToken);
            sessionPersistencePort.save(session);
        });
    }
}
