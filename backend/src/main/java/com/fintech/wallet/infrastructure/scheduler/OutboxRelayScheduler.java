package com.fintech.wallet.infrastructure.scheduler;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fintech.wallet.domain.model.OutboxEvent;
import com.fintech.wallet.domain.model.TransactionEvent;
import com.fintech.wallet.domain.port.out.OutboxEventPersistencePort;
import com.fintech.wallet.domain.port.out.TransactionEventPublisherPort;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import org.springframework.transaction.annotation.Transactional;
import java.util.List;

@Component
public class OutboxRelayScheduler {
    private static final Logger log = LoggerFactory.getLogger(OutboxRelayScheduler.class);
    private static final int MAX_RETRIES = 5;

    private final OutboxEventPersistencePort outboxEventPersistencePort;
    private final TransactionEventPublisherPort transactionEventPublisherPort;
    private final ObjectMapper objectMapper;

    public OutboxRelayScheduler(OutboxEventPersistencePort outboxEventPersistencePort,
                                TransactionEventPublisherPort transactionEventPublisherPort,
                                ObjectMapper objectMapper) {
        this.outboxEventPersistencePort = outboxEventPersistencePort;
        this.transactionEventPublisherPort = transactionEventPublisherPort;
        this.objectMapper = objectMapper;
    }

    @Scheduled(fixedDelay = 500) // Run every 500ms for lower notification latency
    @Transactional
    public void relayEvents() {
        List<OutboxEvent> pendingEvents = outboxEventPersistencePort.findPendingEventsWithLock();
        if (!pendingEvents.isEmpty()) {
            log.info("Found {} pending outbox events. Relaying to RabbitMQ...", pendingEvents.size());
        }

        for (OutboxEvent event : pendingEvents) {
            try {
                if ("Transaction".equals(event.getAggregateType())) {
                    TransactionEvent payload = objectMapper.readValue(event.getPayload(), TransactionEvent.class);
                    // Step 1: Synchronously publish to RabbitMQ. If broker is unreachable, this throws exception.
                    transactionEventPublisherPort.publishTransactionEvent(payload);
                    
                    // Step 2: ONLY after publish returns without error, mark PROCESSED.
                    event.markProcessed();
                    outboxEventPersistencePort.saveOutboxEvent(event);
                    log.info("Successfully relayed outbox event id={}, aggregateId={}", event.getId(), event.getAggregateId());
                }
            } catch (Exception e) {
                log.error("Failed to relay outbox event id={}, aggregateId={}: {}", event.getId(), event.getAggregateId(), e.getMessage());
                event.incrementRetryCount();
                if (event.getRetryCount() >= MAX_RETRIES) {
                    event.markFailed();
                    log.error("CRITICAL: Outbox event id={} aggregateId={} exceeded max retries ({}). Marked as FAILED (Dead Letter). Manual intervention required!", 
                            event.getId(), event.getAggregateId(), MAX_RETRIES);
                } else {
                    log.warn("Outbox event id={} will be retried on next schedule (retryCount={}/{})", 
                            event.getId(), event.getRetryCount(), MAX_RETRIES);
                }
                outboxEventPersistencePort.saveOutboxEvent(event);
            }
        }
    }
}
