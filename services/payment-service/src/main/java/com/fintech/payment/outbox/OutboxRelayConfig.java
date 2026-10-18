package com.fintech.payment.outbox;

import com.fintech.payment.domain.entity.OutboxEvent;
import com.fintech.payment.repository.OutboxEventRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.core.Binding;
import org.springframework.amqp.core.BindingBuilder;
import org.springframework.amqp.core.DirectExchange;
import org.springframework.amqp.core.Queue;
import org.springframework.amqp.rabbit.core.RabbitAdmin;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.annotation.Scheduled;

import java.time.Instant;

/**
 * Cấu hình RabbitMQ Topology cho Payment Service.
 * Exchange: wallet.exchange (topic) - tương đồng các consumer Ledger/Notification.
 * Queue: payment.outbox.queue, binding routing key transaction.*.
 */
@Configuration
@EnableScheduling
@RequiredArgsConstructor
@Slf4j
public class OutboxRelayConfig {

    public static final String EXCHANGE_NAME = "wallet.exchange";
    public static final String QUEUE_NAME = "payment.outbox.queue";
    public static final String ROUTING_KEY_TRANSACTION = "transaction.completed";

    @Value("${rabbitmq.exchange.name:wallet.exchange}")
    private String exchangeName;

    @Value("${rabbitmq.queue.payment:payment.outbox.queue}")
    private String queueName;

    @Value("${rabbitmq.routing.key.transaction:transaction.completed}")
    private String routingKeyTransaction;

    @Bean
    DirectExchange walletExchange() {
        return new DirectExchange(exchangeName);
    }

    @Bean
    Queue paymentOutboxQueue() {
        return new Queue(queueName, true);
    }

    @Bean
    Binding paymentOutboxBinding(DirectExchange exchange, Queue queue) {
        return BindingBuilder.bind(queue).to(exchange).with(routingKeyTransaction);
    }

    @Bean
    RabbitAdmin rabbitAdmin(RabbitTemplate rabbitTemplate) {
        return new RabbitAdmin(rabbitTemplate);
    }
}
