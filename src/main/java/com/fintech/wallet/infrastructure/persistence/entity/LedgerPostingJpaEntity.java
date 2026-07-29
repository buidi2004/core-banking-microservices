package com.fintech.wallet.infrastructure.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.math.BigDecimal;

@Entity
@Table(name = "ledger_postings")
public class LedgerPostingJpaEntity {

    @Id
    private String id;

    @Column(nullable = false)
    private String journalEntryId;

    @Column(nullable = false)
    private String accountId;

    @Column(nullable = false)
    private String entryType;

    @Column(nullable = false)
    private BigDecimal amount;

    public LedgerPostingJpaEntity() {}

    public LedgerPostingJpaEntity(String id, String journalEntryId, String accountId, String entryType, BigDecimal amount) {
        this.id = id;
        this.journalEntryId = journalEntryId;
        this.accountId = accountId;
        this.entryType = entryType;
        this.amount = amount;
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getJournalEntryId() { return journalEntryId; }
    public void setJournalEntryId(String journalEntryId) { this.journalEntryId = journalEntryId; }
    public String getAccountId() { return accountId; }
    public void setAccountId(String accountId) { this.accountId = accountId; }
    public String getEntryType() { return entryType; }
    public void setEntryType(String entryType) { this.entryType = entryType; }
    public BigDecimal getAmount() { return amount; }
    public void setAmount(BigDecimal amount) { this.amount = amount; }
}
