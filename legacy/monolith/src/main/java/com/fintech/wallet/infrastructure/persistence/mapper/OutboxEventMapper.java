package com.fintech.wallet.infrastructure.persistence.mapper;

import com.fintech.wallet.domain.model.OutboxEvent;
import com.fintech.wallet.infrastructure.persistence.entity.OutboxEventJpaEntity;

public class OutboxEventMapper {

    public static OutboxEvent toDomain(OutboxEventJpaEntity entity) {
        if (entity == null) return null;
        return new OutboxEvent(
                entity.getId(),
                entity.getAggregateType(),
                entity.getAggregateId(),
                entity.getType(),
                entity.getPayload(),
                OutboxEvent.OutboxEventStatus.valueOf(entity.getStatus()),
                entity.getCreatedAt(),
                entity.getRetryCount()
        );
    }

    public static OutboxEventJpaEntity toEntity(OutboxEvent domain) {
        if (domain == null) return null;
        OutboxEventJpaEntity entity = new OutboxEventJpaEntity();
        entity.setId(domain.getId());
        entity.setAggregateType(domain.getAggregateType());
        entity.setAggregateId(domain.getAggregateId());
        entity.setType(domain.getType());
        entity.setPayload(domain.getPayload());
        entity.setStatus(domain.getStatus().name());
        entity.setCreatedAt(domain.getCreatedAt());
        entity.setRetryCount(domain.getRetryCount());
        return entity;
    }
}
