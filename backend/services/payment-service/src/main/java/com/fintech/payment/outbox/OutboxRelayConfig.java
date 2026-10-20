package com.fintech.payment.outbox;

import com.fintech.payment.domain.entity.OutboxEvent;
import com.fintech.payment.repository.OutboxEventRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.core.TopicExchange;
import org.springframework.amqp.rabbit.core.RabbitAdmin;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.amqp.support.converter.Jackson2JsonMessageConverter;
import org.springframework.amqp.support.converter.MessageConverter;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.annotation.Scheduled;

import java.time.Instant;

/**
 * Cấu hình RabbitMQ Topology cho Payment Service.
 * Exchange: wallet.transaction.events (topic) - dùng chung với Ledger/Notification.
 * Payment chỉ publish sự kiện (không tự bind queue riêng).
 *
 * Lưu ý: phải là TopicExchange (không phải DirectExchange) vì consumer bind
 * bằng wildcard "transaction.#". Nếu khai báo DirectExchange cùng tên sẽ gây
 * PRECONDITION_FAILED hoặc làm wildcard không match.
 */
@Configuration
@EnableScheduling
@RequiredArgsConstructor
@Slf4j
public class OutboxRelayConfig {

    public static final String EXCHANGE_NAME = "wallet.transaction.events";
    public static final String ROUTING_KEY_TRANSACTION = "transaction.completed";

    @Value("${rabbitmq.exchange.name:wallet.transaction.events}")
    private String exchangeName;

    @Bean
    TopicExchange walletExchange() {
        return new TopicExchange(exchangeName, true, false);
    }

    // Payment chỉ PUBLISH sự kiện; không tự bind một queue cho chính mình
    // (trước đây queue payment.outbox.queue không có consumer nên phình vô hạn).

    @Bean
    RabbitAdmin rabbitAdmin(RabbitTemplate rabbitTemplate) {
        return new RabbitAdmin(rabbitTemplate);
    }

    /**
     * Publish dưới dạng JSON (content_type=application/json).
     * Nếu dùng SimpleMessageConverter mặc định, JsonNode sẽ bị Java-serialize
     * (application/x-java-serialized-object) và Ledger/Notification không đọc được.
     */
    @Bean
    public MessageConverter jsonMessageConverter(com.fasterxml.jackson.databind.ObjectMapper objectMapper) {
        return new Jackson2JsonMessageConverter(objectMapper);
    }
}
