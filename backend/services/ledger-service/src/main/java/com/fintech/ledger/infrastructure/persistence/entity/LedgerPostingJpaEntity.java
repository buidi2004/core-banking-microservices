package com.fintech.ledger.infrastructure.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "ledger_postings")
public class LedgerPostingJpaEntity {

    @Id
    private UUID id;

    @Column(name = "journal_entry_id", nullable = false)
    private UUID journalEntryId;

    @Column(name = "account_id", nullable = false)
    private UUID accountId;

    @Column(nullable = false, length = 10)
    private String side;

    @Column(nullable = false, precision = 19, scale = 2)
    private BigDecimal amount;

    @Column(nullable = false, length = 3)
    private String currency;

    private String description;

    @Column(name = "created_at", insertable = false, updatable = false)
    private LocalDateTime createdAt;

    protected LedgerPostingJpaEntity() {
    }

    public LedgerPostingJpaEntity(String id, UUID journalEntryId, UUID accountId,
                                  String side, BigDecimal amount, String currency, String description) {
        this.id = UUID.fromString(id);
        this.journalEntryId = journalEntryId;
        this.accountId = accountId;
        this.side = side;
        this.amount = amount;
        this.currency = currency;
        this.description = description;
    }

    public String getId() { return id != null ? id.toString() : null; }
    public String getJournalEntryId() { return journalEntryId != null ? journalEntryId.toString() : null; }
    public String getAccountId() { return accountId != null ? accountId.toString() : null; }
    public String getSide() { return side; }
    public BigDecimal getAmount() { return amount; }
    public String getCurrency() { return currency; }
    public String getDescription() { return description; }
    public LocalDateTime getCreatedAt() { return createdAt; }
}
