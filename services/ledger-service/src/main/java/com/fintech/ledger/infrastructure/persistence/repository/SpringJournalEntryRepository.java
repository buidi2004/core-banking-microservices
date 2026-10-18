package com.fintech.ledger.infrastructure.persistence.repository;

import com.fintech.ledger.infrastructure.persistence.entity.JournalEntryJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface SpringJournalEntryRepository extends JpaRepository<JournalEntryJpaEntity, UUID> {

    Optional<JournalEntryJpaEntity> findByReferenceNumber(String referenceNumber);

    List<JournalEntryJpaEntity> findByTransactionIdOrderByEntryNumberAsc(String transactionId);

    List<JournalEntryJpaEntity> findByStatusOrderByEntryNumberAsc(String status);

    Optional<JournalEntryJpaEntity> findByTransactionIdAndStatus(String transactionId, String status);
}
