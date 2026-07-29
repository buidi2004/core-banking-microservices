package com.fintech.wallet.infrastructure.persistence.adapter;

import com.fintech.wallet.domain.model.JournalEntry;
import com.fintech.wallet.domain.model.LedgerAccount;
import com.fintech.wallet.domain.port.out.LedgerPersistencePort;
import com.fintech.wallet.infrastructure.persistence.entity.JournalEntryJpaEntity;
import com.fintech.wallet.infrastructure.persistence.entity.LedgerAccountJpaEntity;
import com.fintech.wallet.infrastructure.persistence.entity.LedgerPostingJpaEntity;
import com.fintech.wallet.infrastructure.persistence.mapper.LedgerMapper;
import com.fintech.wallet.infrastructure.persistence.repository.SpringDataJournalEntryRepository;
import com.fintech.wallet.infrastructure.persistence.repository.SpringDataLedgerAccountRepository;
import com.fintech.wallet.infrastructure.persistence.repository.SpringDataLedgerPostingRepository;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Component
public class LedgerPersistenceAdapter implements LedgerPersistencePort {

    private final SpringDataLedgerAccountRepository accountRepository;
    private final SpringDataJournalEntryRepository entryRepository;
    private final SpringDataLedgerPostingRepository postingRepository;
    private final LedgerMapper mapper;

    public LedgerPersistenceAdapter(SpringDataLedgerAccountRepository accountRepository,
                                    SpringDataJournalEntryRepository entryRepository,
                                    SpringDataLedgerPostingRepository postingRepository,
                                    LedgerMapper mapper) {
        this.accountRepository = accountRepository;
        this.entryRepository = entryRepository;
        this.postingRepository = postingRepository;
        this.mapper = mapper;
    }

    @Override
    public LedgerAccount saveAccount(LedgerAccount account) {
        LedgerAccountJpaEntity entity = mapper.toJpaEntity(account);
        LedgerAccountJpaEntity saved = accountRepository.save(entity);
        return mapper.toDomain(saved);
    }

    @Override
    public Optional<LedgerAccount> findAccountById(String accountId) {
        return accountRepository.findById(accountId).map(mapper::toDomain);
    }

    @Override
    public List<LedgerAccount> findAllAccounts() {
        return accountRepository.findAll().stream()
                .map(mapper::toDomain)
                .collect(Collectors.toList());
    }

    @Override
    public JournalEntry saveJournalEntry(JournalEntry journalEntry) {
        JournalEntryJpaEntity entryEntity = mapper.toJpaEntity(journalEntry);
        JournalEntryJpaEntity savedEntry = entryRepository.save(entryEntity);

        List<LedgerPostingJpaEntity> postingEntities = journalEntry.getPostings().stream()
                .map(mapper::toJpaEntity)
                .collect(Collectors.toList());
        List<LedgerPostingJpaEntity> savedPostings = postingRepository.saveAll(postingEntities);

        return mapper.toDomain(savedEntry, savedPostings);
    }

    @Override
    public List<JournalEntry> findAllJournalEntries() {
        return entryRepository.findAll().stream()
                .map(entry -> {
                    List<LedgerPostingJpaEntity> postings = postingRepository.findByJournalEntryId(entry.getId());
                    return mapper.toDomain(entry, postings);
                })
                .collect(Collectors.toList());
    }
}
