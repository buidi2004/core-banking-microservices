package com.fintech.ledger.infrastructure.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.LocalDateTime;
import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(name = "journal_entries")
public class JournalEntryJpaEntity {

    @Id
    private UUID id;

    @Column(name = "transaction_id", nullable = false, length = 36)
    private String transactionId;

    @Column(name = "entry_number", insertable = false, updatable = false)
    private Long entryNumber;

    @Column(name = "entry_date", insertable = false, updatable = false)
    private LocalDate entryDate;

    @Column(nullable = false)
    private String description;

    @Column(name = "reference_number", length = 64)
    private String referenceNumber;

    @Column(nullable = false, length = 20)
    private String status;

    @Column(name = "reversal_of")
    private UUID reversalOf;


    @Column(name = "posted_at", insertable = false, updatable = false)
    private LocalDateTime postedAt;

    @Column(name = "created_at", insertable = false, updatable = false)
    private LocalDateTime createdAt;

    protected JournalEntryJpaEntity() {
    }

    public JournalEntryJpaEntity(String id, String transactionId, String description,
                                 String referenceNumber, String status, String reversalOf,
                                 LocalDate entryDate) {
        this.id = UUID.fromString(id);
        this.transactionId = transactionId;
        this.entryDate = entryDate;
        this.description = description;
        this.referenceNumber = referenceNumber;
        this.status = status;
        this.reversalOf = reversalOf != null ? UUID.fromString(reversalOf) : null;
    }

    public String getId() { return id != null ? id.toString() : null; }
    public String getTransactionId() { return transactionId; }
    public Long getEntryNumber() { return entryNumber; }
    public LocalDate getEntryDate() { return entryDate; }
    public String getDescription() { return description; }
    public String getReferenceNumber() { return referenceNumber; }
    public String getStatus() { return status; }
    public String getReversalOf() { return reversalOf != null ? reversalOf.toString() : null; }
    public LocalDateTime getPostedAt() { return postedAt; }
    public LocalDateTime getCreatedAt() { return createdAt; }
}
