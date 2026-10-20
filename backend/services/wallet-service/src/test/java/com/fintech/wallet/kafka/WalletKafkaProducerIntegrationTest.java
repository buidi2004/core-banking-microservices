package com.fintech.wallet.kafka;

import com.fintech.wallet.application.service.WalletInternalApplicationService;
import com.fintech.wallet.domain.entity.Wallet;
import com.fintech.wallet.domain.port.out.DistributedLockPort;
import com.fintech.wallet.domain.port.out.WalletPersistencePort;
import com.fintech.wallet.infrastructure.kafka.WalletBalanceChangedKafkaProducer;
import com.fintech.wallet.kafka.WalletBalanceChangedPayload;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.clients.producer.RecordMetadata;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;

import java.math.BigDecimal;
import java.util.Optional;
import java.util.concurrent.CompletableFuture;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * Integration test cho Wallet Kafka Producer.
 * Xác thực:
 *  1. Event được publish đúng topic banking.wallet.balance-changed.v1
 *  2. Partition Key = walletId (strict ordering)
 *  3. Payload chứa đủ metadata: previousBalance, changeAmount, newBalance, currency, transactionId
 */
@ExtendWith(MockitoExtension.class)
class WalletKafkaProducerIntegrationTest {

    @Mock
    private KafkaTemplate<String, Object> kafkaTemplate;

    @Mock
    private WalletPersistencePort walletPersistencePort;

    @Mock
    private DistributedLockPort distributedLockPort;

    @InjectMocks
    private WalletBalanceChangedKafkaProducer kafkaProducer;

    @BeforeEach
    void setUp() {
        // Mock distributed lock — trả về kết quả trực tiếp (không lock thật)
        when(distributedLockPort.executeWithLock(anyString(), anyLong(), any())).thenAnswer(inv -> {
            var supplier = inv.getArgument(2);
            return supplier.get();
        });
    }

    private Wallet createWallet(String id, String userId, long balance) {
        return Wallet.builder()
                .id(id)
                .userId(userId)
                .balance(balance)
                .reservedBalance(0L)
                .currency("VND")
                .status("ACTIVE")
                .dailyLimit(50000000L)
                .dailySpent(0L)
                .build();
    }

    // ======================== KAFKA PRODUCER DIRECT TEST ========================

    @Nested
    @DisplayName("WalletBalanceChangedKafkaProducer")
    class KafkaProducerTests {

        @Test
        @DisplayName("Publish DEBIT — key = walletId, topic đúng, payload đầy đủ")
        void publishDebit_correctKeyAndTopic() {
            String walletId = "w-kafka-1";
            long amount = 50000L;
            String transactionId = "tx-kafka-debit-1";

            // Chuẩn bị sendResult mock
            RecordMetadata metadata = new RecordMetadata(
                    new org.apache.kafka.common.TopicPartition(
                            com.fintech.wallet.kafka.KafkaTopicConstants.TOPIC_WALLET_BALANCE_CHANGED, 0),
                    null, 0L, 0L, 0L);
            when(kafkaTemplate.send(eq(KafkaTopicConstants.TOPIC_WALLET_BALANCE_CHANGED),
                    eq(walletId), any())).thenReturn(
                    CompletableFuture.completedFuture(new SendResult<>(
                            new ProducerRecord<>(KafkaTopicConstants.TOPIC_WALLET_BALANCE_CHANGED, walletId, null),
                            metadata)));

            // Gọi producer trực tiếp
            WalletBalanceChangedPayload payload = WalletBalanceChangedPayload.debit(
                    walletId, new BigDecimal("100000"), new BigDecimal(amount), "VND", transactionId);
            kafkaProducer.publishBalanceChanged(payload);

            // Verify: send được gọi với key = walletId
            ArgumentCaptor<String> keyCaptor = ArgumentCaptor.forClass(String.class);
            ArgumentCaptor<Object> valueCaptor = ArgumentCaptor.forClass(Object.class);
            verify(kafkaTemplate).send(eq(KafkaTopicConstants.TOPIC_WALLET_BALANCE_CHANGED),
                    keyCaptor.capture(), valueCaptor.capture());

            assertEquals(walletId, keyCaptor.getValue(),
                    "Partition Key PHẢI là walletId để đảm bảo Strict Ordering per wallet");
            assertNotNull(valueCaptor.getValue());

            // Verify payload structure
            @SuppressWarnings("unchecked")
            KafkaEventEnvelope<WalletBalanceChangedPayload> envelope =
                    (KafkaEventEnvelope<WalletBalanceChangedPayload>) valueCaptor.getValue();
            assertEquals(KafkaTopicConstants.TOPIC_WALLET_BALANCE_CHANGED, envelope.topic());
            assertEquals("wallet-service", envelope.producerService());
            assertEquals(transactionId, envelope.payload().transactionId());
            assertEquals("WITHDRAWAL", envelope.payload().changeType());
            assertEquals(new BigDecimal("100000"), envelope.payload().previousBalance());
            assertEquals(new BigDecimal("-50000"), envelope.payload().changeAmount());
            assertEquals(new BigDecimal("50000"), envelope.payload().newBalance());
        }

        @Test
        @DisplayName("Publish CREDIT — key = walletId, changeAmount dương")
        void publishCredit_correctPayload() {
            String walletId = "w-kafka-2";
            long amount = 30000L;
            String transactionId = "tx-kafka-credit-1";

            RecordMetadata metadata = new RecordMetadata(
                    new org.apache.kafka.common.TopicPartition(
                            KafkaTopicConstants.TOPIC_WALLET_BALANCE_CHANGED, 1),
                    null, 0L, 0L, 0L);
            when(kafkaTemplate.send(eq(KafkaTopicConstants.TOPIC_WALLET_BALANCE_CHANGED),
                    eq(walletId), any())).thenReturn(
                    CompletableFuture.completedFuture(new SendResult<>(
                            new ProducerRecord<>(KafkaTopicConstants.TOPIC_WALLET_BALANCE_CHANGED, walletId, null),
                            metadata)));

            WalletBalanceChangedPayload payload = WalletBalanceChangedPayload.credit(
                    walletId, new BigDecimal("50000"), new BigDecimal(amount), "VND", transactionId);
            kafkaProducer.publishBalanceChanged(payload);

            ArgumentCaptor<Object> valueCaptor = ArgumentCaptor.forClass(Object.class);
            verify(kafkaTemplate).send(anyString(), eq(walletId), valueCaptor.capture());

            @SuppressWarnings("unchecked")
            KafkaEventEnvelope<WalletBalanceChangedPayload> envelope =
                    (KafkaEventEnvelope<WalletBalanceChangedPayload>) valueCaptor.getValue();

            assertEquals("DEPOSIT", envelope.payload().changeType());
            assertEquals(new BigDecimal("50000"), envelope.payload().previousBalance());
            assertEquals(new BigDecimal("30000"), envelope.payload().changeAmount());
            assertEquals(new BigDecimal("80000"), envelope.payload().newBalance());
        }

        @Test
        @DisplayName("Bỏ qua publish khi walletId trống")
        void publish_skipsWhenWalletIdBlank() {
            WalletBalanceChangedPayload payload = new WalletBalanceChangedPayload(
                    "", new BigDecimal("0"), BigDecimal.ZERO, BigDecimal.ZERO, "VND", "tx", "DEPOSIT");
            kafkaProducer.publishBalanceChanged(payload);

            verifyNoInteractions(kafkaTemplate);
        }

        @Test
        @DisplayName("Publish RESERVE — changeAmount = 0, balance không đổi")
        void publishReserve_noBalanceChange() {
            String walletId = "w-kafka-3";
            String reservationId = "res-kafka-1";

            RecordMetadata metadata = new RecordMetadata(
                    new org.apache.kafka.common.TopicPartition(
                            KafkaTopicConstants.TOPIC_WALLET_BALANCE_CHANGED, 2),
                    null, 0L, 0L, 0L);
            when(kafkaTemplate.send(eq(KafkaTopicConstants.TOPIC_WALLET_BALANCE_CHANGED),
                    eq(walletId), any())).thenReturn(
                    CompletableFuture.completedFuture(new SendResult<>(
                            new ProducerRecord<>(KafkaTopicConstants.TOPIC_WALLET_BALANCE_CHANGED, walletId, null),
                            metadata)));

            WalletBalanceChangedPayload payload = WalletBalanceChangedPayload.reserve(
                    walletId, new BigDecimal("100000"), new BigDecimal("20000"), reservationId);
            kafkaProducer.publishBalanceChanged(payload);

            ArgumentCaptor<Object> valueCaptor = ArgumentCaptor.forClass(Object.class);
            verify(kafkaTemplate).send(anyString(), eq(walletId), valueCaptor.capture());

            @SuppressWarnings("unchecked")
            KafkaEventEnvelope<WalletBalanceChangedPayload> envelope =
                    (KafkaEventEnvelope<WalletBalanceChangedPayload>) valueCaptor.getValue();

            assertEquals("RESERVE", envelope.payload().changeType());
            assertEquals(reservationId, envelope.payload().transactionId());
            assertEquals(BigDecimal.ZERO, envelope.payload().changeAmount());
            assertEquals(new BigDecimal("100000"), envelope.payload().newBalance());
        }
    }

    // ======================== APPLICATION SERVICE INTEGRATION TEST ========================

    @Nested
    @DisplayName("WalletInternalApplicationService — Kafka integration")
    class ApplicationServiceKafkaTest {

        @Test
        @DisplayName("Debit thành công → publish DEBIT event với key = walletId")
        void debit_triggersKafkaPublish() {
            String walletId = "w-int-1";
            String userId = "u-int-1";
            long initialBalance = 100000L;
            long debitAmount = 30000L;
            String transactionId = "tx-int-debit";

            Wallet wallet = createWallet(walletId, userId, initialBalance);
            when(walletPersistencePort.findWalletByIdForUpdate(walletId)).thenReturn(Optional.of(wallet));
            when(walletPersistencePort.saveWallet(any())).thenReturn(wallet);

            RecordMetadata metadata = new RecordMetadata(
                    new org.apache.kafka.common.TopicPartition(KafkaTopicConstants.TOPIC_WALLET_BALANCE_CHANGED, 0),
                    null, 0L, 0L, 0L);
            when(kafkaTemplate.send(eq(KafkaTopicConstants.TOPIC_WALLET_BALANCE_CHANGED),
                    eq(walletId), any())).thenReturn(
                    CompletableFuture.completedFuture(new SendResult<>(
                            new ProducerRecord<>(KafkaTopicConstants.TOPIC_WALLET_BALANCE_CHANGED, walletId, null),
                            metadata)));

            WalletInternalApplicationService service = new WalletInternalApplicationService(
                    walletPersistencePort, distributedLockPort, kafkaProducer);

            WalletInternalApplicationService.DebitResult result = service.debitWallet(
                    walletId, debitAmount, transactionId, null);

            assertTrue(result.success());
            assertEquals(initialBalance - debitAmount, result.balanceAfter());

            // Xác thực Kafka đã được gọi với key = walletId
            ArgumentCaptor<String> keyCaptor = ArgumentCaptor.forClass(String.class);
            ArgumentCaptor<Object> valueCaptor = ArgumentCaptor.forClass(Object.class);
            verify(kafkaTemplate).send(eq(KafkaTopicConstants.TOPIC_WALLET_BALANCE_CHANGED),
                    keyCaptor.capture(), valueCaptor.capture());

            assertEquals(walletId, keyCaptor.getValue(),
                    "Partition Key bắt buộc phải là walletId để đảm bảo Strict Ordering");

            @SuppressWarnings("unchecked")
            KafkaEventEnvelope<WalletBalanceChangedPayload> envelope =
                    (KafkaEventEnvelope<WalletBalanceChangedPayload>) valueCaptor.getValue();
            assertEquals("WITHDRAWAL", envelope.payload().changeType());
            assertEquals(transactionId, envelope.payload().transactionId());
        }

        @Test
        @DisplayName("Credit thành công → publish DEPOSIT event")
        void credit_triggersKafkaPublish() {
            String walletId = "w-int-2";
            long initialBalance = 50000L;
            long creditAmount = 20000L;
            String transactionId = "tx-int-credit";

            Wallet wallet = createWallet(walletId, "u-int-2", initialBalance);
            when(walletPersistencePort.findWalletByIdForUpdate(walletId)).thenReturn(Optional.of(wallet));
            when(walletPersistencePort.saveWallet(any())).thenReturn(wallet);

            RecordMetadata metadata = new RecordMetadata(
                    new org.apache.kafka.common.TopicPartition(KafkaTopicConstants.TOPIC_WALLET_BALANCE_CHANGED, 0),
                    null, 0L, 0L, 0L);
            when(kafkaTemplate.send(eq(KafkaTopicConstants.TOPIC_WALLET_BALANCE_CHANGED),
                    eq(walletId), any())).thenReturn(
                    CompletableFuture.completedFuture(new SendResult<>(
                            new ProducerRecord<>(KafkaTopicConstants.TOPIC_WALLET_BALANCE_CHANGED, walletId, null),
                            metadata)));

            WalletInternalApplicationService service = new WalletInternalApplicationService(
                    walletPersistencePort, distributedLockPort, kafkaProducer);

            WalletInternalApplicationService.CreditResult result = service.creditWallet(
                    walletId, creditAmount, transactionId, null);

            assertTrue(result.success());
            assertEquals(initialBalance + creditAmount, result.balanceAfter());

            ArgumentCaptor<Object> valueCaptor = ArgumentCaptor.forClass(Object.class);
            verify(kafkaTemplate).send(anyString(), eq(walletId), valueCaptor.capture());

            @SuppressWarnings("unchecked")
            KafkaEventEnvelope<WalletBalanceChangedPayload> envelope =
                    (KafkaEventEnvelope<WalletBalanceChangedPayload>) valueCaptor.getValue();
            assertEquals("DEPOSIT", envelope.payload().changeType());
            assertEquals(new BigDecimal(initialBalance + creditAmount), envelope.payload().newBalance());
        }

        @Test
        @DisplayName("Debit thất bại (không đủ số dư) → KHÔNG publish event")
        void debit_insufficientBalance_noKafkaPublish() {
            String walletId = "w-int-3";
            Wallet wallet = createWallet(walletId, "u-int-3", 5000L);
            when(walletPersistencePort.findWalletByIdForUpdate(walletId)).thenReturn(Optional.of(wallet));

            WalletInternalApplicationService service = new WalletInternalApplicationService(
                    walletPersistencePort, distributedLockPort, kafkaProducer);

            WalletInternalApplicationService.DebitResult result = service.debitWallet(
                    walletId, 100000L, "tx-fail", null);

            assertFalse(result.success());
            assertEquals("DEBIT_INSUFFICIENT_BALANCE", result.errorCode());

            // Không có event nào được publish vì giao dịch thất bại
            verifyNoInteractions(kafkaTemplate);
        }

        @Test
        @DisplayName("Wallet not found → KHÔNG publish event")
        void debit_walletNotFound_noKafkaPublish() {
            when(walletPersistencePort.findWalletByIdForUpdate("w-missing"))
                    .thenReturn(Optional.empty());

            WalletInternalApplicationService service = new WalletInternalApplicationService(
                    walletPersistencePort, distributedLockPort, kafkaProducer);

            WalletInternalApplicationService.DebitResult result = service.debitWallet(
                    "w-missing", 1000L, "tx-missing", null);

            assertFalse(result.success());
            verifyNoInteractions(kafkaTemplate);
        }

        @Test
        @DisplayName("Kafka publish lỗi → không ảnh hưởng giao dịch chính (non-fatal)")
        void debit_kafkaFailure_doesNotAffectTransaction() {
            String walletId = "w-int-4";
            long initialBalance = 100000L;
            long debitAmount = 30000L;
            String transactionId = "tx-kafka-fail";

            Wallet wallet = createWallet(walletId, "u-int-4", initialBalance);
            when(walletPersistencePort.findWalletByIdForUpdate(walletId)).thenReturn(Optional.of(wallet));
            when(walletPersistencePort.saveWallet(any())).thenReturn(wallet);

            // Simulate Kafka failure
            when(kafkaTemplate.send(anyString(), anyString(), any()))
                    .thenReturn(CompletableFuture.failedFuture(
                            new RuntimeException("Kafka broker unreachable")));

            WalletInternalApplicationService service = new WalletInternalApplicationService(
                    walletPersistencePort, distributedLockPort, kafkaProducer);

            // Phải vẫn thành công dù Kafka lỗi
            WalletInternalApplicationService.DebitResult result = service.debitWallet(
                    walletId, debitAmount, transactionId, null);

            assertTrue(result.success());
            assertEquals(initialBalance - debitAmount, result.balanceAfter());
        }
    }
}
