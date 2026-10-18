package com.fintech.ledger.domain.model;

import java.math.BigDecimal;
import java.util.Objects;
import java.util.UUID;

public class LedgerAccount {

    public static final String BANK_SETTLEMENT_CODE = "BANK_SETTLEMENT";

    private final String id;
    private final String code;
    private final String name;
    private final AccountType type;
    private final BigDecimal balance;
    private final String currency;

    private LedgerAccount(String id, String code, String name, AccountType type,
                          BigDecimal balance, String currency) {
        if (code == null || code.isBlank()) {
            throw new IllegalArgumentException("Ledger account code must not be null or blank");
        }
        if (code.length() > 20) {
            throw new IllegalArgumentException("Ledger account code must be at most 20 characters: " + code);
        }
        this.id = (id == null || id.isBlank()) ? UUID.randomUUID().toString() : id;
        this.code = code;
        this.name = (name == null || name.isBlank()) ? code : name;
        this.type = type;
        this.balance = balance != null ? balance : BigDecimal.ZERO;
        this.currency = currency != null ? currency : "VND";
    }

    public static LedgerAccount of(String id, String code, String name, AccountType type,
                                   BigDecimal balance, String currency) {
        return new LedgerAccount(id, code, name, type, balance, currency);
    }

    public static LedgerAccount create(String code, String name, AccountType type, String currency) {
        return new LedgerAccount(UUID.randomUUID().toString(), code, name, type, BigDecimal.ZERO, currency);
    }

    public static LedgerAccount bankSettlement(String currency) {
        return create(BANK_SETTLEMENT_CODE, "Bank Settlement Account", AccountType.ASSET, currency);
    }

    public static String walletAccountCode(String walletId) {
        return "W" + walletId.replace("-", "").substring(0, 12);
    }

    public static String walletAccountName(String walletId) {
        return "CUSTOMER_DEPOSITS:" + walletId;
    }

    public String getId() { return id; }
    public String getCode() { return code; }
    public String getName() { return name; }
    public AccountType getType() { return type; }
    public BigDecimal getBalance() { return balance; }
    public String getCurrency() { return currency; }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        return Objects.equals(id, ((LedgerAccount) o).id);
    }

    @Override
    public int hashCode() { return Objects.hash(id); }
}
