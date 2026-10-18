package com.fintech.wallet.infrastructure.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;

@Entity
@Table(name = "journal_entries")
public class JournalEntryJpaEntity {

    @Id
    private String id;

    private String transactionId;
    private String description;
    
    @Column(name = "idempotency_key", unique = true)
    private String idempotencyKey;

    @Column(nullable = false, updatable = false)
    private Instant createdAt;

    public JournalEntryJpaEntity() {}

    public JournalEntryJpaEntity(String id, String transactionId, String description, String idempotencyKey, Instant createdAt) {
        this.id = id;
        this.transactionId = transactionId;
        this.description = description;
        this.idempotencyKey = idempotencyKey;
        this.createdAt = createdAt;
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getTransactionId() { return transactionId; }
    public void setTransactionId(String transactionId) { this.transactionId = transactionId; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public String getIdempotencyKey() { return idempotencyKey; }
    public void setIdempotencyKey(String idempotencyKey) { this.idempotencyKey = idempotencyKey; }
    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
