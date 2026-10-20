package com.fintech.payment.outbox;

import com.fintech.payment.domain.entity.OutboxEvent;
import com.fintech.payment.repository.OutboxEventRepository;
import com.fintech.payment.kafka.PaymentKafkaProducer;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Outbox Relay: quét bảng outbox_events status='PENDING' và publish sự kiện
 * (bao gồm TRANSACTION_COMPLETED) lên RabbitMQ exchange wallet.exchange và
 * Kafka topic banking.payment.transaction-lifecycle.v1 (AGENT 3).
 *
 * Mẫu Transactional Outbox: sự kiện được lưu cùng DB transaction với business
 * entity, rồi relayador đưa qua message broker đảm bảo không mất sự kiện.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class OutboxRelay {

    private static final String DEFAULT_ROUTING_KEY = "transaction.completed";

    private final OutboxEventRepository outboxEventRepository;
    private final RabbitTemplate rabbitTemplate;
    private final PaymentKafkaProducer paymentKafkaProducer;
    private final ObjectMapper objectMapper;

    @Value("${rabbitmq.exchange.name:wallet.exchange}")
    private String exchangeName;

    @Value("${rabbitmq.routing.key.transaction:transaction.completed}")
    private String routingKeyTransaction;

    @Value("${saga.outbox.poll-interval-ms:2000}")
    private long pollIntervalMs;

    @Value("${saga.outbox.batch-size:50}")
    private int batchSize;

    @Value("${saga.outbox.max-retry:5}")
    private int maxRetry;

    @Transactional
    @Scheduled(fixedDelayString = "${saga.outbox.poll-interval-ms:2000}")
    public void relayPendingEvents() {
        List<OutboxEvent> pending = outboxEventRepository.findPendingRetryable(maxRetry);
        if (pending.isEmpty()) {
            return;
        }

        for (OutboxEvent event : pending) {
            try {
                // 1. Publish RabbitMQ (task queue - Ledger/Notification consumer)
                String routingKey = resolveRoutingKey(event);
                rabbitTemplate.convertAndSend(exchangeName, routingKey, event.getPayload(),
                        message -> {
                            message.getMessageProperties().setHeader("event_type", event.getEventType());
                            message.getMessageProperties().setHeader("aggregate_type", event.getAggregateType());
                            message.getMessageProperties().setHeader("aggregate_id", event.getAggregateId());
                            return message;
                        });

                // 2. Publish Kafka (event stream - Saga Transaction Lifecycle, AGENT 3)
                // Message Key = transaction_id (aggregate_id) -> cùng 1 giao dịch rơi vào cùng Partition
                paymentKafkaProducer.sendLifecycleEvent(
                        event.getAggregateId(),
                        event.getEventType(),
                        event.getPayload());

                event.markPublished();
                outboxEventRepository.save(event);
                log.debug("Outbox published (RabbitMQ + Kafka): id={} eventType={} routingKey={} key={}",
                        event.getId(), event.getEventType(), routingKey, event.getAggregateId());
            } catch (Exception e) {
                event.incrementRetry();
                if (event.getRetryCount() >= maxRetry) {
                    event.markFailed();
                    log.error("Outbox event failed after max retry: id={} eventType={}",
                            event.getId(), event.getEventType(), e);
                } else {
                    log.warn("Outbox publish retry {} for id={}: {}", event.getRetryCount(), event.getId(), e.getMessage());
                }
                outboxEventRepository.save(event);
            }
        }
    }

    /**
     * Ghi một sự kiện outbox mới (được gọi từ Saga Orchestrator cùng DB transaction).
     */
    public void saveEvent(String aggregateType, String aggregateId, String eventType, String payload) {
        OutboxEvent event = OutboxEvent.pending(aggregateType, aggregateId, eventType, payload);
        outboxEventRepository.save(event);
        log.debug("Outbox saved PENDING: id={} aggregate={} eventType={}",
                event.getId(), aggregateType, eventType);
    }

    private String resolveRoutingKey(OutboxEvent event) {
        String type = event.getEventType();
        if ("TransactionCompletedEvent".equals(type) || "TRANSACTION_COMPLETED".equals(type)) {
            return routingKeyTransaction;
        }
        if ("TransactionReversedEvent".equals(type)) {
            return "transaction.reversed";
        }
        if ("TransactionFailedEvent".equals(type)) {
            return "transaction.failed";
        }
        return DEFAULT_ROUTING_KEY;
    }
}
