package com.fintech.identity.repository;

import com.fintech.identity.domain.entity.UserSessionEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

@Repository
public interface UserSessionRepository extends JpaRepository<UserSessionEntity, String> {

    Optional<UserSessionEntity> findByUserIdAndDeviceId(String userId, String deviceId);

    Optional<UserSessionEntity> findByRefreshTokenHash(String refreshTokenHash);

    List<UserSessionEntity> findByUserIdAndIsRevokedFalse(String userId);

    void deleteByExpiresAtBefore(Instant cutoff);
}
