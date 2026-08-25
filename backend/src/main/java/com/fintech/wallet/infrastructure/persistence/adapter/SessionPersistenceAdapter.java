package com.fintech.wallet.infrastructure.persistence.adapter;

import com.fintech.wallet.domain.model.DeviceSession;
import com.fintech.wallet.domain.port.out.SessionPersistencePort;
import com.fintech.wallet.infrastructure.persistence.entity.SessionEntity;
import com.fintech.wallet.infrastructure.persistence.repository.SpringDataSessionRepository;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Component
public class SessionPersistenceAdapter implements SessionPersistencePort {

    private final SpringDataSessionRepository repository;

    public SessionPersistenceAdapter(SpringDataSessionRepository repository) {
        this.repository = repository;
    }

    @Override
    public void save(DeviceSession session) {
        SessionEntity entity = new SessionEntity(
                session.getId(),
                session.getUserId(),
                session.getDeviceId(),
                session.getFcmToken(),
                session.getRefreshToken(),
                session.getIpAddress(),
                session.getUserAgent(),
                session.isActive(),
                session.getCreatedAt(),
                session.getLastActiveAt(),
                session.getExpiresAt()
        );
        repository.save(entity);
    }

    @Override
    public Optional<DeviceSession> findByUserIdAndDeviceId(String userId, String deviceId) {
        return repository.findByUserIdAndDeviceId(userId, deviceId)
                .map(this::mapToDomain);
    }

    @Override
    public Optional<DeviceSession> findByRefreshToken(String refreshToken) {
        return repository.findByRefreshToken(refreshToken)
                .map(this::mapToDomain);
    }

    @Override
    public List<DeviceSession> findActiveSessionsByUserId(String userId) {
        return repository.findByUserIdAndIsActiveTrue(userId).stream()
                .map(this::mapToDomain)
                .collect(Collectors.toList());
    }

    @Override
    public void revokeAllSessionsForUser(String userId) {
        repository.revokeAllSessionsForUser(userId, java.time.Instant.now());
    }

    private DeviceSession mapToDomain(SessionEntity entity) {
        return new DeviceSession(
                entity.getId(),
                entity.getUserId(),
                entity.getDeviceId(),
                entity.getFcmToken(),
                entity.getRefreshToken(),
                entity.getIpAddress(),
                entity.getUserAgent(),
                entity.isActive(),
                entity.getCreatedAt(),
                entity.getLastActiveAt(),
                entity.getExpiresAt()
        );
    }
}
