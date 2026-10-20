package com.fintech.ledger.application.port;

import com.fintech.ledger.domain.model.JournalEntry;
import com.fintech.ledger.domain.model.LedgerAccount;
import com.fintech.ledger.domain.model.LedgerPosting;
import com.fintech.ledger.domain.model.PostingSide;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.Optional;

public interface LedgerPersistencePort {

    LedgerAccount saveAccount(LedgerAccount account);

    Optional<LedgerAccount> findAccountByCode(String code);

    Optional<LedgerAccount> findAccountByName(String name);

    List<LedgerAccount> findAllAccounts();

    Optional<LedgerAccount> findAccountById(String accountId);

    JournalEntry saveJournalEntry(JournalEntry entry);

    Optional<JournalEntry> findJournalEntryById(String entryId);

    Optional<JournalEntry> findJournalEntryByReference(String referenceNumber);

    Optional<JournalEntry> findPostedEntryByTransactionId(String transactionId);

    List<JournalEntry> findEntriesByTransactionId(String transactionId);

    List<JournalEntry> findAllEntries();

    List<LedgerPosting> findPostingsByEntryId(String entryId);

    List<LedgerPosting> findPostingsByAccountId(String accountId, Instant from, Instant toExclusive);

    BigDecimal sumAmount(PostingSide side);

    boolean existsJournalEntryByReference(String referenceNumber);
}
