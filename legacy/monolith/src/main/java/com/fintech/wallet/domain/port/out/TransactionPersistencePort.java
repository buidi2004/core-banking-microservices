package com.fintech.wallet.domain.port.out;

import com.fintech.wallet.domain.model.Transaction;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.Optional;

public interface TransactionPersistencePort {
    Transaction saveTransaction(Transaction transaction);
    Optional<Transaction> findTransactionById(String transactionId);
    Optional<Transaction> findTransactionByRequestId(String requestId);
    List<Transaction> findTransactionsByWalletId(String walletId);
    List<Transaction> findTransactionsByWalletIdAndDateRange(String walletId, Instant fromDate, Instant toDate);
    BigDecimal calculateDailySpentByWalletId(String walletId, Instant startOfDay);
    BigDecimal calculateMonthlySpentByWalletId(String walletId, Instant startOfMonth);
    List<Transaction> findExpiredPendingTransactions(Instant threshold);
}

