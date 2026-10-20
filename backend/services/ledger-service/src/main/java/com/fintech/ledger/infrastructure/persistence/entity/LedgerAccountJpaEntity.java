package com.fintech.ledger.infrastructure.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "ledger_accounts")
public class LedgerAccountJpaEntity {

    @Id
    private UUID id;

    @Column(nullable = false, length = 20, unique = true)
    private String code;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false, length = 20)
    private String type;

    @Column(nullable = false, precision = 19, scale = 2)
    private BigDecimal balance;

    @Column(nullable = false, length = 3)
    private String currency;

    @Column(name = "is_active", nullable = false)
    private boolean active;

    private String description;

    @Column(name = "created_at", insertable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", insertable = false, updatable = false)
    private LocalDateTime updatedAt;

    protected LedgerAccountJpaEntity() {
    }

    public LedgerAccountJpaEntity(String id, String code, String name, String type,
                                  BigDecimal balance, String currency) {
        this.id = UUID.fromString(id);
        this.code = code;
        this.name = name;
        this.type = type;
        this.balance = balance != null ? balance : BigDecimal.ZERO;
        this.currency = currency;
        this.active = true;
    }

    public String getId() { return id != null ? id.toString() : null; }
    public String getCode() { return code; }
    public String getName() { return name; }
    public String getType() { return type; }
    public BigDecimal getBalance() { return balance; }
    public String getCurrency() { return currency; }
    public boolean isActive() { return active; }
    public String getDescription() { return description; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
}
