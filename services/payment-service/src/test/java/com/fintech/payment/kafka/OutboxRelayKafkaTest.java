package com.fintech.payment.outbox;

import com.fintech.payment.domain.entity.OutboxEvent;
import com.fintech.payment.repository.OutboxEventRepository;
import com.fintech.payment.kafka.PaymentKafkaProducer;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.amqp.rabbit.core.RabbitTemplate;

import java.time.Instant;
import java.util.Collections;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class OutboxRelayKafkaTest {

    @Mock private OutboxEventRepository outboxEventRepository;
    @Mock private RabbitTemplate rabbitTemplate;
    @Mock private PaymentKafkaProducer paymentKafkaProducer;
    @Mock private ObjectMapper objectMapper;

    private OutboxRelay relay;

    private static final String TX_ID = "tx-lifecycle-1";

    @org.junit.jupiter.api.BeforeEach
    void setUp() {
        relay = new OutboxRelay(outboxEventRepository, rabbitTemplate, paymentKafkaProducer, objectMapper);
        org.springframework.test.util.ReflectionTestUtils.setField(relay, "exchangeName", "wallet.exchange");
        org.springframework.test.util.ReflectionTestUtils.setField(relay, "routingKeyTransaction", "transaction.completed");
    }

    @Test
    @DisplayName("Outbox Relay publish sự kiện Kafka khi Saga hoàn thành: key = transaction_id, topic lifecycle")
    void shouldPublishKafkaLifecycleEventWhenRelayingCompletedEvent() {
        OutboxEvent event = OutboxEvent.pending("Transaction", TX_ID, "TransactionCompletedEvent", "{\"amount\":100000}");
        when(outboxEventRepository.findPendingRetryable(anyInt())).thenReturn(Collections.singletonList(event));
        when(outboxEventRepository.save(any(OutboxEvent.class))).thenAnswer(inv -> inv.getArgument(0));

        relay.relayPendingEvents();

        // RabbitMQ publish
        verify(rabbitTemplate).convertAndSend(any(String.class), any(String.class), any(Object.class), any(org.springframework.amqp.core.MessagePostProcessor.class));

        // Kafka publish: key = transaction_id (aggregateId), eventType = TransactionCompletedEvent
        ArgumentCaptor<String> keyCaptor = ArgumentCaptor.forClass(String.class);
        ArgumentCaptor<String> typeCaptor = ArgumentCaptor.forClass(String.class);
        ArgumentCaptor<Object> payloadCaptor = ArgumentCaptor.forClass(Object.class);
        verify(paymentKafkaProducer, times(1))
                .sendLifecycleEvent(keyCaptor.capture(), typeCaptor.capture(), payloadCaptor.capture());

        assertThat(keyCaptor.getValue()).isEqualTo(TX_ID);
        assertThat(typeCaptor.getValue()).isEqualTo("TransactionCompletedEvent");

        // Đánh dấu PUBLISHED
        assertThat(event.getStatus()).isEqualTo("PUBLISHED");
        assertThat(event.getPublishedAt()).isNotNull();
    }

    @Test
    @DisplayName("Không có sự kiện PENDING thì không gọi Kafka Producer")
    void shouldNotCallKafkaWhenNoPendingEvent() {
        when(outboxEventRepository.findPendingRetryable(anyInt())).thenReturn(Collections.emptyList());

        relay.relayPendingEvents();

        verify(paymentKafkaProducer, never()).sendLifecycleEvent(any(), any(), any());
        verify(rabbitTemplate, never()).convertAndSend(any(String.class), any(String.class), any(Object.class), any(org.springframework.amqp.core.MessagePostProcessor.class));
    }

    @Test
    @DisplayName("Sự kiện REVERSED cũng được stream Kafka với key = transaction_id")
    void shouldStreamReversedEventToKafka() {
        OutboxEvent event = OutboxEvent.pending("Transaction", TX_ID, "TransactionReversedEvent", "{\"reason\":\"credit failed\"}");
        when(outboxEventRepository.findPendingRetryable(anyInt())).thenReturn(Collections.singletonList(event));
        when(outboxEventRepository.save(any(OutboxEvent.class))).thenAnswer(inv -> inv.getArgument(0));

        relay.relayPendingEvents();

        ArgumentCaptor<String> keyCaptor = ArgumentCaptor.forClass(String.class);
        ArgumentCaptor<String> typeCaptor = ArgumentCaptor.forClass(String.class);
        verify(paymentKafkaProducer, times(1))
                .sendLifecycleEvent(keyCaptor.capture(), typeCaptor.capture(), any());

        assertThat(keyCaptor.getValue()).isEqualTo(TX_ID);
        assertThat(typeCaptor.getValue()).isEqualTo("TransactionReversedEvent");
        assertThat(event.getStatus()).isEqualTo("PUBLISHED");
    }
}
