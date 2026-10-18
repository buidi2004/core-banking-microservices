package com.fintech.wallet.infrastructure.persistence.adapter;

import com.fintech.wallet.domain.model.Transaction;
import com.fintech.wallet.domain.port.out.TransactionPersistencePort;
import com.fintech.wallet.infrastructure.persistence.entity.TransactionJpaEntity;
import com.fintech.wallet.infrastructure.persistence.mapper.WalletMapper;
import com.fintech.wallet.infrastructure.persistence.repository.SpringDataTransactionRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

/**
 * OPT #1: Extracted from WalletPersistenceAdapter to follow Single Responsibility Principle.
 * Each adapter now handles persistence for exactly one aggregate/entity type.
 */
@Component
public class TransactionPersistenceAdapter implements TransactionPersistencePort {

    private static final Logger log = LoggerFactory.getLogger(TransactionPersistenceAdapter.class);

    private final SpringDataTransactionRepository transactionRepository;
    private final WalletMapper mapper;

    public TransactionPersistenceAdapter(SpringDataTransactionRepository transactionRepository,
                                         WalletMapper mapper) {
        this.transactionRepository = transactionRepository;
        this.mapper = mapper;
    }

    // Bug #3 fix: catch unique constraint violation on requestId (race condition between different lock keys)
    @Override
    public Transaction saveTransaction(Transaction transaction) {
        try {
            TransactionJpaEntity entity = mapper.toJpaEntity(transaction);
            TransactionJpaEntity saved = transactionRepository.save(entity);
            return mapper.toDomain(saved);
        } catch (DataIntegrityViolationException e) {
            if (transaction.getRequestId() != null && !transaction.getRequestId().isBlank()) {
                log.warn("Duplicate requestId detected during save: {}, re-querying", transaction.getRequestId());
                return transactionRepository.findByRequestId(transaction.getRequestId())
                        .map(mapper::toDomain)
                        .orElseThrow(() -> e);
            }
            throw e;
        }
    }

    @Override
    public Optional<Transaction> findTransactionById(String transactionId) {
        return transactionRepository.findById(transactionId).map(mapper::toDomain);
    }

    @Override
    public Optional<Transaction> findTransactionByRequestId(String requestId) {
        return transactionRepository.findByRequestId(requestId).map(mapper::toDomain);
    }

    @Override
    public List<Transaction> findTransactionsByWalletId(String walletId) {
        return transactionRepository.findBySourceWalletIdOrTargetWalletIdOrderByCreatedAtDesc(walletId, walletId)
                .stream()
                .map(mapper::toDomain)
                .collect(Collectors.toList());
    }

    @Override
    public List<Transaction> findTransactionsByWalletIdAndDateRange(String walletId, Instant fromDate, Instant toDate) {
        return transactionRepository.findBySourceWalletIdAndCreatedAtBetweenOrTargetWalletIdAndCreatedAtBetweenOrderByCreatedAtDesc(
                        walletId, fromDate, toDate,
                        walletId, fromDate, toDate
                )
                .stream()
                .map(mapper::toDomain)
                .collect(Collectors.toList());
    }

    @Override
    public BigDecimal calculateDailySpentByWalletId(String walletId, Instant startOfDay) {
        BigDecimal spent = transactionRepository.sumDailySpentByWalletId(walletId, startOfDay);
        return spent != null ? spent : BigDecimal.ZERO;
    }

    @Override
    public BigDecimal calculateMonthlySpentByWalletId(String walletId, Instant startOfMonth) {
        BigDecimal spent = transactionRepository.sumMonthlySpentByWalletId(walletId, startOfMonth);
        return spent != null ? spent : BigDecimal.ZERO;
    }

    @Override
    public List<Transaction> findExpiredPendingTransactions(Instant threshold) {
        return transactionRepository.findByStatusInAndCreatedAtBefore(
                List.of("PENDING", "PENDING_CONFIRMATION"), threshold)
                .stream()
                .map(mapper::toDomain)
                .collect(Collectors.toList());
    }
}

