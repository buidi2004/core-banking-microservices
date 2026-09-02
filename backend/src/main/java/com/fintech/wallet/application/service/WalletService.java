package com.fintech.wallet.application.service;

import org.springframework.beans.factory.annotation.Autowired;

import org.springframework.beans.factory.annotation.Autowired;

import com.fintech.wallet.domain.exception.InvalidMoneyException;
import com.fintech.wallet.domain.exception.TransactionLimitExceededException;
import com.fintech.wallet.domain.exception.WalletNotFoundException;
import com.fintech.wallet.domain.model.AuditLog;
import com.fintech.wallet.domain.model.KycStatus;
import com.fintech.wallet.domain.model.Money;
import com.fintech.wallet.domain.model.Transaction;
import com.fintech.wallet.domain.model.TransactionStatus;
import com.fintech.wallet.domain.model.TransactionType;
import com.fintech.wallet.domain.model.User;
import com.fintech.wallet.domain.model.Wallet;
import com.fintech.wallet.domain.port.in.DepositMoneyUseCase;
import com.fintech.wallet.domain.port.in.GetWalletUseCase;
import com.fintech.wallet.domain.port.in.TransactionQueryUseCase;
import com.fintech.wallet.domain.port.in.LedgerUseCase;
import com.fintech.wallet.domain.port.in.TransferMoneyUseCase;
import com.fintech.wallet.domain.port.in.WithdrawMoneyUseCase;
import com.fintech.wallet.domain.port.out.AuditLogPersistencePort;
import com.fintech.wallet.domain.port.out.BankGatewayPort;
import com.fintech.wallet.domain.port.out.ClientInfoPort;
import com.fintech.wallet.domain.port.out.DistributedLockPort;
import com.fintech.wallet.domain.port.out.NotificationPort;
import com.fintech.wallet.domain.port.out.TransactionPersistencePort;
import com.fintech.wallet.domain.port.out.TransactionalOperationPort;
import com.fintech.wallet.domain.port.out.UserPersistencePort;
import com.fintech.wallet.domain.port.out.WalletPersistencePort;
import com.fintech.wallet.domain.port.out.KycPersistencePort;
import com.fintech.wallet.domain.util.NameMaskingUtils;
import com.fintech.wallet.presentation.response.RecipientInfoResponse;
import com.fintech.wallet.domain.model.TransactionEvent;
import com.fintech.wallet.domain.port.out.TransactionEventPublisherPort;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.Collections;
import java.util.List;
import java.util.Optional;

/**
 * Application Service: WalletService
 * Coordinates Domain entities & calls Output Ports.
 * Implements Input Ports (TransferMoneyUseCase, GetWalletUseCase, DepositMoneyUseCase, WithdrawMoneyUseCase, TransactionQueryUseCase).
 */
public class WalletService implements TransferMoneyUseCase, GetWalletUseCase, DepositMoneyUseCase, WithdrawMoneyUseCase, TransactionQueryUseCase {

    private static final Logger log = LoggerFactory.getLogger(WalletService.class);

    private static final long LOCK_TIMEOUT_SECONDS = 30;

    private final WalletPersistencePort walletPersistencePort;
    private final TransactionPersistencePort transactionPersistencePort;
    private final DistributedLockPort distributedLockPort;
    private final NotificationPort notificationPort;
    private final TransactionalOperationPort transactionalOperationPort;
    private final BankGatewayPort bankGatewayPort;
    private final UserPersistencePort userPersistencePort;
    private final AuditLogPersistencePort auditLogPersistencePort;
    private final ClientInfoPort clientInfoPort;
    private final LedgerUseCase ledgerUseCase;
    private final TransactionEventPublisherPort transactionEventPublisherPort;
    
    @Autowired(required = false)
    private KycPersistencePort kycPersistencePort;

    @Autowired(required = false)
    private com.fintech.wallet.domain.port.in.FeeEstimationUseCase feeEstimationUseCase;

    @Autowired
    public WalletService(WalletPersistencePort walletPersistencePort,
                         TransactionPersistencePort transactionPersistencePort,
                         DistributedLockPort distributedLockPort,
                         NotificationPort notificationPort,
                         TransactionalOperationPort transactionalOperationPort,
                         BankGatewayPort bankGatewayPort,
                         UserPersistencePort userPersistencePort,
                         AuditLogPersistencePort auditLogPersistencePort,
                         ClientInfoPort clientInfoPort,
                         LedgerUseCase ledgerUseCase,
                         TransactionEventPublisherPort transactionEventPublisherPort) {
        this.walletPersistencePort = walletPersistencePort;
        this.transactionPersistencePort = transactionPersistencePort;
        this.distributedLockPort = distributedLockPort;
        this.notificationPort = notificationPort;
        this.transactionalOperationPort = transactionalOperationPort;
        this.bankGatewayPort = bankGatewayPort;
        this.userPersistencePort = userPersistencePort;
        this.auditLogPersistencePort = auditLogPersistencePort;
        this.clientInfoPort = clientInfoPort;
        this.ledgerUseCase = ledgerUseCase;
        this.transactionEventPublisherPort = transactionEventPublisherPort;
    }

    public WalletService(WalletPersistencePort walletPersistencePort,
                         TransactionPersistencePort transactionPersistencePort,
                         DistributedLockPort distributedLockPort,
                         NotificationPort notificationPort,
                         TransactionalOperationPort transactionalOperationPort,
                         BankGatewayPort bankGatewayPort) {
        this(walletPersistencePort, transactionPersistencePort, distributedLockPort, notificationPort, transactionalOperationPort, bankGatewayPort, null, null, null, null, null);
    }

    public WalletService(WalletPersistencePort walletPersistencePort,
                         TransactionPersistencePort transactionPersistencePort,
                         DistributedLockPort distributedLockPort,
                         NotificationPort notificationPort,
                         TransactionalOperationPort transactionalOperationPort) {
        this(walletPersistencePort, transactionPersistencePort, distributedLockPort, notificationPort, transactionalOperationPort, null, null, null, null, null, null);
    }



    @Override
    public Wallet getWalletById(String walletId) {
        if (walletId == null || walletId.isBlank()) {
            throw new IllegalArgumentException("Wallet ID cannot be null or empty");
        }
        return walletPersistencePort.findWalletById(walletId)
                .orElseThrow(() -> new WalletNotFoundException("Wallet with ID " + walletId + " not found"));
    }

    @Override
    public Optional<Wallet> findWalletByOwnerId(String ownerId) {
        if (ownerId == null || ownerId.isBlank()) {
            return Optional.empty();
        }
        return walletPersistencePort.findWalletByOwnerId(ownerId);
    }

    // BUG #1 fix: Distributed lock prevents TOCTOU race condition on createWallet
    @Override
    public Wallet createWallet(String ownerId, String currency) {
        if (ownerId == null || ownerId.isBlank()) {
            throw new IllegalArgumentException("Owner ID cannot be null or empty");
        }
        if (currency == null || currency.isBlank()) {
            throw new IllegalArgumentException("Currency cannot be null or empty");
        }

        String lockKey = "lock:create-wallet:" + ownerId;
        return distributedLockPort.executeWithLock(lockKey, LOCK_TIMEOUT_SECONDS, () -> {
            Optional<Wallet> existing = walletPersistencePort.findWalletByOwnerId(ownerId);
            if (existing.isPresent()) {
                throw new IllegalArgumentException("Wallet already exists for owner: " + ownerId);
            }
            Wallet wallet = Wallet.createNew(ownerId, currency);
            return walletPersistencePort.saveWallet(wallet);
        });
    }

    @Override
    public Wallet getWalletByUserIdAndCurrency(String userId, String currency) {
        if (userId == null || userId.isBlank()) {
            throw new IllegalArgumentException("User ID cannot be null or empty");
        }
        if (currency == null || currency.isBlank()) {
            throw new IllegalArgumentException("Currency cannot be null or empty");
        }
        Wallet wallet = walletPersistencePort.findWalletByOwnerId(userId)
                .orElseThrow(() -> new WalletNotFoundException("No wallet found for user: " + userId));
        if (!wallet.getBalance().getCurrency().equalsIgnoreCase(currency)) {
            throw new WalletNotFoundException(
                    "No " + currency + " wallet found for user: " + userId);
        }
        return wallet;
    }

    @Override
    public RecipientInfoResponse getRecipientInfo(String walletId, String phoneNumber) {
        Wallet wallet;
        User user;

        if (walletId != null && !walletId.isBlank()) {
            wallet = getWalletById(walletId);
            user = userPersistencePort.findUserById(wallet.getOwnerId())
                    .orElseThrow(() -> new IllegalArgumentException("Wallet owner not found"));
        } else if (phoneNumber != null && !phoneNumber.isBlank()) {
            user = userPersistencePort.findUserByPhoneNumber(phoneNumber)
                    .orElseThrow(() -> new IllegalArgumentException("User with phone number " + phoneNumber + " not found"));
            wallet = getWalletByUserIdAndCurrency(user.getId(), "VND");
        } else {
            throw new IllegalArgumentException("Either walletId or phoneNumber must be provided");
        }

        String rawName = user.getFullName();
        if (rawName == null || rawName.isBlank()) {
            if (kycPersistencePort != null) {
                var kycOpt = kycPersistencePort.findKycByUserId(user.getId());
                if (kycOpt.isPresent() && kycOpt.get().getFullName() != null && !kycOpt.get().getFullName().isBlank()) {
                    rawName = kycOpt.get().getFullName();
                }
            }
        }
        if (rawName == null || rawName.isBlank()) {
            String phone = user.getPhoneNumber();
            rawName = "NGƯỜI DÙNG " + (phone.length() > 4 ? phone.substring(phone.length() - 4) : phone);
        }

        // We still mask it for maskedName but also pass the full rawName back for the frontend
        String maskedName = NameMaskingUtils.maskName(rawName);
        return new RecipientInfoResponse(wallet.getId(), user.getPhoneNumber(), maskedName, rawName);
    }

    @Override
    public Transaction deposit(String requestId, String walletId, Money amount) {
        if (walletId == null || walletId.isBlank()) {
            throw new IllegalArgumentException("Wallet ID cannot be null or empty");
        }
        if (amount == null) {
            throw new InvalidMoneyException("Deposit amount cannot be null");
        }

        // Bug #2 fix: Idempotency check — only return if SUCCESS, allow retry for FAILED
        if (requestId != null && !requestId.isBlank()) {
            Optional<Transaction> existingTx = transactionPersistencePort.findTransactionByRequestId(requestId);
            if (existingTx.isPresent()) {
                return existingTx.get();
            }
        }

        String lockKey = "lock:wallet:" + walletId;
        return distributedLockPort.executeWithLock(lockKey, LOCK_TIMEOUT_SECONDS, () -> {
            // Re-check inside lock
            if (requestId != null && !requestId.isBlank()) {
                Optional<Transaction> existingTx = transactionPersistencePort.findTransactionByRequestId(requestId);
                if (existingTx.isPresent()) {
                    return existingTx.get();
                }
            }

            Wallet wallet = getWalletById(walletId);

            // Currency validation
            if (!wallet.getBalance().getCurrency().equalsIgnoreCase(amount.getCurrency())) {
                throw new InvalidMoneyException("Deposit currency mismatch: wallet uses "
                        + wallet.getBalance().getCurrency() + " but deposit amount is in " + amount.getCurrency());
            }

            Transaction transaction = Transaction.createDeposit(requestId, walletId, amount);

            // Bug #1 fix: wrap all DB writes in a single transaction for atomicity
            // Bug #4 fix: notification moved outside the business try-catch
            Transaction savedTx;
            try {
                wallet.deposit(amount);

                savedTx = transactionalOperationPort.executeInTransaction(() -> {
                    walletPersistencePort.saveWallet(wallet);
                    transaction.markSuccess();
                    return transactionPersistencePort.saveTransaction(transaction);
                });
            } catch (Exception e) {
                // Save FAILED record (outside the rolled-back transaction)
                transaction.markFailed();
                try {
                    transactionPersistencePort.saveTransaction(transaction);
                } catch (Exception saveEx) {
                    log.error("Failed to save FAILED transaction record for requestId={}", requestId, saveEx);
                }
                throw e;
            }

            // Bug #4 fix: notification is fire-and-forget, never affects business result
            // ISSUE #9 fix: use in-memory wallet directly (already has correct balance), avoid extra DB query
            safeNotify(savedTx, wallet);
            return savedTx;
        });
    }

    @Override
    public Transaction transfer(String requestId, String sourceWalletId, String targetWalletId, String bankCode, Money amount, String note) {
        if (sourceWalletId == null || sourceWalletId.isBlank() || targetWalletId == null || targetWalletId.isBlank()) {
            throw new IllegalArgumentException("Source and target wallet IDs must not be empty");
        }
        if (sourceWalletId.equals(targetWalletId)) {
            throw new IllegalArgumentException("Không thể chuyển tiền vào chính tài khoản của bạn. Vui lòng nhập số tài khoản người nhận khác.");
        }
        if (amount == null) {
            throw new InvalidMoneyException("Transfer amount cannot be null");
        }

        validatePerTransactionLimits(amount);

        // Fix: Idempotency — return the exact previous transaction state
        if (requestId != null && !requestId.isBlank()) {
            Optional<Transaction> existingTx = transactionPersistencePort.findTransactionByRequestId(requestId);
            if (existingTx.isPresent()) {
                return existingTx.get();
            }
        }

        // Pre-validate daily and monthly limits before acquiring locks
        Wallet initialSourceWallet = getWalletById(sourceWalletId);
        validateDailyTransactionLimit(initialSourceWallet.getOwnerId(), sourceWalletId, amount);

        // Lock ordering based on ID comparison to prevent deadlocks
        String firstLockId = sourceWalletId.compareTo(targetWalletId) < 0 ? sourceWalletId : targetWalletId;
        String secondLockId = sourceWalletId.compareTo(targetWalletId) < 0 ? targetWalletId : sourceWalletId;

        String lockKey1 = "lock:wallet:" + firstLockId;
        String lockKey2 = "lock:wallet:" + secondLockId;

        return distributedLockPort.executeWithLock(lockKey1, LOCK_TIMEOUT_SECONDS, () ->
            distributedLockPort.executeWithLock(lockKey2, LOCK_TIMEOUT_SECONDS, () -> {
                // Re-check inside lock
                if (requestId != null && !requestId.isBlank()) {
                    Optional<Transaction> existingTx = transactionPersistencePort.findTransactionByRequestId(requestId);
                    if (existingTx.isPresent()) {
                        return existingTx.get();
                    }
                }

                Wallet sourceWallet = getWalletById(sourceWalletId);
                Wallet targetWallet = getWalletById(targetWalletId);

                // Enforce daily limit for source wallet owner
                validateDailyTransactionLimit(sourceWallet.getOwnerId(), sourceWalletId, amount);

                // Currency validation upfront to prevent partial mutation
                if (!sourceWallet.getBalance().getCurrency().equalsIgnoreCase(targetWallet.getBalance().getCurrency())) {
                    throw new InvalidMoneyException("Currency mismatch between wallets: "
                            + sourceWallet.getBalance().getCurrency() + " vs " + targetWallet.getBalance().getCurrency());
                }
                if (!sourceWallet.getBalance().getCurrency().equalsIgnoreCase(amount.getCurrency())) {
                    throw new InvalidMoneyException("Transfer amount currency (" + amount.getCurrency()
                            + ") does not match wallet currency (" + sourceWallet.getBalance().getCurrency() + ")");
                }

                Transaction transaction = Transaction.createTransfer(requestId, sourceWalletId, targetWalletId, amount, note);
                transaction.setBankCode(bankCode);

                Money totalDeduction = amount;
                if (feeEstimationUseCase != null) {
                    com.fintech.wallet.domain.model.FeeEstimate feeEstimate = feeEstimationUseCase.estimateFee(
                            sourceWallet.getOwnerId(),
                            com.fintech.wallet.domain.model.TransactionType.TRANSFER,
                            amount);
                    if (feeEstimate.getFeeAmount().compareTo(java.math.BigDecimal.ZERO) > 0) {
                        Money fee = Money.of(feeEstimate.getFeeAmount(), amount.getCurrency());
                        totalDeduction = amount.add(fee);
                        transaction = Transaction.createTransfer(requestId, sourceWalletId, targetWalletId, amount, note + " (Fee: " + feeEstimate.getFeeAmount() + " " + amount.getCurrency() + ")");
                        transaction.setBankCode(bankCode);
                        transaction.setFeeAmount(fee);
                    }
                }

                final Transaction finalTransaction = transaction;
                Transaction savedTx;
                try {
                    sourceWallet.withdraw(totalDeduction);
                    targetWallet.deposit(amount);

                    savedTx = transactionalOperationPort.executeInTransaction(() -> {
                        walletPersistencePort.saveWallet(sourceWallet);
                        walletPersistencePort.saveWallet(targetWallet);
                        finalTransaction.markSuccess();
                        return transactionPersistencePort.saveTransaction(finalTransaction);
                    });
                } catch (Exception e) {
                    finalTransaction.markFailed();
                    try {
                        transactionPersistencePort.saveTransaction(finalTransaction);
                    } catch (Exception saveEx) {
                        log.error("Failed to save FAILED transaction record for requestId={}", requestId, saveEx);
                    }
                    throw e;
                }

                // Publish Transaction Event instead of direct notify and audit
                TransactionEvent event = new TransactionEvent(
                        savedTx.getId(),
                        savedTx.getType().name(),
                        savedTx.getStatus().name(),
                        savedTx.getSourceWalletId(),
                        savedTx.getTargetWalletId(),
                        savedTx.getAmount().getAmount(),
                        savedTx.getAmount().getCurrency()
                );
                if (transactionEventPublisherPort != null) {
                    transactionEventPublisherPort.publishTransactionEvent(event);
                } else {
                    safeNotify(savedTx, sourceWallet);
                    safeNotify(savedTx, targetWallet);
                    recordAuditLog(sourceWallet.getOwnerId(), "TRANSFER", "txId:" + savedTx.getId() + ",amount:" + amount.getAmount());
                }
                
                return savedTx;
            })
        );
    }

    @Override
    public Transaction withdraw(String requestId, String userId, String walletId, String bankAccountId, Money amount) {
        if (walletId == null || walletId.isBlank()) {
            throw new IllegalArgumentException("Wallet ID cannot be null or empty");
        }
        if (amount == null) {
            throw new InvalidMoneyException("Withdrawal amount cannot be null");
        }

        // Idempotency check
        if (requestId != null && !requestId.isBlank()) {
            Optional<Transaction> existingTx = transactionPersistencePort.findTransactionByRequestId(requestId);
            if (existingTx.isPresent()) {
                return existingTx.get();
            }
        }

        String lockKey = "lock:wallet:" + walletId;
        Transaction finalSavedTx = distributedLockPort.executeWithLock(lockKey, LOCK_TIMEOUT_SECONDS, () -> {
            Wallet wallet = getWalletById(walletId);

            if (!wallet.getOwnerId().equals(userId)) {
                throw new IllegalArgumentException("Unauthorized wallet access for user: " + userId);
            }

            // Enforce daily limit for withdrawing user
            validateDailyTransactionLimit(userId, walletId, amount);

            if (!wallet.getBalance().getCurrency().equalsIgnoreCase(amount.getCurrency())) {
                throw new InvalidMoneyException("Withdrawal currency mismatch: wallet uses "
                        + wallet.getBalance().getCurrency() + " but withdrawal amount is in " + amount.getCurrency());
            }

            Transaction transaction = Transaction.createWithdrawal(requestId, walletId, amount);

            Money totalDeduction = amount;
            if (feeEstimationUseCase != null) {
                com.fintech.wallet.domain.model.FeeEstimate feeEstimate = feeEstimationUseCase.estimateFee(
                        wallet.getOwnerId(),
                        com.fintech.wallet.domain.model.TransactionType.WITHDRAWAL,
                        amount);
                if (feeEstimate.getFeeAmount().compareTo(java.math.BigDecimal.ZERO) > 0) {
                    Money fee = Money.of(feeEstimate.getFeeAmount(), amount.getCurrency());
                    totalDeduction = amount.add(fee);
                    transaction = Transaction.createWithdrawal(requestId, walletId, amount);
                    // Add fee to note
                    transaction = new Transaction(transaction.getId(), transaction.getRequestId(), transaction.getSourceWalletId(), transaction.getTargetWalletId(), transaction.getAmount(), transaction.getType(), transaction.getStatus(), transaction.getCreatedAt(), null, "Fee: " + feeEstimate.getFeeAmount() + " " + amount.getCurrency());
                    transaction.setFeeAmount(fee);
                }
            }

            final Transaction finalTransaction = transaction;
            Transaction savedTx;
            try {
                wallet.withdraw(totalDeduction);

                savedTx = transactionalOperationPort.executeInTransaction(() -> {
                    walletPersistencePort.saveWallet(wallet);
                    finalTransaction.markSuccess();
                    return transactionPersistencePort.saveTransaction(finalTransaction);
                });
            } catch (Exception e) {
                finalTransaction.markFailed();
                try {
                    transactionPersistencePort.saveTransaction(finalTransaction);
                } catch (Exception saveEx) {
                    log.error("Failed to save FAILED transaction record for requestId={}", requestId, saveEx);
                }
                throw e;
            }

            if (transactionEventPublisherPort != null) {
                transactionEventPublisherPort.publishTransactionEvent(new TransactionEvent(
                        savedTx.getId(),
                        savedTx.getType().name(),
                        savedTx.getStatus().name(),
                        savedTx.getSourceWalletId(),
                        savedTx.getTargetWalletId(),
                        savedTx.getAmount().getAmount(),
                        savedTx.getAmount().getCurrency()
                ));
            } else {
                safeNotify(savedTx, wallet);
            }
            return savedTx;
        });
        
        // Execute bank transfer OUTSIDE the lock to prevent lock timeouts on slow bank APIs
        if (bankGatewayPort != null) {
            try {
                bankGatewayPort.transferToBank(bankAccountId, amount, finalSavedTx.getId());
            } catch (Exception bankEx) {
                log.error("Bank transfer failed for txId={}, bankAccountId={}. Initiating auto-reverse.",
                        finalSavedTx.getId(), bankAccountId, bankEx);
                // Auto-reverse: must re-acquire lock to safely update balance
                distributedLockPort.executeWithLock(lockKey, LOCK_TIMEOUT_SECONDS, () -> {
                    Wallet walletToReverse = getWalletById(walletId);
                    try {
                        walletToReverse.deposit(amount);
                        transactionalOperationPort.executeInTransaction(() -> {
                            walletPersistencePort.saveWallet(walletToReverse);
                            finalSavedTx.markReversed();
                            transactionPersistencePort.saveTransaction(finalSavedTx);
                            Transaction reversalTx = Transaction.createReversal(
                                    finalSavedTx.getId(), walletId, amount);
                            reversalTx.markSuccess();
                            return transactionPersistencePort.saveTransaction(reversalTx);
                        });
                        log.info("Auto-reverse completed for txId={}", finalSavedTx.getId());
                        if (transactionEventPublisherPort != null) {
                            transactionEventPublisherPort.publishTransactionEvent(new TransactionEvent(
                                    finalSavedTx.getId(),
                                    "REVERSED",
                                    finalSavedTx.getStatus().name(),
                                    finalSavedTx.getSourceWalletId(),
                                    finalSavedTx.getTargetWalletId(),
                                    finalSavedTx.getAmount().getAmount(),
                                    finalSavedTx.getAmount().getCurrency()
                            ));
                        } else {
                            recordAuditLog(userId, "AUTO_REVERSE",
                                    "originalTxId:" + finalSavedTx.getId() + ",reason:bank_transfer_failed");
                            safeNotify(finalSavedTx, walletToReverse);
                        }
                    } catch (Exception reverseEx) {
                        log.error("CRITICAL: Auto-reverse failed for txId={}. Manual intervention required.",
                                finalSavedTx.getId(), reverseEx);
                    }
                    return null;
                });
            }
        }

        return finalSavedTx;
    }

    public Transaction processPaymentInternal(String requestId, String userId, String walletId, com.fintech.wallet.domain.model.TransactionType type, Money amount) {
        if (walletId == null || walletId.isBlank()) {
            throw new IllegalArgumentException("Wallet ID cannot be null or empty");
        }
        if (amount == null) {
            throw new com.fintech.wallet.domain.exception.InvalidMoneyException("Payment amount cannot be null");
        }

        if (requestId != null && !requestId.isBlank()) {
            java.util.Optional<Transaction> existingTx = transactionPersistencePort.findTransactionByRequestId(requestId);
            if (existingTx.isPresent()) {
                return existingTx.get();
            }
        }

        String lockKey = "lock:wallet:" + walletId;
        return distributedLockPort.executeWithLock(lockKey, LOCK_TIMEOUT_SECONDS, () -> {
            Wallet wallet = getWalletById(walletId);

            if (!wallet.getOwnerId().equals(userId)) {
                throw new IllegalArgumentException("Unauthorized wallet access for user: " + userId);
            }

            validateDailyTransactionLimit(userId, walletId, amount);

            if (!wallet.getBalance().getCurrency().equalsIgnoreCase(amount.getCurrency())) {
                throw new com.fintech.wallet.domain.exception.InvalidMoneyException("Payment currency mismatch");
            }

            Money totalDeduction = amount;
            Transaction transaction = new Transaction(
                java.util.UUID.randomUUID().toString(),
                requestId,
                walletId,
                null,
                amount,
                type,
                com.fintech.wallet.domain.model.TransactionStatus.PENDING,
                java.time.Instant.now()
            );

            if (feeEstimationUseCase != null) {
                com.fintech.wallet.domain.model.FeeEstimate feeEstimate = feeEstimationUseCase.estimateFee(
                        wallet.getOwnerId(),
                        type,
                        amount);
                if (feeEstimate.getFeeAmount().compareTo(java.math.BigDecimal.ZERO) > 0) {
                    Money fee = Money.of(feeEstimate.getFeeAmount(), amount.getCurrency());
                    totalDeduction = amount.add(fee);
                    transaction = new Transaction(transaction.getId(), transaction.getRequestId(), transaction.getSourceWalletId(), transaction.getTargetWalletId(), transaction.getAmount(), transaction.getType(), transaction.getStatus(), transaction.getCreatedAt(), null, "Fee: " + feeEstimate.getFeeAmount() + " " + amount.getCurrency());
                    transaction.setFeeAmount(fee);
                }
            }

            final Transaction finalTransaction = transaction;
            Transaction savedTx;
            try {
                wallet.withdraw(totalDeduction);

                savedTx = transactionalOperationPort.executeInTransaction(() -> {
                    walletPersistencePort.saveWallet(wallet);
                    finalTransaction.markSuccess();
                    return transactionPersistencePort.saveTransaction(finalTransaction);
                });
            } catch (Exception e) {
                finalTransaction.markFailed();
                try {
                    transactionPersistencePort.saveTransaction(finalTransaction);
                } catch (Exception saveEx) {
                    log.error("Failed to save FAILED transaction record for requestId={}", requestId, saveEx);
                }
                throw e;
            }

            if (transactionEventPublisherPort != null) {
                transactionEventPublisherPort.publishTransactionEvent(new com.fintech.wallet.domain.model.TransactionEvent(
                        savedTx.getId(),
                        savedTx.getType().name(),
                        savedTx.getStatus().name(),
                        savedTx.getSourceWalletId(),
                        savedTx.getTargetWalletId(),
                        savedTx.getAmount().getAmount(),
                        savedTx.getAmount().getCurrency()
                ));
            } else {
                safeNotify(savedTx, wallet);
            }
            return savedTx;
        });
    }

    @Override
    public List<Transaction> getTransactionHistory(String walletId, TransactionType type, int page, int size) {
        if (walletId == null || walletId.isBlank()) {
            throw new IllegalArgumentException("Wallet ID cannot be null or empty");
        }
        return transactionPersistencePort.findTransactionsByWalletId(walletId);
    }

    @Override
    public Transaction initTransfer(String requestId, String sourceWalletId, String targetWalletId, String bankCode, Money amount, String note) {
        if (sourceWalletId == null || sourceWalletId.isBlank() || targetWalletId == null || targetWalletId.isBlank()) {
            throw new IllegalArgumentException("Source and target wallet IDs must not be empty");
        }
        if (sourceWalletId.equals(targetWalletId)) {
            throw new IllegalArgumentException("Không thể chuyển tiền vào chính tài khoản của bạn. Vui lòng nhập số tài khoản người nhận khác.");
        }
        if (amount == null) {
            throw new InvalidMoneyException("Transfer amount cannot be null");
        }
        
        validatePerTransactionLimits(amount);

        if (requestId != null && !requestId.isBlank()) {
            java.util.Optional<Transaction> existingTx = transactionPersistencePort.findTransactionByRequestId(requestId);
            if (existingTx.isPresent() && existingTx.get().getStatus() != TransactionStatus.FAILED) {
                return existingTx.get();
            }
        }
        
        // Validate daily & monthly transaction limits before creating transaction
        Wallet sourceWallet = getWalletById(sourceWalletId);
        validateDailyTransactionLimit(sourceWallet.getOwnerId(), sourceWalletId, amount);

        Transaction transaction = Transaction.createTransfer(requestId, sourceWalletId, targetWalletId, amount, note);
        transaction.setBankCode(bankCode);
        return transactionPersistencePort.saveTransaction(transaction);
    }


    /**
     * Confirms and executes a pending transfer.
     * <p>
     * <b>EDGE-2 (Optimistic Locking):</b> This method relies on JPA {@code @Version} fields in the Wallet entity
     * to prevent concurrent modification anomalies. If two concurrent transactions attempt to debit or credit
     * the same wallet, the second one to commit will fail with an {@code ObjectOptimisticLockingFailureException}.
     * The global exception handler translates this to a 409 Conflict status. API clients must implement a retry
     * strategy (e.g., exponential backoff) when encountering 409s during balance operations.
     * </p>
     *
     * @param transactionId The ID of the pending transaction
     * @return The completed Transaction
     */
    @Override
    public Transaction confirmTransfer(String transactionId) {
        Transaction transaction = transactionPersistencePort.findTransactionById(transactionId)
                .orElseThrow(() -> new IllegalArgumentException("Transaction not found"));
                
        if (transaction.getStatus() == TransactionStatus.SUCCESS) {
            return transaction;
        }
        
        if (transaction.getStatus() != TransactionStatus.PENDING && transaction.getStatus() != TransactionStatus.PENDING_CONFIRMATION) {
            throw new IllegalStateException("Transaction is not pending");
        }

        String sourceWalletId = transaction.getSourceWalletId();
        String targetWalletId = transaction.getTargetWalletId();
        Money amount = transaction.getAmount();

        String firstLockId = sourceWalletId.compareTo(targetWalletId) < 0 ? sourceWalletId : targetWalletId;
        String secondLockId = sourceWalletId.compareTo(targetWalletId) < 0 ? targetWalletId : sourceWalletId;

        String lockKey1 = "lock:wallet:" + firstLockId;
        String lockKey2 = "lock:wallet:" + secondLockId;

        return distributedLockPort.executeWithLock(lockKey1, LOCK_TIMEOUT_SECONDS, () ->
            distributedLockPort.executeWithLock(lockKey2, LOCK_TIMEOUT_SECONDS, () -> {
                // re-fetch to ensure no race condition
                Transaction tx = transactionPersistencePort.findTransactionById(transactionId)
                        .orElseThrow(() -> new IllegalArgumentException("Transaction not found: " + transactionId));
                if (tx.getStatus() != TransactionStatus.PENDING && tx.getStatus() != TransactionStatus.PENDING_CONFIRMATION) {
                    return tx;
                }
                
                Wallet sourceWallet = getWalletById(sourceWalletId);
                Wallet targetWallet = getWalletById(targetWalletId);

                // Enforce daily & monthly limit for source wallet owner (only check inside lock to prevent TOCTOU)
                validateDailyTransactionLimit(sourceWallet.getOwnerId(), sourceWalletId, amount);

                if (!sourceWallet.getBalance().getCurrency().equalsIgnoreCase(amount.getCurrency())) {
                    throw new InvalidMoneyException("Currency mismatch");
                }
                boolean isInternalForCheck = tx.getBankCode() == null || "SENHONG".equalsIgnoreCase(tx.getBankCode());
                if (isInternalForCheck && !targetWallet.getBalance().getCurrency().equalsIgnoreCase(amount.getCurrency())) {
                    throw new InvalidMoneyException("Currency mismatch");
                }

                boolean isInternal = tx.getBankCode() == null || "SENHONG".equalsIgnoreCase(tx.getBankCode());
                
                Money totalDeduction = amount;
                Money fee = Money.of(java.math.BigDecimal.ZERO, amount.getCurrency());
                if (feeEstimationUseCase != null) {
                    com.fintech.wallet.domain.model.FeeEstimate feeEstimate = feeEstimationUseCase.estimateFee(
                            sourceWallet.getOwnerId(),
                            com.fintech.wallet.domain.model.TransactionType.TRANSFER,
                            amount);
                    if (feeEstimate.getFeeAmount().compareTo(java.math.BigDecimal.ZERO) > 0) {
                        fee = Money.of(feeEstimate.getFeeAmount(), amount.getCurrency());
                        totalDeduction = amount.add(fee);
                    }
                }
                
                if (!isInternal) {
                    // Mock NAPAS external transfer fee
                    if (fee.getAmount().compareTo(java.math.BigDecimal.ZERO) == 0) {
                        fee = Money.of(new java.math.BigDecimal("2000.00"), amount.getCurrency());
                        totalDeduction = amount.add(fee);
                    }
                }

                tx.setFeeAmount(fee);

                // BUG-1 fix: wrap all DB writes in a single transaction for atomicity
                Transaction savedTx;
                try {
                    sourceWallet.withdraw(totalDeduction);
                    tx.setBalanceAfter(sourceWallet.getBalance());
                    
                    if (isInternal) {
                        targetWallet.deposit(amount);
                    } else {
                        // Mock NAPAS integration
                        log.info("Mocking external NAPAS transfer for tx {} to bank {}", tx.getId(), tx.getBankCode());
                    }

                    savedTx = transactionalOperationPort.executeInTransaction(() -> {
                        walletPersistencePort.saveWallet(sourceWallet);
                        if (isInternal) {
                            walletPersistencePort.saveWallet(targetWallet);
                        }
                        tx.markSuccess();
                        return transactionPersistencePort.saveTransaction(tx);
                    });
                } catch (Exception e) {
                    tx.markFailed();
                    try {
                        transactionPersistencePort.saveTransaction(tx);
                    } catch (Exception saveEx) {
                        log.error("Failed to save FAILED transaction record for txId={}", transactionId, saveEx);
                    }
                    throw e;
                }
                if (transactionEventPublisherPort != null) {
                    transactionEventPublisherPort.publishTransactionEvent(new TransactionEvent(
                            savedTx.getId(),
                            savedTx.getType().name(),
                            savedTx.getStatus().name(),
                            savedTx.getSourceWalletId(),
                            savedTx.getTargetWalletId(),
                            savedTx.getAmount().getAmount(),
                            savedTx.getAmount().getCurrency()
                    ));
                } else {
                    recordAuditLog(sourceWallet.getOwnerId(), "TRANSFER", tx.getId());
                    safeNotify(savedTx, sourceWallet);
                    safeNotify(savedTx, targetWallet);
                }
                return savedTx;
            })
        );
    }

    
    @Override
    public Transaction getTransactionById(String transactionId) {
        return transactionPersistencePort.findTransactionById(transactionId)
                .orElseThrow(() -> new IllegalArgumentException("Transaction not found: " + transactionId));
    }

    @Override
    public byte[] exportStatementCsv(String walletId, Instant fromDate, Instant toDate) {
        if (walletId == null || walletId.isBlank()) {
            throw new IllegalArgumentException("Wallet ID cannot be null or empty");
        }
        List<Transaction> transactions;
        if (fromDate != null && toDate != null) {
            transactions = transactionPersistencePort.findTransactionsByWalletIdAndDateRange(walletId, fromDate, toDate);
        } else {
            transactions = transactionPersistencePort.findTransactionsByWalletId(walletId);
        }

        StringBuilder csv = new StringBuilder("Transaction ID,Request ID,Type,Status,Amount,Currency,Created At\n");
        for (Transaction tx : transactions) {
            csv.append(String.format("%s,%s,%s,%s,%s,%s,%s\n",
                    escapeCsvField(tx.getId()),
                    escapeCsvField(tx.getRequestId() != null ? tx.getRequestId() : ""),
                    tx.getType(),
                    tx.getStatus(),
                    tx.getAmount().getAmount(),
                    tx.getAmount().getCurrency(),
                    tx.getCreatedAt()));
        }
        return csv.toString().getBytes(StandardCharsets.UTF_8);
    }

    @Override
    public byte[] exportStatementPdf(String walletId, Instant fromDate, Instant toDate) {
        if (walletId == null || walletId.isBlank()) {
            throw new IllegalArgumentException("Wallet ID cannot be null or empty");
        }
        List<Transaction> transactions = (fromDate != null && toDate != null)
                ? transactionPersistencePort.findTransactionsByWalletIdAndDateRange(walletId, fromDate, toDate)
                : transactionPersistencePort.findTransactionsByWalletId(walletId);

        try (java.io.ByteArrayOutputStream out = new java.io.ByteArrayOutputStream()) {
            com.lowagie.text.Document document = new com.lowagie.text.Document();
            com.lowagie.text.pdf.PdfWriter.getInstance(document, out);
            document.open();
            document.add(new com.lowagie.text.Paragraph("Account Statement - Wallet " + walletId));
            document.add(new com.lowagie.text.Paragraph("Generated: " + Instant.now()));
            document.add(new com.lowagie.text.Paragraph(" "));

            com.lowagie.text.pdf.PdfPTable table = new com.lowagie.text.pdf.PdfPTable(5);
            table.addCell("Tx ID");
            table.addCell("Type");
            table.addCell("Status");
            table.addCell("Amount");
            table.addCell("Date");

            for (Transaction tx : transactions) {
                table.addCell(tx.getId().substring(0, Math.min(tx.getId().length(), 8)));
                table.addCell(tx.getType().name());
                table.addCell(tx.getStatus().name());
                table.addCell(tx.getAmount().getAmount() + " " + tx.getAmount().getCurrency());
                table.addCell(tx.getCreatedAt().toString());
            }
            document.add(table);
            document.close();
            return out.toByteArray();
        } catch (Exception e) {
            log.error("Failed to generate PDF statement for wallet={}", walletId, e);
            throw new RuntimeException("Failed to generate PDF statement", e);
        }
    }

    @Override
    public byte[] exportStatementExcel(String walletId, Instant fromDate, Instant toDate) {
        if (walletId == null || walletId.isBlank()) {
            throw new IllegalArgumentException("Wallet ID cannot be null or empty");
        }
        List<Transaction> transactions = (fromDate != null && toDate != null)
                ? transactionPersistencePort.findTransactionsByWalletIdAndDateRange(walletId, fromDate, toDate)
                : transactionPersistencePort.findTransactionsByWalletId(walletId);

        try (org.apache.poi.xssf.usermodel.XSSFWorkbook workbook = new org.apache.poi.xssf.usermodel.XSSFWorkbook();
             java.io.ByteArrayOutputStream out = new java.io.ByteArrayOutputStream()) {
            org.apache.poi.ss.usermodel.Sheet sheet = workbook.createSheet("Statement");
            org.apache.poi.ss.usermodel.Row header = sheet.createRow(0);
            header.createCell(0).setCellValue("Transaction ID");
            header.createCell(1).setCellValue("Request ID");
            header.createCell(2).setCellValue("Type");
            header.createCell(3).setCellValue("Status");
            header.createCell(4).setCellValue("Amount");
            header.createCell(5).setCellValue("Currency");
            header.createCell(6).setCellValue("Created At");

            int rowNum = 1;
            for (Transaction tx : transactions) {
                org.apache.poi.ss.usermodel.Row row = sheet.createRow(rowNum++);
                row.createCell(0).setCellValue(tx.getId());
                row.createCell(1).setCellValue(tx.getRequestId() != null ? tx.getRequestId() : "");
                row.createCell(2).setCellValue(tx.getType().name());
                row.createCell(3).setCellValue(tx.getStatus().name());
                row.createCell(4).setCellValue(tx.getAmount().getAmount().doubleValue());
                row.createCell(5).setCellValue(tx.getAmount().getCurrency());
                row.createCell(6).setCellValue(tx.getCreatedAt().toString());
            }
            workbook.write(out);
            return out.toByteArray();
        } catch (Exception e) {
            log.error("Failed to generate Excel statement for wallet={}", walletId, e);
            throw new RuntimeException("Failed to generate Excel statement", e);
        }
    }

    public static final BigDecimal DEFAULT_DAILY_LIMIT = new BigDecimal("100000000"); // 100,000,000 VND
    public static final BigDecimal DEFAULT_MONTHLY_LIMIT = new BigDecimal("500000000"); // 500,000,000 VND

    private void validateDailyTransactionLimit(String userId, String walletId, Money amount) {
        if (walletId == null || amount == null) return;

        BigDecimal limitAmount = DEFAULT_DAILY_LIMIT;
        if (userPersistencePort != null && userId != null) {
            User user = userPersistencePort.findUserById(userId).orElse(null);
            if (user != null && user.getKycStatus() == KycStatus.UNVERIFIED) {
                limitAmount = new BigDecimal("5000000");
            }
        }

        Instant startOfDay = LocalDate.now(ZoneOffset.UTC).atStartOfDay(ZoneOffset.UTC).toInstant();
        BigDecimal spentToday = transactionPersistencePort != null
                ? transactionPersistencePort.calculateDailySpentByWalletId(walletId, startOfDay)
                : BigDecimal.ZERO;
        if (spentToday == null) {
            spentToday = BigDecimal.ZERO;
        }

        if (spentToday.add(amount.getAmount()).compareTo(limitAmount) > 0) {
            throw new TransactionLimitExceededException(String.format(
                    "Daily transaction limit exceeded. Spent today: %s, Attempted: %s, Limit: %s %s",
                    spentToday, amount.getAmount(), limitAmount, amount.getCurrency()
            ));
        }

        validateMonthlyTransactionLimit(userId, walletId, amount);
    }

    private void validateMonthlyTransactionLimit(String userId, String walletId, Money amount) {
        BigDecimal monthlyLimit = DEFAULT_MONTHLY_LIMIT;
        if (userPersistencePort != null && userId != null) {
            User user = userPersistencePort.findUserById(userId).orElse(null);
            if (user != null && user.getKycStatus() == KycStatus.UNVERIFIED) {
                monthlyLimit = new BigDecimal("20000000");
            }
        }

        Instant startOfMonth = LocalDate.now(ZoneOffset.UTC).withDayOfMonth(1).atStartOfDay(ZoneOffset.UTC).toInstant();
        BigDecimal spentThisMonth = transactionPersistencePort != null
                ? transactionPersistencePort.calculateMonthlySpentByWalletId(walletId, startOfMonth)
                : BigDecimal.ZERO;
        if (spentThisMonth == null) {
            spentThisMonth = BigDecimal.ZERO;
        }

        if (spentThisMonth.add(amount.getAmount()).compareTo(monthlyLimit) > 0) {
            throw new TransactionLimitExceededException(String.format(
                    "Monthly transaction limit exceeded. Spent this month: %s, Attempted: %s, Limit: %s %s",
                    spentThisMonth, amount.getAmount(), monthlyLimit, amount.getCurrency()
            ));
        }
    }

    private void recordAuditLog(String callerId, String action, String payloadHash) {
        if (auditLogPersistencePort != null) {
            try {
                String ip = clientInfoPort != null ? clientInfoPort.getClientIp() : "127.0.0.1";
                auditLogPersistencePort.saveAuditLog(AuditLog.record(callerId, ip, action, payloadHash));
            } catch (Exception e) {
                log.warn("Failed to record audit log action={}: {}", action, e.getMessage());
            }
        }
    }

    /**
     * Fire-and-forget notification. Never throws — prevents notification failures
     * from affecting business transaction status.
     */
    private void safeNotify(Transaction transaction, Wallet wallet) {
        if (notificationPort == null) {
            return;
        }
        try {
            notificationPort.notifyTransactionCompleted(transaction, wallet);
        } catch (Exception e) {
            log.warn("Notification failed for transaction={} wallet={}, but business transaction committed successfully",
                    transaction.getId(), wallet.getId(), e);
        }
    }

    public static final BigDecimal MIN_TRANSACTION_AMOUNT_VND = new BigDecimal("1000");
    public static final BigDecimal MAX_TRANSACTION_AMOUNT_PER_TX = new BigDecimal("50000000");

    private void validatePerTransactionLimits(Money amount) {
        if (amount == null) {
            throw new InvalidMoneyException("Transaction amount cannot be null");
        }
        if (amount.getAmount().compareTo(BigDecimal.ZERO) <= 0) {
            throw new InvalidMoneyException("Transaction amount must be positive");
        }
        if ("VND".equalsIgnoreCase(amount.getCurrency()) && amount.getAmount().compareTo(MIN_TRANSACTION_AMOUNT_VND) < 0) {
            throw new InvalidMoneyException("Số tiền giao dịch tối thiểu là 1,000 VND");
        }
        if (amount.getAmount().compareTo(MAX_TRANSACTION_AMOUNT_PER_TX) > 0) {
            throw new TransactionLimitExceededException("Số tiền vượt quá hạn mức tối đa cho 1 giao dịch (50,000,000 " + amount.getCurrency() + ")");
        }
    }

    /**
     * SEC-2 fix: Escapes a CSV field to prevent formula injection and field corruption.
     * Wraps field in double quotes if it contains commas, quotes, or formula-triggering characters.
     */
    private static String escapeCsvField(String field) {
        if (field == null) return "";
        // Strip leading formula triggers (=, +, -, @, \t, \r)
        String sanitized = field.replaceAll("^[=+\\-@\\t\\r]+", "");
        if (sanitized.contains(",") || sanitized.contains("\"") || sanitized.contains("\n")) {
            return "\"" + sanitized.replace("\"", "\"\"") + "\"";
        }
        return sanitized;
    }
}
