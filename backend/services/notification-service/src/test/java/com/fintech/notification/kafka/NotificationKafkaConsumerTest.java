package com.fintech.notification.kafka;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fintech.notification.amqp.NotificationConsumer;
import com.fintech.wallet.domain.event.TransactionEvent;
import com.fintech.wallet.kafka.KafkaTopicConstants;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.kafka.support.Acknowledgment;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class NotificationKafkaConsumerTest {

    @Mock
    private NotificationConsumer notificationConsumer;

    @Mock
    private Acknowledgment acknowledgment;

    private NotificationKafkaConsumer kafkaConsumer;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @BeforeEach
    void setUp() {
        kafkaConsumer = new NotificationKafkaConsumer(notificationConsumer, objectMapper);
    }

    @Test
    @DisplayName("Parse sự kiện nạp tiền tại quầy (banking.cash.deposit-completed.v1)")
    void parsesCashDepositCompletedEvent() {
        String json = """
                {
                  "eventType": "DepositCompletedEvent",
                  "depositCode": "DEP-20261107-001",
                  "accountNumber": "0901234567",
                  "customerName": "Nguyen Van A",
                  "amount": 5000000,
                  "branchId": "BR_Q1",
                  "timestamp": 1794000000000
                }
                """;

        ConsumerRecord<String, String> record = new ConsumerRecord<>(
                NotificationKafkaConsumer.TOPIC_CASH_DEPOSIT_COMPLETED, 0, 100L, "0901234567", json);

        kafkaConsumer.onTransactionEvent(record, acknowledgment);

        ArgumentCaptor<TransactionEvent> captor = ArgumentCaptor.forClass(TransactionEvent.class);
        verify(notificationConsumer).onTransactionEvent(captor.capture());
        verify(acknowledgment).acknowledge();

        TransactionEvent event = captor.getValue();
        assertThat(event.getTransactionId()).isEqualTo("DEP-20261107-001");
        assertThat(event.getType()).isEqualTo("DEPOSIT");
        assertThat(event.getStatus()).isEqualTo("SUCCESS");
        assertThat(event.getTargetWalletId()).isEqualTo("0901234567");
        assertThat(event.getAmount()).isEqualByComparingTo(BigDecimal.valueOf(5000000));
        assertThat(event.getNote()).contains("BR_Q1").contains("Nguyen Van A");
    }

    @Test
    @DisplayName("Parse sự kiện tăng số dư ví DEPOSIT từ Wallet Service")
    void parsesWalletBalanceChangedCredit() {
        String json = """
                {
                  "walletId": "wallet-abc-123",
                  "previousBalance": 1000000,
                  "changeAmount": 200000,
                  "newBalance": 1200000,
                  "currency": "VND",
                  "transactionId": "tx-dep-123",
                  "changeType": "DEPOSIT"
                }
                """;

        ConsumerRecord<String, String> record = new ConsumerRecord<>(
                KafkaTopicConstants.TOPIC_WALLET_BALANCE_CHANGED, 0, 101L, "wallet-abc-123", json);

        kafkaConsumer.onTransactionEvent(record, acknowledgment);

        ArgumentCaptor<TransactionEvent> captor = ArgumentCaptor.forClass(TransactionEvent.class);
        verify(notificationConsumer).onTransactionEvent(captor.capture());
        verify(acknowledgment).acknowledge();

        TransactionEvent event = captor.getValue();
        assertThat(event.getTransactionId()).isEqualTo("tx-dep-123");
        assertThat(event.getTargetWalletId()).isEqualTo("wallet-abc-123");
        assertThat(event.getSourceWalletId()).isNull();
        assertThat(event.getAmount()).isEqualByComparingTo(BigDecimal.valueOf(200000));
        assertThat(event.getTargetBalanceAfter()).isEqualByComparingTo(BigDecimal.valueOf(1200000));
        assertThat(event.getStatus()).isEqualTo("SUCCESS");
    }

    @Test
    @DisplayName("Parse sự kiện giảm số dư ví TRANSFER_OUT/WITHDRAWAL từ Wallet Service")
    void parsesWalletBalanceChangedDebit() {
        String json = """
                {
                  "walletId": "wallet-xyz-789",
                  "previousBalance": 1200000,
                  "changeAmount": -300000,
                  "newBalance": 900000,
                  "currency": "VND",
                  "transactionId": "tx-with-456",
                  "changeType": "WITHDRAWAL"
                }
                """;

        ConsumerRecord<String, String> record = new ConsumerRecord<>(
                KafkaTopicConstants.TOPIC_WALLET_BALANCE_CHANGED, 0, 102L, "wallet-xyz-789", json);

        kafkaConsumer.onTransactionEvent(record, acknowledgment);

        ArgumentCaptor<TransactionEvent> captor = ArgumentCaptor.forClass(TransactionEvent.class);
        verify(notificationConsumer).onTransactionEvent(captor.capture());
        verify(acknowledgment).acknowledge();

        TransactionEvent event = captor.getValue();
        assertThat(event.getTransactionId()).isEqualTo("tx-with-456");
        assertThat(event.getSourceWalletId()).isEqualTo("wallet-xyz-789");
        assertThat(event.getTargetWalletId()).isNull();
        assertThat(event.getAmount()).isEqualByComparingTo(BigDecimal.valueOf(300000));
        assertThat(event.getSourceBalanceAfter()).isEqualByComparingTo(BigDecimal.valueOf(900000));
        assertThat(event.getStatus()).isEqualTo("SUCCESS");
    }

    @Test
    @DisplayName("Bỏ qua sự kiện RESERVE hoặc RELEASE (giữ tiền tạm thời)")
    void skipsReserveAndReleaseEvents() {
        String json = """
                {
                  "walletId": "wallet-xyz-789",
                  "previousBalance": 1200000,
                  "changeAmount": 0,
                  "newBalance": 1200000,
                  "currency": "VND",
                  "transactionId": "res-123",
                  "changeType": "RESERVE"
                }
                """;

        ConsumerRecord<String, String> record = new ConsumerRecord<>(
                KafkaTopicConstants.TOPIC_WALLET_BALANCE_CHANGED, 0, 103L, "wallet-xyz-789", json);

        kafkaConsumer.onTransactionEvent(record, acknowledgment);

        verify(notificationConsumer, never()).onTransactionEvent(any());
        verify(acknowledgment).acknowledge();
    }

    @Test
    @DisplayName("Parse sự kiện chuẩn TransactionEvent từ Payment Lifecycle")
    void parsesPaymentLifecycleTransactionEvent() {
        String json = """
                {
                  "payload": {
                    "eventId": "evt-lifecycle-1",
                    "transactionId": "tx-lifecycle-1",
                    "type": "TRANSFER",
                    "status": "SUCCESS",
                    "sourceWalletId": "w-src",
                    "targetWalletId": "w-dst",
                    "amount": 50000,
                    "currency": "VND"
                  }
                }
                """;

        ConsumerRecord<String, String> record = new ConsumerRecord<>(
                KafkaTopicConstants.TOPIC_PAYMENT_TRANSACTION_LIFECYCLE, 0, 104L, "tx-lifecycle-1", json);

        kafkaConsumer.onTransactionEvent(record, acknowledgment);

        ArgumentCaptor<TransactionEvent> captor = ArgumentCaptor.forClass(TransactionEvent.class);
        verify(notificationConsumer).onTransactionEvent(captor.capture());
        verify(acknowledgment).acknowledge();

        TransactionEvent event = captor.getValue();
        assertThat(event.getTransactionId()).isEqualTo("tx-lifecycle-1");
        assertThat(event.getSourceWalletId()).isEqualTo("w-src");
        assertThat(event.getTargetWalletId()).isEqualTo("w-dst");
        assertThat(event.getAmount()).isEqualByComparingTo(BigDecimal.valueOf(50000));
    }
}

