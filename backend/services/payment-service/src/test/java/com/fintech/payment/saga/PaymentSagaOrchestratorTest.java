package com.fintech.payment.saga;

import com.fintech.payment.domain.entity.OutboxEvent;
import com.fintech.payment.domain.entity.Transaction;
import com.fintech.payment.grpc.WalletGrpcClient;
import com.fintech.payment.grpc.dto.WalletBalanceResult;
import com.fintech.payment.grpc.dto.WalletInfoResult;
import com.fintech.payment.repository.OutboxEventRepository;
import com.fintech.payment.repository.TransactionRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.ArgumentMatcher;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ValueOperations;

import java.time.Duration;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.atLeastOnce;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class PaymentSagaOrchestratorTest {

    @Mock private WalletGrpcClient walletGrpcClient;
    @Mock private TransactionRepository transactionRepository;
    @Mock private OutboxEventRepository outboxEventRepository;
    @Mock private ObjectMapper objectMapper;
    @Mock private StringRedisTemplate redisTemplate;
    @Mock private ValueOperations<String, String> valueOperations;

    private PaymentSagaOrchestrator saga;
    private Transaction fixedTx;

    private static final String SENDER_USER = "user-sender";
    private static final String RECEIVER_USER = "user-receiver";
    private static final String SENDER_WALLET = "wallet-sender";
    private static final String RECEIVER_WALLET = "wallet-receiver";
    private static final String IDEM_KEY = "idem-123";
    private static final Long AMOUNT = 100_000L;

    @BeforeEach
    void setUp() {
        when(redisTemplate.opsForValue()).thenReturn(valueOperations);
        when(valueOperations.setIfAbsent(anyString(), anyString(), any(Duration.class))).thenReturn(true);

        fixedTx = new Transaction();
        fixedTx.setId("tx-test-1");
        fixedTx.setTransactionCode("TXN-TEST1");
        fixedTx.setStatus("INITIATED");

        when(transactionRepository.save(any(Transaction.class))).thenAnswer(inv -> {
            Transaction t = inv.getArgument(0);
            t.setId("tx-test-1");
            t.setTransactionCode("TXN-TEST1");
            return fixedTx;
        });
        when(transactionRepository.findById(anyString())).thenReturn(Optional.of(fixedTx));
        when(outboxEventRepository.save(any(OutboxEvent.class))).thenAnswer(inv -> inv.getArgument(0));

        saga = new PaymentSagaOrchestrator(walletGrpcClient, transactionRepository, outboxEventRepository, objectMapper, redisTemplate);
    }

    private void givenWalletsResolved() {
        when(walletGrpcClient.getWalletByUserId(SENDER_USER))
            .thenReturn(WalletInfoResult.builder().found(true).walletId(SENDER_WALLET).build());
        when(walletGrpcClient.getWalletByUserId(RECEIVER_USER))
            .thenReturn(WalletInfoResult.builder().found(true).walletId(RECEIVER_WALLET).build());
    }

    private void givenDebitSucceeds() {
        when(walletGrpcClient.debit(eq(SENDER_WALLET), eq(AMOUNT), anyString(), eq(IDEM_KEY)))
            .thenReturn(WalletBalanceResult.builder().success(true).balanceAfter(900_000L).build());
    }

    private void givenReceiverCreditFails(String errorCode) {
        when(walletGrpcClient.credit(eq(RECEIVER_WALLET), eq(AMOUNT), anyString(), anyString()))
            .thenReturn(WalletBalanceResult.builder().success(false).errorCode(errorCode).build());
    }

    private void givenSenderCreditSucceeds() {
        when(walletGrpcClient.credit(eq(SENDER_WALLET), eq(AMOUNT), anyString(), anyString()))
            .thenReturn(WalletBalanceResult.builder().success(true).balanceAfter(1_000_000L).build());
    }

    private boolean outboxHas(ArgumentCaptor<OutboxEvent> captor, String eventType) {
        return captor.getAllValues().stream().anyMatch(e -> eventType.equals(e.getEventType()));
    }

    @Test
    @DisplayName("TC-SAGA-01: Luong thanh cong - Debit gui xong, Credit nhan xong -> SUCCESS")
    void shouldCompleteP2PTransferSuccessfully() {
        givenWalletsResolved();
        givenDebitSucceeds();
        when(walletGrpcClient.credit(eq(RECEIVER_WALLET), eq(AMOUNT), anyString(), anyString()))
            .thenReturn(WalletBalanceResult.builder().success(true).balanceAfter(300_000L).build());

        SagaContext ctx = saga.transferP2p(SENDER_USER, RECEIVER_USER, AMOUNT, "VND", null, IDEM_KEY);

        assertThat(ctx.getStatus()).isEqualTo("SUCCESS");
        assertThat(ctx.getTransactionId()).isEqualTo("tx-test-1");

        verify(walletGrpcClient, times(1)).debit(eq(SENDER_WALLET), eq(AMOUNT), anyString(), eq(IDEM_KEY));
        verify(walletGrpcClient, times(1)).credit(eq(RECEIVER_WALLET), eq(AMOUNT), anyString(), anyString());
        verify(walletGrpcClient, never()).credit(eq(SENDER_WALLET), anyLong(), anyString(), anyString());

        ArgumentCaptor<OutboxEvent> captor = ArgumentCaptor.forClass(OutboxEvent.class);
        verify(outboxEventRepository, atLeastOnce()).save(captor.capture());
        assertThat(outboxHas(captor, "TransactionCompletedEvent")).isTrue();
    }

    @Test
    @DisplayName("TC-SAGA-02: Debit that bai (khong du so du) -> ket thuc ngay, khong goi Credit -> FAILED")
    void shouldFailFastWhenDebitFails() {
        givenWalletsResolved();
        when(walletGrpcClient.debit(eq(SENDER_WALLET), eq(AMOUNT), anyString(), eq(IDEM_KEY)))
            .thenReturn(WalletBalanceResult.builder().success(false)
                .errorCode("DEBIT_INSUFFICIENT_BALANCE")
                .errorMessage("Khong du so du")
                .build());

        SagaContext ctx = saga.transferP2p(SENDER_USER, RECEIVER_USER, AMOUNT, "VND", null, IDEM_KEY);

        assertThat(ctx.getStatus()).isEqualTo("FAILED");
        assertThat(ctx.getFailureReason()).isEqualTo("Khong du so du");

        verify(walletGrpcClient, times(1)).debit(eq(SENDER_WALLET), eq(AMOUNT), anyString(), eq(IDEM_KEY));
        verify(walletGrpcClient, never()).credit(anyString(), anyLong(), anyString(), anyString());

        ArgumentCaptor<OutboxEvent> captor = ArgumentCaptor.forClass(OutboxEvent.class);
        verify(outboxEventRepository, atLeastOnce()).save(captor.capture());
        assertThat(outboxHas(captor, "TransactionFailedEvent")).isTrue();
    }

    @Test
    @DisplayName("TC-SAGA-03: Auto-Reversal khi Credit vi nhan that bai -> hoan tien vi gui -> REVERSED")
    void shouldAutoReverseSenderWhenReceiverCreditFails() {
        givenWalletsResolved();
        givenDebitSucceeds();
        givenReceiverCreditFails("WALLET_STATUS_LOCKED");
        givenSenderCreditSucceeds();

        SagaContext ctx = saga.transferP2p(SENDER_USER, RECEIVER_USER, AMOUNT, "VND", null, IDEM_KEY);

        assertThat(ctx.getStatus()).isEqualTo("REVERSED");
        assertThat(ctx.isReversed()).isTrue();

        verify(walletGrpcClient, times(1)).debit(eq(SENDER_WALLET), eq(AMOUNT), anyString(), eq(IDEM_KEY));
        verify(walletGrpcClient, times(1)).credit(eq(RECEIVER_WALLET), eq(AMOUNT), anyString(), anyString());
        verify(walletGrpcClient, times(1)).credit(
            eq(SENDER_WALLET),
            eq(AMOUNT),
            anyString(),
            argThat((ArgumentMatcher<String>) key -> key != null && (key.startsWith("REV-") || key.contains("reversal")))
        );

        ArgumentCaptor<OutboxEvent> captor = ArgumentCaptor.forClass(OutboxEvent.class);
        verify(outboxEventRepository, atLeastOnce()).save(captor.capture());
        assertThat(outboxHas(captor, "TransactionReversedEvent")).isTrue();
    }

    @Test
    @DisplayName("TC-SAGA-04: Auto-Reversal khi Credit bi timeout (ngat mang) -> hoan tien vi gui -> REVERSED")
    void shouldAutoReverseSenderWhenReceiverCreditTimeouts() {
        givenWalletsResolved();
        givenDebitSucceeds();
        when(walletGrpcClient.credit(eq(RECEIVER_WALLET), eq(AMOUNT), anyString(), anyString()))
            .thenThrow(new RuntimeException("gRPC DEADLINE_EXCEEDED"));
        givenSenderCreditSucceeds();

        SagaContext ctx = saga.transferP2p(SENDER_USER, RECEIVER_USER, AMOUNT, "VND", null, IDEM_KEY);

        assertThat(ctx.getStatus()).isEqualTo("REVERSED");
        assertThat(ctx.isReversed()).isTrue();

        verify(walletGrpcClient, times(1)).debit(eq(SENDER_WALLET), eq(AMOUNT), anyString(), eq(IDEM_KEY));
        verify(walletGrpcClient, times(1)).credit(eq(RECEIVER_WALLET), eq(AMOUNT), anyString(), anyString());
        verify(walletGrpcClient, times(1)).credit(eq(SENDER_WALLET), eq(AMOUNT), anyString(), anyString());

        ArgumentCaptor<OutboxEvent> captor = ArgumentCaptor.forClass(OutboxEvent.class);
        verify(outboxEventRepository, atLeastOnce()).save(captor.capture());
        assertThat(outboxHas(captor, "TransactionReversedEvent")).isTrue();
    }
}
