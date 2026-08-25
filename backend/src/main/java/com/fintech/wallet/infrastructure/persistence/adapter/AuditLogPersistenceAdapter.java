package com.fintech.wallet.infrastructure.persistence.adapter;

import com.fintech.wallet.domain.model.AuditLog;
import com.fintech.wallet.domain.port.out.AuditLogPersistencePort;
import com.fintech.wallet.infrastructure.persistence.entity.AuditLogJpaEntity;
import com.fintech.wallet.infrastructure.persistence.mapper.AuditLogMapper;
import com.fintech.wallet.infrastructure.persistence.repository.SpringDataAuditLogRepository;
import org.springframework.stereotype.Component;

@Component
public class AuditLogPersistenceAdapter implements AuditLogPersistencePort {

    private final SpringDataAuditLogRepository repository;
    private final AuditLogMapper mapper;

    public AuditLogPersistenceAdapter(SpringDataAuditLogRepository repository, AuditLogMapper mapper) {
        this.repository = repository;
        this.mapper = mapper;
    }

    @Override
    public void saveAuditLog(AuditLog auditLog) {
        AuditLogJpaEntity entity = mapper.toJpaEntity(auditLog);
        repository.save(entity);
    }
}
