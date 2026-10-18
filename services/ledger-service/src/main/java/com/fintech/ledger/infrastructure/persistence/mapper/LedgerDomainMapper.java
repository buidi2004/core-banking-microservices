package com.fintech.ledger.infrastructure.persistence.mapper;

import com.fintech.ledger.domain.model.AccountType;
import com.fintech.ledger.domain.model.JournalEntry;
import com.fintech.ledger.domain.model.JournalEntryStatus;
import com.fintech.ledger.domain.model.LedgerAccount;
import com.fintech.ledger.domain.model.LedgerPosting;
import com.fintech.ledger.domain.model.PostingSide;
import com.fintech.ledger.infrastructure.persistence.entity.JournalEntryJpaEntity;
import com.fintech.ledger.infrastructure.persistence.entity.LedgerAccountJpaEntity;
import com.fintech.ledger.infrastructure.persistence.entity.LedgerPostingJpaEntity;

import java.util.ArrayList;
import java.util.List;

public class LedgerDomainMapper {

    private LedgerDomainMapper() {
    }

    public static LedgerAccountJpaEntity toJpa(LedgerAccount account) {
        return new LedgerAccountJpaEntity(account.getId(), account.getCode(), account.getName(),
                account.getType().name(), account.getBalance(), account.getCurrency());
    }

    public static LedgerAccount toDomain(LedgerAccountJpaEntity entity) {
        return LedgerAccount.of(entity.getId(), entity.getCode(), entity.getName(),
                AccountType.valueOf(entity.getType()), entity.getBalance(), entity.getCurrency());
    }

    public static JournalEntryJpaEntity toJpa(JournalEntry entry) {
        return new JournalEntryJpaEntity(entry.getId(), entry.getTransactionId(), entry.getDescription(),
                entry.getReferenceNumber(), entry.getStatus().name(),
                entry.getReversalOf(), entry.getEntryDate());
    }

    public static LedgerPostingJpaEntity toJpa(String journalEntryId, LedgerPosting posting) {
        return new LedgerPostingJpaEntity(posting.getId(),
                journalEntryId != null ? java.util.UUID.fromString(journalEntryId) : null,
                java.util.UUID.fromString(posting.getAccountId()),
                posting.getSide().name(), posting.getAmount(), posting.getCurrency(), null);
    }

    public static LedgerPosting toDomainWithoutEntry(LedgerPostingJpaEntity entity) {
        return new LedgerPosting(entity.getId(), entity.getJournalEntryId(), entity.getAccountId(),
                PostingSide.valueOf(entity.getSide()), entity.getAmount(), entity.getCurrency());
    }

    public static JournalEntry toDomain(JournalEntryJpaEntity entity, List<LedgerPostingJpaEntity> postingEntities) {
        List<LedgerPosting> postings = new ArrayList<>();
        for (LedgerPostingJpaEntity postingEntity : postingEntities) {
            postings.add(toDomainWithoutEntry(postingEntity));
        }
        return JournalEntry.rehydrate(entity.getId(), entity.getTransactionId(),
                entity.getEntryNumber() != null ? entity.getEntryNumber().toString() : null,
                entity.getEntryDate(), entity.getDescription(),
                entity.getReferenceNumber(), JournalEntryStatus.valueOf(entity.getStatus()),
                entity.getReversalOf(), toInstant(entity.getPostedAt()), postings);
    }

    /** DB dùng TIMESTAMP (không timezone), domain dùng Instant — quy đổi theo zone hệ thống */
    static java.time.Instant toInstant(java.time.LocalDateTime localDateTime) {
        return localDateTime != null
                ? localDateTime.atZone(java.time.ZoneId.systemDefault()).toInstant()
                : null;
    }

    static java.time.LocalDateTime toLocalDateTime(java.time.Instant instant) {
        return instant != null
                ? java.time.LocalDateTime.ofInstant(instant, java.time.ZoneId.systemDefault())
                : null;
    }
}
