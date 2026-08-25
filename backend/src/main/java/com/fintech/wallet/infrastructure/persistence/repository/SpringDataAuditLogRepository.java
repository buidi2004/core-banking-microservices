package com.fintech.wallet.infrastructure.persistence.repository;

import com.fintech.wallet.infrastructure.persistence.entity.AuditLogJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SpringDataAuditLogRepository extends JpaRepository<AuditLogJpaEntity, String> {
}
