package com.fintech.payment.kafka;

import com.fintech.wallet.kafka.KafkaEventEnvelope;
import com.fintech.wallet.kafka.KafkaTopicConstants;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;

import java.util.concurrent.CompletableFuture;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class PaymentKafkaProducerTest {

    @Mock private KafkaTemplate<String, Object> kafkaTemplate;

    private PaymentKafkaProducer producer;

    private static final String TOPIC = KafkaTopicConstants.TOPIC_PAYMENT_TRANSACTION_LIFECYCLE;
    private static final String TX_ID = "tx-123";

    @org.junit.jupiter.api.BeforeEach
    void setUp() {
        CompletableFuture<SendResult<String, Object>> future = CompletableFuture.completedFuture(null);
        when(kafkaTemplate.send(eq(TOPIC), eq(TX_ID), any())).thenReturn(future);
        producer = new PaymentKafkaProducer(kafkaTemplate);
    }

    @Test
    @DisplayName("Gửi sự kiện vòng đời Saga: topic đúng, key = transaction_id, traceId = transaction_id")
    void shouldSendLifecycleEventWithTransactionIdKey() {
        producer.sendLifecycleEvent(TX_ID, "TransactionCompletedEvent", new Object());

        ArgumentCaptor<KafkaEventEnvelope<Object>> captor = ArgumentCaptor.forClass(KafkaEventEnvelope.class);
        verify(kafkaTemplate).send(eq(TOPIC), eq(TX_ID), captor.capture());

        KafkaEventEnvelope<Object> envelope = captor.getValue();
        assertThat(envelope).isNotNull();
        assertThat(envelope.traceId()).isEqualTo(TX_ID);
        assertThat(envelope.producerService()).isEqualTo("payment-service");
        assertThat(envelope.topic()).isEqualTo(TOPIC);
        assertThat(envelope.timestamp()).isNotNull();
        assertThat(envelope.eventId()).isNotNull();
    }
}
