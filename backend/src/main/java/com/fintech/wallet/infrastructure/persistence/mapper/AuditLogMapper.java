package com.fintech.wallet.infrastructure.persistence.mapper;

import com.fintech.wallet.domain.model.AuditLog;
import com.fintech.wallet.infrastructure.persistence.entity.AuditLogJpaEntity;
import org.springframework.stereotype.Component;

@Component
public class AuditLogMapper {

    public AuditLog toDomain(AuditLogJpaEntity entity) {
        if (entity == null) return null;
        return new AuditLog(
                entity.getId(),
                entity.getCallerId(),
                entity.getIpAddress(),
                entity.getAction(),
                entity.getPayloadHash(),
                entity.getIdempotencyKey(),
                entity.getCreatedAt()
        );
    }

    public AuditLogJpaEntity toJpaEntity(AuditLog domain) {
        if (domain == null) return null;
        return new AuditLogJpaEntity(
                domain.getId(),
                domain.getCallerId(),
                domain.getIpAddress(),
                domain.getAction(),
                domain.getPayloadHash(),
                domain.getIdempotencyKey(),
                domain.getCreatedAt()
        );
    }
}
