package com.fintech.notification.repository;

import com.fintech.notification.entity.DeviceToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface DeviceTokenRepository extends JpaRepository<DeviceToken, UUID> {

    Optional<DeviceToken> findByToken(String token);

    List<DeviceToken> findByUserId(String userId);

    List<DeviceToken> findByUserIdAndActiveTrue(String userId);

    void deleteByToken(String token);
}
