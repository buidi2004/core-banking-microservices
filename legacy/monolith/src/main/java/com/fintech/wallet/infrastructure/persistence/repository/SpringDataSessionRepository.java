package com.fintech.wallet.infrastructure.persistence.repository;

import com.fintech.wallet.infrastructure.persistence.entity.SessionEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface SpringDataSessionRepository extends JpaRepository<SessionEntity, String> {

    Optional<SessionEntity> findByUserIdAndDeviceId(String userId, String deviceId);

    Optional<SessionEntity> findByRefreshToken(String refreshToken);

    List<SessionEntity> findByUserIdAndIsActiveTrue(String userId);

    @Modifying
    @Query("UPDATE SessionEntity s SET s.isActive = false, s.refreshToken = null, s.fcmToken = null, s.lastActiveAt = :now WHERE s.userId = :userId")
    void revokeAllSessionsForUser(@Param("userId") String userId, @Param("now") java.time.Instant now);
}
