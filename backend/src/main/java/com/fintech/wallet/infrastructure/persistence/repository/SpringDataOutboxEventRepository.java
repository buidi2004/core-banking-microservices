package com.fintech.wallet.infrastructure.persistence.repository;

import com.fintech.wallet.infrastructure.persistence.entity.OutboxEventJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

@Repository
public interface SpringDataOutboxEventRepository extends JpaRepository<OutboxEventJpaEntity, String> {
    List<OutboxEventJpaEntity> findByStatusOrderByCreatedAtAsc(String status);
    
    @Query(value = "SELECT * FROM outbox_events WHERE status = :status ORDER BY created_at ASC LIMIT 100 FOR UPDATE SKIP LOCKED", nativeQuery = true)
    List<OutboxEventJpaEntity> findPendingWithLock(@Param("status") String status);
}
