package com.fintech.ledger.infrastructure.persistence.repository;

import com.fintech.ledger.infrastructure.persistence.entity.AuditLogJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface SpringAuditLogRepository extends JpaRepository<AuditLogJpaEntity, java.util.UUID> {
    List<AuditLogJpaEntity> findTop500ByOrderByPerformedAtDesc();
    List<AuditLogJpaEntity> findTop500ByPerformedByOrderByPerformedAtDesc(String performedBy);
    List<AuditLogJpaEntity> findTop500ByEntityTypeAndEntityIdOrderByPerformedAtDesc(
            String entityType, String entityId);
    List<AuditLogJpaEntity> findTop500ByCorrelationIdOrderByPerformedAtDesc(String correlationId);
}
