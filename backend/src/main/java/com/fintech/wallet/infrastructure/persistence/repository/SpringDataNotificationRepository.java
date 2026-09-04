package com.fintech.wallet.infrastructure.persistence.repository;

import com.fintech.wallet.infrastructure.persistence.entity.NotificationEntity;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

@Repository
public interface SpringDataNotificationRepository extends JpaRepository<NotificationEntity, String> {

    Page<NotificationEntity> findByUserId(String userId, Pageable pageable);

    Page<NotificationEntity> findByUserIdAndType(String userId, String type, Pageable pageable);

    @Transactional
    @Modifying
    @Query("UPDATE NotificationEntity n SET n.isRead = true WHERE n.userId = :userId AND n.id = :notificationId")
    void markAsRead(@Param("userId") String userId, @Param("notificationId") String notificationId);

    @Transactional
    @Modifying
    @Query("UPDATE NotificationEntity n SET n.isRead = true WHERE n.userId = :userId AND (:type IS NULL OR n.type = :type)")
    void markAllAsRead(@Param("userId") String userId, @Param("type") String type);
}
