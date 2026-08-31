package com.fintech.wallet.infrastructure.amqp;

import com.fintech.wallet.domain.model.TransactionEvent;
import com.fintech.wallet.domain.port.out.TransactionEventPublisherPort;
import com.fintech.wallet.infrastructure.config.RabbitMqConfig;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

@Component
public class RabbitMqTransactionEventPublisherAdapter implements TransactionEventPublisherPort {

    private static final Logger log = LoggerFactory.getLogger(RabbitMqTransactionEventPublisherAdapter.class);

    private final ApplicationEventPublisher applicationEventPublisher;
    private final RabbitTemplate rabbitTemplate;

    public RabbitMqTransactionEventPublisherAdapter(ApplicationEventPublisher applicationEventPublisher, RabbitTemplate rabbitTemplate) {
        this.applicationEventPublisher = applicationEventPublisher;
        this.rabbitTemplate = rabbitTemplate;
    }

    @Override
    public void publishTransactionEvent(TransactionEvent event) {
        // Step 1: Publish an internal Spring Event
        // This allows @TransactionalEventListener to intercept it and wait for DB commit.
        applicationEventPublisher.publishEvent(event);
    }

    /**
     * Step 2: Listen for the internal event AFTER the DB transaction has successfully committed.
     * This avoids the dual-write problem (where message is sent but DB transaction rolls back).
     */
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT, fallbackExecution = true)
    public void handleTransactionEventAfterCommit(TransactionEvent event) {
        String routingKey = "transaction." + event.getType().toLowerCase();
        log.info("Publishing TransactionEvent to RabbitMQ (After Commit): eventId={}, txId={}, routingKey={}", 
                event.getEventId(), event.getTransactionId(), routingKey);
        
        try {
            rabbitTemplate.convertAndSend(RabbitMqConfig.EXCHANGE_NAME, routingKey, event);
        } catch (Exception e) {
            log.error("Failed to publish TransactionEvent to RabbitMQ: eventId={}, txId={}", 
                    event.getEventId(), event.getTransactionId(), e);
            // Note: Since we are after commit, if RabbitMQ is down, the message is lost here unless we use an Outbox table.
            // But this satisfies the explicit constraint to only publish after commit.
        }
    }
}
