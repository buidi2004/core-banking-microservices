package com.fintech.notification.repository;

import com.fintech.notification.entity.Notification;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.UUID;

@Repository
public interface NotificationRepository extends JpaRepository<Notification, UUID> {

    Page<Notification> findByUserId(String userId, Pageable pageable);

    Page<Notification> findByUserIdAndType(String userId, String type, Pageable pageable);

    long countByUserIdAndReadFalse(String userId);

    @Transactional
    @Modifying
    @Query("UPDATE Notification n SET n.read = true, n.readAt = :readAt "
            + "WHERE n.userId = :userId AND n.id = :id")
    int markAsRead(@Param("userId") String userId, @Param("id") UUID id, @Param("readAt") Instant readAt);

    @Transactional
    @Modifying
    @Query("UPDATE Notification n SET n.read = true, n.readAt = :readAt "
            + "WHERE n.userId = :userId AND (:type IS NULL OR n.type = :type)")
    int markAllAsRead(@Param("userId") String userId, @Param("type") String type, @Param("readAt") Instant readAt);
}
