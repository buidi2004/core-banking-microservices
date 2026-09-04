package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.model.AuditLog;
import com.fintech.wallet.domain.model.Money;
import com.fintech.wallet.domain.model.Transaction;
import com.fintech.wallet.domain.model.TransactionStatus;
import com.fintech.wallet.domain.model.Wallet;
import com.fintech.wallet.domain.port.in.TransactionReversalUseCase;
import com.fintech.wallet.domain.port.out.AuditLogPersistencePort;
import com.fintech.wallet.domain.port.out.DistributedLockPort;
import com.fintech.wallet.domain.port.out.NotificationPort;
import com.fintech.wallet.domain.port.out.TransactionPersistencePort;
import com.fintech.wallet.domain.port.out.TransactionalOperationPort;
import com.fintech.wallet.domain.port.out.WalletPersistencePort;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

/**
 * Application Service: TransactionReversalService
 * Handles both manual reversal (support team) and automatic reversal
 * (e.g. when bank withdrawal fails after wallet balance was deducted).
 *
 * A reversal creates a compensating REVERSAL transaction that credits
 * the amount back to the original source wallet, and marks the original
 * transaction as REVERSED.
 */
@Service
public class TransactionReversalService implements TransactionReversalUseCase {

    private static final Logger log = LoggerFactory.getLogger(TransactionReversalService.class);
    private static final long LOCK_TIMEOUT_SECONDS = 30;

    private final TransactionPersistencePort transactionPersistencePort;
    private final WalletPersistencePort walletPersistencePort;
    private final DistributedLockPort distributedLockPort;
    private final TransactionalOperationPort transactionalOperationPort;
    private final NotificationPort notificationPort;
    private final AuditLogPersistencePort auditLogPersistencePort;

    public TransactionReversalService(TransactionPersistencePort transactionPersistencePort,
                                      WalletPersistencePort walletPersistencePort,
                                      DistributedLockPort distributedLockPort,
                                      TransactionalOperationPort transactionalOperationPort,
                                      NotificationPort notificationPort,
                                      AuditLogPersistencePort auditLogPersistencePort) {
        this.transactionPersistencePort = transactionPersistencePort;
        this.walletPersistencePort = walletPersistencePort;
        this.distributedLockPort = distributedLockPort;
        this.transactionalOperationPort = transactionalOperationPort;
        this.notificationPort = notificationPort;
        this.auditLogPersistencePort = auditLogPersistencePort;
    }

    @Override
    public Transaction reverseTransaction(String transactionId, String reason) {
        if (transactionId == null || transactionId.isBlank()) {
            throw new IllegalArgumentException("Transaction ID cannot be null or empty");
        }

        Transaction originalTx = transactionPersistencePort.findTransactionById(transactionId)
                .orElseThrow(() -> new IllegalArgumentException("Transaction not found: " + transactionId));

        if (originalTx.getStatus() != TransactionStatus.SUCCESS) {
            throw new IllegalStateException(
                    "Only SUCCESS transactions can be reversed. Current status: " + originalTx.getStatus());
        }

        // Determine which wallet to credit back
        String refundWalletId = resolveRefundWalletId(originalTx);
        if (refundWalletId == null) {
            throw new IllegalStateException("Cannot determine refund wallet for transaction: " + transactionId);
        }

        return executeReversal(originalTx, refundWalletId, reason);
    }

    @Override
    public Transaction autoReverseFailedWithdrawal(String transactionId) {
        if (transactionId == null || transactionId.isBlank()) {
            throw new IllegalArgumentException("Transaction ID cannot be null or empty");
        }

        Transaction originalTx = transactionPersistencePort.findTransactionById(transactionId)
                .orElseThrow(() -> new IllegalArgumentException("Transaction not found: " + transactionId));

        // For auto-reverse, the withdrawal succeeded in our system (wallet debited)
        // but failed at the bank side. The original tx is SUCCESS in our DB.
        if (originalTx.getStatus() != TransactionStatus.SUCCESS) {
            throw new IllegalStateException(
                    "Auto-reverse requires a SUCCESS transaction. Current status: " + originalTx.getStatus());
        }

        String sourceWalletId = originalTx.getSourceWalletId();
        if (sourceWalletId == null) {
            throw new IllegalStateException("Withdrawal transaction has no source wallet: " + transactionId);
        }

        return executeReversal(originalTx, sourceWalletId, "Auto-reverse: bank transfer failed");
    }

    private Transaction executeReversal(Transaction originalTx, String refundWalletId, String reason) {
        String lockKey = "lock:wallet:" + refundWalletId;

        return distributedLockPort.executeWithLock(lockKey, LOCK_TIMEOUT_SECONDS, () -> {
            // Re-validate inside lock
            Transaction freshTx = transactionPersistencePort.findTransactionById(originalTx.getId())
                    .orElseThrow(() -> new IllegalArgumentException("Transaction not found: " + originalTx.getId()));

            if (freshTx.getStatus() == TransactionStatus.REVERSED) {
                throw new IllegalStateException("Transaction already reversed: " + originalTx.getId());
            }

            Wallet wallet = walletPersistencePort.findWalletById(refundWalletId)
                    .orElseThrow(() -> new IllegalArgumentException("Wallet not found: " + refundWalletId));

            Transaction reversalTx = Transaction.createReversal(
                    originalTx.getId(), refundWalletId, originalTx.getAmount());

            // The original deduction was amount + fee. Refund both so the user
            // doesn't permanently lose the fee amount on a failed/reversed transaction.
            Money refundAmount = originalTx.getAmount();
            if (originalTx.getFeeAmount() != null
                    && originalTx.getFeeAmount().getAmount() != null
                    && originalTx.getFeeAmount().getAmount().compareTo(java.math.BigDecimal.ZERO) > 0) {
                refundAmount = originalTx.getAmount().add(originalTx.getFeeAmount());
            }
            final Money finalRefundAmount = refundAmount;

            Transaction savedReversalTx;
            try {
                // Credit the original amount + fee back to the wallet
                wallet.deposit(finalRefundAmount);

                savedReversalTx = transactionalOperationPort.executeInTransaction(() -> {
                    walletPersistencePort.saveWallet(wallet);
                    freshTx.markReversed();
                    transactionPersistencePort.saveTransaction(freshTx);
                    reversalTx.setFeeAmount(originalTx.getFeeAmount());
                    reversalTx.markSuccess();
                    return transactionPersistencePort.saveTransaction(reversalTx);
                });
            } catch (Exception e) {
                reversalTx.markFailed();
                try {
                    transactionPersistencePort.saveTransaction(reversalTx);
                } catch (Exception saveEx) {
                    log.error("Failed to save FAILED reversal transaction for originalTxId={}", originalTx.getId(), saveEx);
                }
                throw e;
            }

            // Fire-and-forget notification
            if (notificationPort != null) {
                try {
                    notificationPort.notifyTransactionCompleted(savedReversalTx, wallet, null, null, null);
                } catch (Exception e) {
                    log.warn("Notification failed for reversal transaction={}", savedReversalTx.getId(), e);
                }
            }

            // Audit log
            if (auditLogPersistencePort != null) {
                try {
                    auditLogPersistencePort.saveAuditLog(AuditLog.record(
                            wallet.getOwnerId(), "127.0.0.1", "REVERSAL",
                            "originalTxId:" + originalTx.getId() + ",reversalTxId:" + savedReversalTx.getId()
                                    + ",reason:" + reason, java.util.UUID.randomUUID().toString()));
                } catch (Exception e) {
                    log.warn("Failed to record audit log for reversal: {}", e.getMessage());
                }
            }

            log.info("Transaction reversed: originalTxId={}, reversalTxId={}, amount={}, reason={}",
                    originalTx.getId(), savedReversalTx.getId(), originalTx.getAmount(), reason);

            return savedReversalTx;
        });
    }

    /**
     * Determines which wallet should receive the refund based on transaction type.
     * - WITHDRAWAL: refund to sourceWalletId (the wallet that was debited)
     * - TRANSFER: refund to sourceWalletId
     * - DEPOSIT: refund to targetWalletId (unusual, but handled)
     */
    private String resolveRefundWalletId(Transaction tx) {
        if (tx.getSourceWalletId() != null) {
            return tx.getSourceWalletId();
        }
        return tx.getTargetWalletId();
    }
}
