package com.fintech.wallet.domain.model;

import java.math.BigDecimal;
import java.util.Objects;
import java.util.UUID;

public class LedgerAccount {
    private final String id;
    private final String accountName;
    private final AccountType accountType;
    private final String currency;
    private BigDecimal balance;

    public LedgerAccount(String id, String accountName, AccountType accountType, String currency, BigDecimal balance) {
        this.id = id != null ? id : UUID.randomUUID().toString();
        this.accountName = accountName;
        this.accountType = accountType;
        this.currency = currency != null ? currency : "VND";
        this.balance = balance != null ? balance : BigDecimal.ZERO;
    }

    public static LedgerAccount createNew(String accountName, AccountType accountType, String currency) {
        return new LedgerAccount(
            UUID.randomUUID().toString(),
            accountName,
            accountType,
            currency,
            BigDecimal.ZERO
        );
    }

    public void updateBalance(BigDecimal delta) {
        this.balance = this.balance.add(delta);
    }

    public String getId() { return id; }
    public String getAccountName() { return accountName; }
    public AccountType getAccountType() { return accountType; }
    public String getCurrency() { return currency; }
    public BigDecimal getBalance() { return balance; }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        LedgerAccount account = (LedgerAccount) o;
        return Objects.equals(id, account.id);
    }

    @Override
    public int hashCode() { return Objects.hash(id); }
}
