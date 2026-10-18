package com.fintech.wallet.infrastructure.persistence.repository;

import com.fintech.wallet.infrastructure.persistence.entity.WalletJpaEntity;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface SpringDataWalletRepository extends JpaRepository<WalletJpaEntity, String> {
    Optional<WalletJpaEntity> findByOwnerId(String ownerId);

    @Query("SELECT SUM(w.balanceAmount) FROM WalletJpaEntity w")
    java.math.BigDecimal sumAllBalances();

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT w FROM WalletJpaEntity w WHERE w.id = :id")
    Optional<WalletJpaEntity> findByIdForUpdate(@Param("id") String id);
}
