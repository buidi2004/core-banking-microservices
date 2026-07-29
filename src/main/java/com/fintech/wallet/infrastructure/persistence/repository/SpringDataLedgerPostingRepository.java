package com.fintech.wallet.infrastructure.persistence.repository;

import com.fintech.wallet.infrastructure.persistence.entity.LedgerPostingJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface SpringDataLedgerPostingRepository extends JpaRepository<LedgerPostingJpaEntity, String> {
    List<LedgerPostingJpaEntity> findByJournalEntryId(String journalEntryId);
}
