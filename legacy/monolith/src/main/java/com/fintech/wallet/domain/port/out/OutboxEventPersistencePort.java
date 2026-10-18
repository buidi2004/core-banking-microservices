package com.fintech.wallet.domain.port.out;

import com.fintech.wallet.domain.model.OutboxEvent;

import java.util.List;

public interface OutboxEventPersistencePort {
    OutboxEvent saveOutboxEvent(OutboxEvent event);
    List<OutboxEvent> findPendingEvents();
    List<OutboxEvent> findPendingEventsWithLock();
}
