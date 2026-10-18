package com.fintech.ledger.infrastructure.persistence.adapter;

import com.fintech.ledger.application.port.LedgerPersistencePort;
import com.fintech.ledger.domain.model.JournalEntry;
import com.fintech.ledger.domain.model.LedgerAccount;
import com.fintech.ledger.domain.model.LedgerPosting;
import com.fintech.ledger.domain.model.PostingSide;
import com.fintech.ledger.infrastructure.persistence.entity.JournalEntryJpaEntity;
import com.fintech.ledger.infrastructure.persistence.entity.LedgerAccountJpaEntity;
import com.fintech.ledger.infrastructure.persistence.entity.LedgerPostingJpaEntity;
import com.fintech.ledger.infrastructure.persistence.mapper.LedgerDomainMapper;
import com.fintech.ledger.infrastructure.persistence.repository.SpringLedgerAccountRepository;
import com.fintech.ledger.infrastructure.persistence.repository.SpringJournalEntryRepository;
import com.fintech.ledger.infrastructure.persistence.repository.SpringLedgerPostingRepository;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Component
public class LedgerPersistenceAdapter implements LedgerPersistencePort {

    private final SpringLedgerAccountRepository accountRepository;
    private final SpringJournalEntryRepository journalEntryRepository;
    private final SpringLedgerPostingRepository postingRepository;

    public LedgerPersistenceAdapter(SpringLedgerAccountRepository accountRepository,
                                    SpringJournalEntryRepository journalEntryRepository,
                                    SpringLedgerPostingRepository postingRepository) {
        this.accountRepository = accountRepository;
        this.journalEntryRepository = journalEntryRepository;
        this.postingRepository = postingRepository;
    }

    @Override
    public LedgerAccount saveAccount(LedgerAccount account) {
        LedgerAccountJpaEntity saved = accountRepository.save(LedgerDomainMapper.toJpa(account));
        return LedgerDomainMapper.toDomain(saved);
    }

    @Override
    public Optional<LedgerAccount> findAccountByCode(String code) {
        return accountRepository.findByCode(code).map(LedgerDomainMapper::toDomain);
    }

    @Override
    public Optional<LedgerAccount> findAccountByName(String name) {
        return accountRepository.findByName(name).map(LedgerDomainMapper::toDomain);
    }

    @Override
    public List<LedgerAccount> findAllAccounts() {
        return accountRepository.findAll().stream().map(LedgerDomainMapper::toDomain).toList();
    }

    @Override
    public Optional<LedgerAccount> findAccountById(String accountId) {
        return accountRepository.findById(UUID.fromString(accountId)).map(LedgerDomainMapper::toDomain);
    }

    @Override
    public JournalEntry saveJournalEntry(JournalEntry entry) {
        JournalEntryJpaEntity savedEntry = journalEntryRepository.save(LedgerDomainMapper.toJpa(entry));

        List<LedgerPostingJpaEntity> postingEntities = entry.getPostings().stream()
                .map(posting -> LedgerDomainMapper.toJpa(savedEntry.getId(), posting))
                .toList();
        List<LedgerPostingJpaEntity> savedPostings = postingRepository.saveAll(postingEntities);

        return LedgerDomainMapper.toDomain(savedEntry, savedPostings);
    }

    @Override
    public Optional<JournalEntry> findJournalEntryById(String entryId) {
        return journalEntryRepository.findById(UUID.fromString(entryId))
                .map(entity -> LedgerDomainMapper.toDomain(entity,
                        postingRepository.findByJournalEntryIdOrderByCreatedAtAsc(UUID.fromString(entity.getId()))));
    }

    @Override
    public Optional<JournalEntry> findJournalEntryByReference(String referenceNumber) {
        return journalEntryRepository.findByReferenceNumber(referenceNumber)
                .map(entity -> LedgerDomainMapper.toDomain(entity,
                        postingRepository.findByJournalEntryIdOrderByCreatedAtAsc(UUID.fromString(entity.getId()))));
    }

    @Override
    public Optional<JournalEntry> findPostedEntryByTransactionId(String transactionId) {
        return journalEntryRepository.findByTransactionIdAndStatus(transactionId, "POSTED")
                .map(entity -> LedgerDomainMapper.toDomain(entity,
                        postingRepository.findByJournalEntryIdOrderByCreatedAtAsc(UUID.fromString(entity.getId()))));
    }

    @Override
    public List<JournalEntry> findEntriesByTransactionId(String transactionId) {
        return journalEntryRepository.findByTransactionIdOrderByEntryNumberAsc(transactionId).stream()
                .map(entity -> LedgerDomainMapper.toDomain(entity,
                        postingRepository.findByJournalEntryIdOrderByCreatedAtAsc(UUID.fromString(entity.getId()))))
                .toList();
    }

    @Override
    public List<JournalEntry> findAllEntries() {
        return journalEntryRepository.findAll().stream()
                .map(entity -> LedgerDomainMapper.toDomain(entity,
                        postingRepository.findByJournalEntryIdOrderByCreatedAtAsc(UUID.fromString(entity.getId()))))
                .toList();
    }

    @Override
    public List<LedgerPosting> findPostingsByEntryId(String entryId) {
        return postingRepository
                .findByJournalEntryIdOrderByCreatedAtAsc(UUID.fromString(entryId))
                .stream().map(LedgerDomainMapper::toDomainWithoutEntry).toList();
    }

    @Override
    public List<LedgerPosting> findPostingsByAccountId(String accountId, Instant from, Instant toExclusive) {
        UUID accountIdUuid = UUID.fromString(accountId);
        if (from != null && toExclusive != null) {
            return postingRepository.findByAccountIdBetween(accountIdUuid,
                            LedgerDomainMapper.toLocalDateTime(from), LedgerDomainMapper.toLocalDateTime(toExclusive))
                    .stream().map(LedgerDomainMapper::toDomainWithoutEntry).toList();
        }
        return postingRepository.findByAccountIdOrderByCreatedAtDesc(accountIdUuid)
                .stream().map(LedgerDomainMapper::toDomainWithoutEntry).toList();
    }

    @Override
    public BigDecimal sumAmount(PostingSide side) {
        return postingRepository.sumAmountBySide(side.name());
    }

    @Override
    public boolean existsJournalEntryByReference(String referenceNumber) {
        return journalEntryRepository.findByReferenceNumber(referenceNumber).isPresent();
    }
}
