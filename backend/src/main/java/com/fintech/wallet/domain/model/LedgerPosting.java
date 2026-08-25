package com.fintech.wallet.domain.model;

import java.math.BigDecimal;
import java.util.UUID;

public class LedgerPosting {
    private final String id;
    private final String journalEntryId;
    private final String accountId;
    private final EntryType entryType;
    private final BigDecimal amount;

    public LedgerPosting(String id, String journalEntryId, String accountId, EntryType entryType, BigDecimal amount) {
        if (amount == null || amount.compareTo(BigDecimal.ZERO) < 0) {
            throw new IllegalArgumentException("Amount cannot be null or negative");
        }
        this.id = id != null ? id : UUID.randomUUID().toString();
        this.journalEntryId = journalEntryId;
        this.accountId = accountId;
        this.entryType = entryType;
        this.amount = amount;
    }

    public String getId() { return id; }
    public String getJournalEntryId() { return journalEntryId; }
    public String getAccountId() { return accountId; }
    public EntryType getEntryType() { return entryType; }
    public BigDecimal getAmount() { return amount; }
}
