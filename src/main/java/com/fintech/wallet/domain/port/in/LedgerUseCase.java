package com.fintech.wallet.domain.port.in;

import com.fintech.wallet.domain.model.AccountType;
import com.fintech.wallet.domain.model.JournalEntry;
import com.fintech.wallet.domain.model.LedgerAccount;
import com.fintech.wallet.domain.model.LedgerPosting;

import java.util.List;

public interface LedgerUseCase {
    LedgerAccount createAccount(String accountName, AccountType accountType, String currency);
    JournalEntry recordJournalEntry(String transactionId, String description, List<LedgerPosting> postings);
    List<LedgerAccount> getAllAccounts();
    List<JournalEntry> getAllJournalEntries();
}
