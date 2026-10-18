package com.fintech.wallet.infrastructure.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.math.BigDecimal;

@Entity
@Table(name = "ledger_accounts")
public class LedgerAccountJpaEntity {

    @Id
    private String id;

    @Column(nullable = false)
    private String accountName;

    @Column(nullable = false)
    private String accountType;

    @Column(nullable = false)
    private String currency;

    @Column(nullable = false)
    private BigDecimal balance;

    public LedgerAccountJpaEntity() {}

    public LedgerAccountJpaEntity(String id, String accountName, String accountType, String currency, BigDecimal balance) {
        this.id = id;
        this.accountName = accountName;
        this.accountType = accountType;
        this.currency = currency;
        this.balance = balance;
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getAccountName() { return accountName; }
    public void setAccountName(String accountName) { this.accountName = accountName; }
    public String getAccountType() { return accountType; }
    public void setAccountType(String accountType) { this.accountType = accountType; }
    public String getCurrency() { return currency; }
    public void setCurrency(String currency) { this.currency = currency; }
    public BigDecimal getBalance() { return balance; }
    public void setBalance(BigDecimal balance) { this.balance = balance; }
}
