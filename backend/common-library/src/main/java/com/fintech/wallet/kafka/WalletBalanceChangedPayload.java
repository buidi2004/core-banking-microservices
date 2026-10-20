package com.fintech.wallet.kafka;

import java.math.BigDecimal;

/**
 * Payload chứa thông tin biến động số dư ví, được publish vào topic
 * {@link KafkaTopicConstants#TOPIC_WALLET_BALANCE_CHANGED}.
 *
 * Ledger Service (Agent 4) dùng payload này để hạch toán sổ cái kép:
 *   - side=DEBIT  → ghi Nợ vào tài khoản nguồn
 *   - side=CREDIT → ghi Có vào tài khoản đích
 *
 * @param walletId        Partition key bắt buộc (String) — đảm bảo strict ordering per wallet
 * @param previousBalance số dư trước biến động
 * @param changeAmount    số tiền thay đổi (dương = tăng, âm = giảm)
 * @param newBalance      số dư sau biến động
 * @param currency        đơn vị tiền tệ (VND, USD, ...)
 * @param transactionId   ID giao dịch gây ra biến động (null nếu không áp dụng)
 * @param changeType      LOAN | CREDIT | RESERVE | RELEASE | DEPOSIT | WITHDRAWAL | TRANSFER_OUT | TRANSFER_IN
 */
public record WalletBalanceChangedPayload(
        String walletId,
        BigDecimal previousBalance,
        BigDecimal changeAmount,
        BigDecimal newBalance,
        String currency,
        String transactionId,
        String changeType
) {
    public enum ChangeType {
        DEPOSIT, WITHDRAWAL, TRANSFER_OUT, TRANSFER_IN,
        RESERVE, RELEASE, FEE_CHARGE, ADJUSTMENT
    }

    public static WalletBalanceChangedPayload debit(
            String walletId, BigDecimal previous, BigDecimal amount,
            String currency, String transactionId) {
        BigDecimal newBal = previous.subtract(amount);
        return new WalletBalanceChangedPayload(
                walletId, previous, amount.negate(), newBal, currency, transactionId,
                ChangeType.WITHDRAWAL.name());
    }

    public static WalletBalanceChangedPayload credit(
            String walletId, BigDecimal previous, BigDecimal amount,
            String currency, String transactionId) {
        BigDecimal newBal = previous.add(amount);
        return new WalletBalanceChangedPayload(
                walletId, previous, amount, newBal, currency, transactionId,
                ChangeType.DEPOSIT.name());
    }

    public static WalletBalanceChangedPayload reserve(
            String walletId, BigDecimal previous, BigDecimal amount, String reservationId) {
        BigDecimal newBal = previous; // reserved không làm thay đổi balance thực
        return new WalletBalanceChangedPayload(
                walletId, previous, BigDecimal.ZERO, newBal, "VND", reservationId,
                ChangeType.RESERVE.name());
    }

    public static WalletBalanceChangedPayload release(
            String walletId, BigDecimal previous, BigDecimal amount, String reservationId) {
        BigDecimal newBal = previous;
        return new WalletBalanceChangedPayload(
                walletId, previous, BigDecimal.ZERO, newBal, "VND", reservationId,
                ChangeType.RELEASE.name());
    }
}
