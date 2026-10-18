package com.fintech.wallet.infrastructure.persistence.repository;

import com.fintech.wallet.infrastructure.persistence.entity.DeviceTokenEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Repository
public interface SpringDataDeviceTokenRepository extends JpaRepository<DeviceTokenEntity, String> {

    List<DeviceTokenEntity> findByUserId(String userId);

    Optional<DeviceTokenEntity> findByFcmToken(String fcmToken);

    @Transactional
    @Modifying
    @Query("DELETE FROM DeviceTokenEntity d WHERE d.fcmToken = :fcmToken")
    void deleteByFcmToken(@Param("fcmToken") String fcmToken);

    @Transactional
    @Modifying
    @Query("DELETE FROM DeviceTokenEntity d WHERE d.userId = :userId AND d.fcmToken = :fcmToken")
    void deleteByUserIdAndFcmToken(@Param("userId") String userId, @Param("fcmToken") String fcmToken);
}
