package com.fintech.wallet.infrastructure.persistence.mapper;

import com.fintech.wallet.domain.model.AccountType;
import com.fintech.wallet.domain.model.EntryType;
import com.fintech.wallet.domain.model.JournalEntry;
import com.fintech.wallet.domain.model.LedgerAccount;
import com.fintech.wallet.domain.model.LedgerPosting;
import com.fintech.wallet.infrastructure.persistence.entity.JournalEntryJpaEntity;
import com.fintech.wallet.infrastructure.persistence.entity.LedgerAccountJpaEntity;
import com.fintech.wallet.infrastructure.persistence.entity.LedgerPostingJpaEntity;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.stream.Collectors;

@Component
public class LedgerMapper {

    public LedgerAccount toDomain(LedgerAccountJpaEntity entity) {
        if (entity == null) return null;
        return new LedgerAccount(
                entity.getId(),
                entity.getAccountName(),
                AccountType.valueOf(entity.getAccountType()),
                entity.getCurrency(),
                entity.getBalance()
        );
    }

    public LedgerAccountJpaEntity toJpaEntity(LedgerAccount domain) {
        if (domain == null) return null;
        return new LedgerAccountJpaEntity(
                domain.getId(),
                domain.getAccountName(),
                domain.getAccountType().name(),
                domain.getCurrency(),
                domain.getBalance()
        );
    }

    public JournalEntry toDomain(JournalEntryJpaEntity entity, List<LedgerPostingJpaEntity> postings) {
        if (entity == null) return null;
        List<LedgerPosting> postingDomains = postings.stream()
                .map(p -> new LedgerPosting(p.getId(), p.getJournalEntryId(), p.getAccountId(), EntryType.valueOf(p.getEntryType()), p.getAmount()))
                .collect(Collectors.toList());

        return new JournalEntry(
                entity.getId(),
                entity.getTransactionId(),
                entity.getDescription(),
                entity.getCreatedAt(),
                postingDomains
        );
    }

    public JournalEntryJpaEntity toJpaEntity(JournalEntry domain) {
        if (domain == null) return null;
        return new JournalEntryJpaEntity(
                domain.getId(),
                domain.getTransactionId(),
                domain.getDescription(),
                domain.getCreatedAt()
        );
    }

    public LedgerPostingJpaEntity toJpaEntity(LedgerPosting domain) {
        if (domain == null) return null;
        return new LedgerPostingJpaEntity(
                domain.getId(),
                domain.getJournalEntryId(),
                domain.getAccountId(),
                domain.getEntryType().name(),
                domain.getAmount()
        );
    }
}
