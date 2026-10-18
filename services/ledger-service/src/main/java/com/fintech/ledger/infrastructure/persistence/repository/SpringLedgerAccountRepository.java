package com.fintech.ledger.infrastructure.persistence.repository;

import com.fintech.ledger.infrastructure.persistence.entity.LedgerAccountJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface SpringLedgerAccountRepository extends JpaRepository<LedgerAccountJpaEntity, UUID> {

    Optional<LedgerAccountJpaEntity> findByCode(String code);

    Optional<LedgerAccountJpaEntity> findByName(String name);
}
