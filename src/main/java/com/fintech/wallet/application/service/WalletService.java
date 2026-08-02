package com.fintech.wallet.application.service;

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
import com.fintech.wallet.domain.port.in.TransferMoneyUseCase;
import com.fintech.wallet.domain.port.in.WithdrawMoneyUseCase;
import com.fintech.wallet.domain.port.out.AuditLogPersistencePort;
import com.fintech.wallet.domain.port.out.BankGatewayPort;
import com.fintech.wallet.domain.port.out.DistributedLockPort;
import com.fintech.wallet.domain.port.out.NotificationPort;
import com.fintech.wallet.domain.port.out.TransactionPersistencePort;
import com.fintech.wallet.domain.port.out.TransactionalOperationPort;
import com.fintech.wallet.domain.port.out.UserPersistencePort;
import com.fintech.wallet.domain.port.out.WalletPersistencePort;
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

    public WalletService(WalletPersistencePort walletPersistencePort,
                         TransactionPersistencePort transactionPersistencePort,
                         DistributedLockPort distributedLockPort,
                         NotificationPort notificationPort,
                         TransactionalOperationPort transactionalOperationPort,
                         BankGatewayPort bankGatewayPort,
                         UserPersistencePort userPersistencePort,
                         AuditLogPersistencePort auditLogPersistencePort) {
        this.walletPersistencePort = walletPersistencePort;
        this.transactionPersistencePort = transactionPersistencePort;
        this.distributedLockPort = distributedLockPort;
        this.notificationPort = notificationPort;
        this.transactionalOperationPort = transactionalOperationPort;
        this.bankGatewayPort = bankGatewayPort;
        this.userPersistencePort = userPersistencePort;
        this.auditLogPersistencePort = auditLogPersistencePort;
    }

    public WalletService(WalletPersistencePort walletPersistencePort,
                         TransactionPersistencePort transactionPersistencePort,
                         DistributedLockPort distributedLockPort,
                         NotificationPort notificationPort,
                         TransactionalOperationPort transactionalOperationPort,
                         BankGatewayPort bankGatewayPort) {
        this(walletPersistencePort, transactionPersistencePort, distributedLockPort, notificationPort, transactionalOperationPort, bankGatewayPort, null, null);
    }

    public WalletService(WalletPersistencePort walletPersistencePort,
                         TransactionPersistencePort transactionPersistencePort,
                         DistributedLockPort distributedLockPort,
                         NotificationPort notificationPort,
                         TransactionalOperationPort transactionalOperationPort) {
        this(walletPersistencePort, transactionPersistencePort, distributedLockPort, notificationPort, transactionalOperationPort, null, null, null);
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
            if (existingTx.isPresent() && existingTx.get().getStatus() == TransactionStatus.SUCCESS) {
                return existingTx.get();
            }
        }

        String lockKey = "lock:wallet:" + walletId;
        return distributedLockPort.executeWithLock(lockKey, LOCK_TIMEOUT_SECONDS, () -> {
            // Re-check inside lock
            if (requestId != null && !requestId.isBlank()) {
                Optional<Transaction> existingTx = transactionPersistencePort.findTransactionByRequestId(requestId);
                if (existingTx.isPresent() && existingTx.get().getStatus() == TransactionStatus.SUCCESS) {
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
    public Transaction transfer(String requestId, String sourceWalletId, String targetWalletId, Money amount) {
        if (sourceWalletId == null || sourceWalletId.isBlank() || targetWalletId == null || targetWalletId.isBlank()) {
            throw new IllegalArgumentException("Source and target wallet IDs must not be empty");
        }
        if (sourceWalletId.equals(targetWalletId)) {
            throw new IllegalArgumentException("Cannot transfer money to the same wallet");
        }
        if (amount == null) {
            throw new InvalidMoneyException("Transfer amount cannot be null");
        }

        // Bug #2 fix: Idempotency — only return SUCCESS
        if (requestId != null && !requestId.isBlank()) {
            Optional<Transaction> existingTx = transactionPersistencePort.findTransactionByRequestId(requestId);
            if (existingTx.isPresent() && existingTx.get().getStatus() == TransactionStatus.SUCCESS) {
                return existingTx.get();
            }
        }

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
                    if (existingTx.isPresent() && existingTx.get().getStatus() == TransactionStatus.SUCCESS) {
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

                Transaction transaction = Transaction.createTransfer(requestId, sourceWalletId, targetWalletId, amount);

                // Bug #1 fix: atomic transaction for all DB writes
                // Bug #4 fix: notification outside business try-catch
                Transaction savedTx;
                try {
                    sourceWallet.withdraw(amount);
                    targetWallet.deposit(amount);

                    savedTx = transactionalOperationPort.executeInTransaction(() -> {
                        walletPersistencePort.saveWallet(sourceWallet);
                        walletPersistencePort.saveWallet(targetWallet);
                        transaction.markSuccess();
                        return transactionPersistencePort.saveTransaction(transaction);
                    });
                } catch (Exception e) {
                    transaction.markFailed();
                    try {
                        transactionPersistencePort.saveTransaction(transaction);
                    } catch (Exception saveEx) {
                        log.error("Failed to save FAILED transaction record for requestId={}", requestId, saveEx);
                    }
                    throw e;
                }

                // Bug #4 fix: notification is fire-and-forget
                // ISSUE #9 fix: use in-memory wallets directly, avoid extra DB queries
                safeNotify(savedTx, sourceWallet);
                safeNotify(savedTx, targetWallet);
                recordAuditLog(sourceWallet.getOwnerId(), "TRANSFER", "txId:" + savedTx.getId() + ",amount:" + amount.getAmount());
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
            if (existingTx.isPresent() && existingTx.get().getStatus() == TransactionStatus.SUCCESS) {
                return existingTx.get();
            }
        }

        String lockKey = "lock:wallet:" + walletId;
        return distributedLockPort.executeWithLock(lockKey, LOCK_TIMEOUT_SECONDS, () -> {
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

            Transaction savedTx;
            try {
                wallet.withdraw(amount);

                savedTx = transactionalOperationPort.executeInTransaction(() -> {
                    walletPersistencePort.saveWallet(wallet);
                    transaction.markSuccess();
                    return transactionPersistencePort.saveTransaction(transaction);
                });
            } catch (Exception e) {
                transaction.markFailed();
                try {
                    transactionPersistencePort.saveTransaction(transaction);
                } catch (Exception saveEx) {
                    log.error("Failed to save FAILED transaction record for requestId={}", requestId, saveEx);
                }
                throw e;
            }

            if (bankGatewayPort != null) {
                try {
                    bankGatewayPort.transferToBank(bankAccountId, amount, savedTx.getId());
                } catch (Exception bankEx) {
                    log.error("Bank transfer failed for txId={}, bankAccountId={}. Initiating auto-reverse.",
                            savedTx.getId(), bankAccountId, bankEx);
                    // Auto-reverse: credit the amount back to the user's wallet
                    try {
                        wallet.deposit(amount);
                        transactionalOperationPort.executeInTransaction(() -> {
                            walletPersistencePort.saveWallet(wallet);
                            savedTx.markReversed();
                            transactionPersistencePort.saveTransaction(savedTx);
                            Transaction reversalTx = Transaction.createReversal(
                                    savedTx.getId(), walletId, amount);
                            reversalTx.markSuccess();
                            return transactionPersistencePort.saveTransaction(reversalTx);
                        });
                        log.info("Auto-reverse completed for txId={}", savedTx.getId());
                        recordAuditLog(userId, "AUTO_REVERSE",
                                "originalTxId:" + savedTx.getId() + ",reason:bank_transfer_failed");
                    } catch (Exception reverseEx) {
                        log.error("CRITICAL: Auto-reverse failed for txId={}. Manual intervention required.",
                                savedTx.getId(), reverseEx);
                    }
                }
            }

            safeNotify(savedTx, wallet);
            recordAuditLog(userId, "WITHDRAW", "txId:" + savedTx.getId() + ",amount:" + amount.getAmount());
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
                    tx.getId(),
                    tx.getRequestId() != null ? tx.getRequestId() : "",
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

    private void validateDailyTransactionLimit(String userId, String walletId, Money amount) {
        if (userPersistencePort == null) return;

        User user = userPersistencePort.findUserById(userId).orElse(null);
        KycStatus status = user != null && user.getKycStatus() != null ? user.getKycStatus() : KycStatus.UNVERIFIED;

        BigDecimal limitAmount = (status == KycStatus.VERIFIED)
                ? new BigDecimal("100000000")
                : new BigDecimal("5000000");

        Instant startOfDay = LocalDate.now(ZoneOffset.UTC).atStartOfDay(ZoneOffset.UTC).toInstant();
        BigDecimal spentToday = transactionPersistencePort.calculateDailySpentByWalletId(walletId, startOfDay);

        if (spentToday.add(amount.getAmount()).compareTo(limitAmount) > 0) {
            throw new TransactionLimitExceededException(String.format(
                    "Daily transaction limit exceeded for KYC level %s. Spent today: %s, Attempted: %s, Limit: %s %s",
                    status, spentToday, amount.getAmount(), limitAmount, amount.getCurrency()
            ));
        }

        validateMonthlyTransactionLimit(userId, walletId, amount, status);
    }

    private void validateMonthlyTransactionLimit(String userId, String walletId, Money amount, KycStatus status) {
        BigDecimal monthlyLimit = (status == KycStatus.VERIFIED)
                ? new BigDecimal("500000000")
                : new BigDecimal("20000000");

        Instant startOfMonth = LocalDate.now(ZoneOffset.UTC).withDayOfMonth(1).atStartOfDay(ZoneOffset.UTC).toInstant();
        BigDecimal spentThisMonth = transactionPersistencePort.calculateMonthlySpentByWalletId(walletId, startOfMonth);

        if (spentThisMonth.add(amount.getAmount()).compareTo(monthlyLimit) > 0) {
            throw new TransactionLimitExceededException(String.format(
                    "Monthly transaction limit exceeded for KYC level %s. Spent this month: %s, Attempted: %s, Limit: %s %s",
                    status, spentThisMonth, amount.getAmount(), monthlyLimit, amount.getCurrency()
            ));
        }
    }

    private void recordAuditLog(String callerId, String action, String payloadHash) {
        if (auditLogPersistencePort != null && callerId != null) {
            try {
                auditLogPersistencePort.saveAuditLog(AuditLog.record(callerId, "127.0.0.1", action, payloadHash));
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
}
