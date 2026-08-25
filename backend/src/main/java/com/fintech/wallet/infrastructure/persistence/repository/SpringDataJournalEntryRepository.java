package com.fintech.wallet.infrastructure.persistence.repository;

import com.fintech.wallet.infrastructure.persistence.entity.JournalEntryJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SpringDataJournalEntryRepository extends JpaRepository<JournalEntryJpaEntity, String> {
}
