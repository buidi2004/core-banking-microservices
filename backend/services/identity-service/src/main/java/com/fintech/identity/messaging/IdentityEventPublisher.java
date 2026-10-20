package com.fintech.identity.messaging;

import com.fintech.wallet.domain.event.UserRegisteredEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * Publisher phát sự kiện từ Identity Service lên RabbitMQ.
 * Phục vụ Event-Driven Onboarding: khởi tạo ví tự động khi người dùng đăng ký.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class IdentityEventPublisher {

    private final RabbitTemplate rabbitTemplate;

    @Value("${wallet.rabbitmq.exchange:wallet.exchange}")
    private String exchange;

    @Value("${wallet.rabbitmq.routing-key.user-registered:wallet.user.registered}")
    private String userRegisteredRoutingKey;

    public void publishUserRegistered(UserRegisteredEvent event) {
        log.info("Phát sự kiện UserRegisteredEvent lên exchange='{}' key='{}': userId={}, phone={}",
                exchange, userRegisteredRoutingKey, event.userId(), event.phone());
        try {
            rabbitTemplate.convertAndSend(exchange, userRegisteredRoutingKey, event);
            log.info("Publish UserRegisteredEvent thành công cho userId={}", event.userId());
        } catch (Exception e) {
            log.error("Lỗi khi publish UserRegisteredEvent cho userId={}: {}", event.userId(), e.getMessage(), e);
            // Có thể bổ sung lưu vào Outbox table để đảm bảo transactional outbox
            throw new RuntimeException("Không thể gửi sự kiện đăng ký người dùng: " + e.getMessage(), e);
        }
    }
}
