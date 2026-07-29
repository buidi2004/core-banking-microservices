package com.fintech.wallet.infrastructure.persistence.repository;

import com.fintech.wallet.infrastructure.persistence.entity.TransactionJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.Optional;

public interface SpringDataTransactionRepository extends JpaRepository<TransactionJpaEntity, String> {
    Optional<TransactionJpaEntity> findByRequestId(String requestId);

    List<TransactionJpaEntity> findBySourceWalletIdOrTargetWalletIdOrderByCreatedAtDesc(String sourceWalletId, String targetWalletId);

    List<TransactionJpaEntity> findBySourceWalletIdAndCreatedAtBetweenOrTargetWalletIdAndCreatedAtBetweenOrderByCreatedAtDesc(
            String sourceWalletId1, Instant from1, Instant to1,
            String targetWalletId2, Instant from2, Instant to2
    );

    @Query("SELECT COALESCE(SUM(t.amount), 0) FROM TransactionJpaEntity t WHERE t.sourceWalletId = :walletId AND t.status = 'SUCCESS' AND t.createdAt >= :startOfDay AND t.type IN ('TRANSFER', 'WITHDRAW', 'BILL_PAYMENT', 'TOPUP')")
    BigDecimal sumDailySpentByWalletId(@Param("walletId") String walletId, @Param("startOfDay") Instant startOfDay);
}

