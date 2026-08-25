package com.fintech.wallet.domain.port.out;

import com.fintech.wallet.domain.model.JournalEntry;
import com.fintech.wallet.domain.model.LedgerAccount;

import java.util.List;
import java.util.Optional;

public interface LedgerPersistencePort {
    LedgerAccount saveAccount(LedgerAccount account);
    Optional<LedgerAccount> findAccountById(String accountId);
    List<LedgerAccount> findAllAccounts();

    JournalEntry saveJournalEntry(JournalEntry journalEntry);
    List<JournalEntry> findAllJournalEntries();
}
