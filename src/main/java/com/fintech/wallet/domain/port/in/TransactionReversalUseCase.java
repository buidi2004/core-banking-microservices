package com.fintech.wallet.domain.port.in;

import com.fintech.wallet.domain.model.Transaction;

/**
 * Input Port: transaction reversal / refund operations.
 * Supports both manual reversal (by support team) and automatic reversal
 * (e.g. when a bank withdrawal fails after wallet balance was deducted).
 */
public interface TransactionReversalUseCase {

    /**
     * Manually reverse a completed transaction (used by support team).
     * Creates a compensating REVERSAL transaction that credits back the source wallet.
     * Marks the original transaction as REVERSED.
     *
     * @param transactionId The original transaction to reverse
     * @param reason Human-readable reason for the reversal
     * @return The newly created reversal transaction
     */
    Transaction reverseTransaction(String transactionId, String reason);

    /**
     * Automatically reverse a failed withdrawal.
     * Called when bank transfer fails after wallet balance was already deducted.
     * Credits the deducted amount back to the user's wallet.
     *
     * @param transactionId The failed withdrawal transaction
     * @return The newly created reversal transaction
     */
    Transaction autoReverseFailedWithdrawal(String transactionId);
}
