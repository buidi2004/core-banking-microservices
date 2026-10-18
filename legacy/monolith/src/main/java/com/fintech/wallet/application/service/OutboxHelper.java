package com.fintech.wallet.application.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fintech.wallet.domain.model.OutboxEvent;
import com.fintech.wallet.domain.model.TransactionEvent;
import com.fintech.wallet.domain.port.out.OutboxEventPersistencePort;
import org.springframework.stereotype.Component;

@Component
public class OutboxHelper {
    private final OutboxEventPersistencePort outboxEventPersistencePort;
    private final ObjectMapper objectMapper;

    public OutboxHelper(OutboxEventPersistencePort outboxEventPersistencePort, ObjectMapper objectMapper) {
        this.outboxEventPersistencePort = outboxEventPersistencePort;
        this.objectMapper = objectMapper;
    }

    public void saveEvent(TransactionEvent event) {
        try {
            String payload = objectMapper.writeValueAsString(event);
            OutboxEvent outboxEvent = OutboxEvent.create("Transaction", event.getTransactionId(), event.getType(), payload);
            outboxEventPersistencePort.saveOutboxEvent(outboxEvent);
        } catch (Exception e) {
            throw new RuntimeException("Failed to serialize and save outbox event", e);
        }
    }
}
