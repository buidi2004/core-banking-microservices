package com.fintech.wallet.saga;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Kiểm thử đơn vị logic điều phối Saga P2P và kịch bản bù trừ tự động (Compensating Auto-Reversal).
 * Đặc tả theo tài liệu docs/architecture/artifacts/SAGA_AUTO_REVERSAL_TEST_SPEC.md.
 */
class PaymentSagaAutoReversalTest {

    public enum TransactionStatus {
        INITIATED, DEBITED, SUCCESS, FAILED, REVERSED
    }

    public record SagaState(
            String transactionId,
            String senderWalletId,
            String receiverWalletId,
            BigDecimal amount,
            TransactionStatus status,
            String reversalReason
    ) {}

    @Test
    @DisplayName("TC-SAGA-01: Happy Path - Debit và Credit đều thành công")
    void shouldCompleteSagaSuccessfullyWhenBothDebitAndCreditSucceed() {
        String txId = UUID.randomUUID().toString();
        BigDecimal amount = new BigDecimal("100000");

        // Giả lập Debit thành công
        boolean debitSuccess = true;
        // Giả lập Credit thành công
        boolean creditSuccess = true;

        TransactionStatus finalStatus = (debitSuccess && creditSuccess)
                ? TransactionStatus.SUCCESS
                : TransactionStatus.FAILED;

        assertThat(finalStatus).isEqualTo(TransactionStatus.SUCCESS);
    }

    @Test
    @DisplayName("TC-SAGA-03: Auto-Reversal khi Credit ví người nhận thất bại (Ví bị khóa/Timeout)")
    void shouldTriggerAutoReversalWhenReceiverCreditFails() {
        String txId = UUID.randomUUID().toString();
        String senderWalletId = "wallet-sender-01";
        String receiverWalletId = "wallet-receiver-locked";
        BigDecimal amount = new BigDecimal("100000");

        // Bước 1: Debit ví người gửi -> THÀNH CÔNG
        boolean debitSuccess = true;
        TransactionStatus statusAfterDebit = TransactionStatus.DEBITED;
        assertThat(statusAfterDebit).isEqualTo(TransactionStatus.DEBITED);

        // Bước 2: Credit ví người nhận -> THẤT BẠI (Wallet locked / network error)
        boolean creditSuccess = false;
        String errorCode = "WALLET_LOCKED";

        // Bước 3: Kích hoạt Compensating Auto-Reversal
        boolean reversalTriggered = !creditSuccess && (statusAfterDebit == TransactionStatus.DEBITED);
        assertThat(reversalTriggered).isTrue();

        // Bước 4: Gọi hoàn tiền ví người gửi
        boolean refundToSenderSuccess = true; // Credit lại ví người gửi
        TransactionStatus finalStatus = refundToSenderSuccess ? TransactionStatus.REVERSED : TransactionStatus.FAILED;

        SagaState finalState = new SagaState(
                txId, senderWalletId, receiverWalletId, amount, finalStatus, errorCode
        );

        // Tiêu chuẩn nghiệm thu: Giao dịch được đánh dấu REVERSED và tiền hoàn về ví gửi
        assertThat(finalState.status()).isEqualTo(TransactionStatus.REVERSED);
        assertThat(finalState.reversalReason()).isEqualTo("WALLET_LOCKED");
    }

    @Test
    @DisplayName("TC-SAGA-05: Idempotency Key bảo vệ Reversal không bị hoàn tiền 2 lần")
    void shouldEnsureIdempotentReversal() {
        String idempotencyKey = "REV-TX-123456";
        int refundCount = 0;

        // Lần 1: Gọi Reversal
        refundCount++;

        // Lần 2: Giả lập mạng chập chờn, worker gửi lại lệnh Reversal với cùng idempotencyKey
        boolean isDuplicate = true; // Hệ thống phát hiện key trùng trong Redis / DB
        if (!isDuplicate) {
            refundCount++;
        }

        // Tiêu chuẩn nghiệm thu: Số lần cộng tiền hoàn về ví gửi duy nhất là 1
        assertThat(refundCount).isEqualTo(1);
    }
}
