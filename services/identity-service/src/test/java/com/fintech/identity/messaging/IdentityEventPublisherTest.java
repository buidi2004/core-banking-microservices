package com.fintech.identity.messaging;

import com.fintech.wallet.domain.event.UserRegisteredEvent;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.test.util.ReflectionTestUtils;

import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;

@ExtendWith(MockitoExtension.class)
class IdentityEventPublisherTest {

    @Mock
    private RabbitTemplate rabbitTemplate;

    @InjectMocks
    private IdentityEventPublisher publisher;

    @BeforeEach
    void setUp() {
        ReflectionTestUtils.setField(publisher, "exchange", "wallet.exchange");
        ReflectionTestUtils.setField(publisher, "userRegisteredRoutingKey", "wallet.user.registered");
    }

    @Test
    @DisplayName("Phát sự kiện UserRegisteredEvent đến topic exchange 'wallet.exchange' với key 'wallet.user.registered'")
    void shouldPublishUserRegisteredEventToRabbitMQ() {
        UserRegisteredEvent event = UserRegisteredEvent.of(
                "user-test-uuid",
                "0987654321",
                "Tran Thi B",
                0,
                "VN"
        );

        publisher.publishUserRegistered(event);

        verify(rabbitTemplate, times(1)).convertAndSend(
                "wallet.exchange",
                "wallet.user.registered",
                event
        );
    }
}
