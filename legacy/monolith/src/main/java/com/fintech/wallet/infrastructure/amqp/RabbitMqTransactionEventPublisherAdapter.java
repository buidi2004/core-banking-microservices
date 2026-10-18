package com.fintech.wallet.infrastructure.amqp;

import com.fintech.wallet.domain.model.TransactionEvent;
import com.fintech.wallet.domain.port.out.TransactionEventPublisherPort;
import com.fintech.wallet.infrastructure.config.RabbitMqConfig;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.stereotype.Component;

@Component
public class RabbitMqTransactionEventPublisherAdapter implements TransactionEventPublisherPort {

    private static final Logger log = LoggerFactory.getLogger(RabbitMqTransactionEventPublisherAdapter.class);

    private final RabbitTemplate rabbitTemplate;

    public RabbitMqTransactionEventPublisherAdapter(RabbitTemplate rabbitTemplate) {
        this.rabbitTemplate = rabbitTemplate;
    }

    @Override
    public void publishTransactionEvent(TransactionEvent event) {
        String routingKey = "transaction." + event.getType().toLowerCase();
        log.info("Publishing TransactionEvent to RabbitMQ: eventId={}, txId={}, routingKey={}", 
                event.getEventId(), event.getTransactionId(), routingKey);
        
        rabbitTemplate.convertAndSend(RabbitMqConfig.EXCHANGE_NAME, routingKey, event);
        log.info("Successfully published TransactionEvent to RabbitMQ: eventId={}, txId={}", 
                event.getEventId(), event.getTransactionId());
    }
}

