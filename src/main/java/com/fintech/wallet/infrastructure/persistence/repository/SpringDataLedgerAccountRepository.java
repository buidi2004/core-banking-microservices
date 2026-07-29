package com.fintech.wallet.infrastructure.persistence.repository;

import com.fintech.wallet.infrastructure.persistence.entity.LedgerAccountJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SpringDataLedgerAccountRepository extends JpaRepository<LedgerAccountJpaEntity, String> {
}
