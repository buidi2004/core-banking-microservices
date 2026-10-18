package com.fintech.payment.repository;

import com.fintech.payment.domain.entity.OutboxEvent;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface OutboxEventRepository extends JpaRepository<OutboxEvent, String> {

    @Query("SELECT o FROM OutboxEvent o WHERE o.status = 'PENDING' ORDER BY o.createdAt ASC")
    List<OutboxEvent> findPendingByCreatedAtAsc();

    @Query("SELECT o FROM OutboxEvent o WHERE o.status = 'PENDING' AND o.retryCount < :maxRetry ORDER BY o.createdAt ASC")
    List<OutboxEvent> findPendingRetryable(@Param("maxRetry") Integer maxRetry);

    boolean existsByAggregateTypeAndAggregateIdAndEventType(String aggregateType, String aggregateId, String eventType);
}
