package com.fintech.wallet.infrastructure.persistence.adapter;

import com.fintech.wallet.domain.model.OutboxEvent;
import com.fintech.wallet.domain.port.out.OutboxEventPersistencePort;
import com.fintech.wallet.infrastructure.persistence.entity.OutboxEventJpaEntity;
import com.fintech.wallet.infrastructure.persistence.mapper.OutboxEventMapper;
import com.fintech.wallet.infrastructure.persistence.repository.SpringDataOutboxEventRepository;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.stream.Collectors;

@Component
public class OutboxEventPersistenceAdapter implements OutboxEventPersistencePort {

    private final SpringDataOutboxEventRepository repository;

    public OutboxEventPersistenceAdapter(SpringDataOutboxEventRepository repository) {
        this.repository = repository;
    }

    @Override
    public OutboxEvent saveOutboxEvent(OutboxEvent event) {
        OutboxEventJpaEntity entity = OutboxEventMapper.toEntity(event);
        entity = repository.save(entity);
        return OutboxEventMapper.toDomain(entity);
    }

    @Override
    public List<OutboxEvent> findPendingEvents() {
        return repository.findByStatusOrderByCreatedAtAsc(OutboxEvent.OutboxEventStatus.PENDING.name())
                .stream()
                .map(OutboxEventMapper::toDomain)
                .collect(Collectors.toList());
    }

    @Override
    public List<OutboxEvent> findPendingEventsWithLock() {
        return repository.findPendingWithLock(OutboxEvent.OutboxEventStatus.PENDING.name())
                .stream()
                .map(OutboxEventMapper::toDomain)
                .collect(Collectors.toList());
    }
}
