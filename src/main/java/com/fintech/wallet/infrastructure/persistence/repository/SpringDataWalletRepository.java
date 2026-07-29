package com.fintech.wallet.infrastructure.persistence.repository;

import com.fintech.wallet.infrastructure.persistence.entity.WalletJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface SpringDataWalletRepository extends JpaRepository<WalletJpaEntity, String> {
    Optional<WalletJpaEntity> findByOwnerId(String ownerId);
}
