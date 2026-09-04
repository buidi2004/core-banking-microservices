package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.model.AccountType;
import com.fintech.wallet.domain.model.EntryType;
import com.fintech.wallet.domain.model.JournalEntry;
import com.fintech.wallet.domain.model.LedgerAccount;
import com.fintech.wallet.domain.model.LedgerPosting;
import com.fintech.wallet.domain.port.in.LedgerUseCase;
import com.fintech.wallet.domain.port.out.LedgerPersistencePort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class LedgerService implements LedgerUseCase {

    private final LedgerPersistencePort ledgerPersistencePort;

    public LedgerService(LedgerPersistencePort ledgerPersistencePort) {
        this.ledgerPersistencePort = ledgerPersistencePort;
    }

    @Override
    @Transactional
    public LedgerAccount createAccount(String accountName, AccountType accountType, String currency) {
        LedgerAccount account = LedgerAccount.createNew(accountName, accountType, currency);
        return ledgerPersistencePort.saveAccount(account);
    }

    @Override
    @Transactional
    public JournalEntry recordJournalEntry(String transactionId, String description, String idempotencyKey, List<LedgerPosting> postings) {
        // JournalEntry constructor automatically validates Debit == Credit
        JournalEntry entry = JournalEntry.create(transactionId, description, idempotencyKey, postings);

        // Update account balances
        for (LedgerPosting posting : entry.getPostings()) {
            LedgerAccount account = ledgerPersistencePort.findAccountById(posting.getAccountId())
                    .orElseThrow(() -> new IllegalArgumentException("Ledger Account not found: " + posting.getAccountId()));

            // ASSET / EXPENSE increase with DEBIT, decrease with CREDIT
            // LIABILITY / EQUITY / REVENUE increase with CREDIT, decrease with DEBIT
            if (account.getAccountType() == AccountType.ASSET || account.getAccountType() == AccountType.EXPENSE) {
                if (posting.getEntryType() == EntryType.DEBIT) {
                    account.updateBalance(posting.getAmount());
                } else {
                    account.updateBalance(posting.getAmount().negate());
                }
            } else {
                if (posting.getEntryType() == EntryType.CREDIT) {
                    account.updateBalance(posting.getAmount());
                } else {
                    account.updateBalance(posting.getAmount().negate());
                }
            }
            ledgerPersistencePort.saveAccount(account);
        }

        return ledgerPersistencePort.saveJournalEntry(entry);
    }

    @Override
    public List<LedgerAccount> getAllAccounts() {
        return ledgerPersistencePort.findAllAccounts();
    }

    @Override
    public List<JournalEntry> getAllJournalEntries() {
        return ledgerPersistencePort.findAllJournalEntries();
    }
}
