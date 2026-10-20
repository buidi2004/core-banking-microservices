package com.fintech.ledger.domain.model;

import java.math.BigDecimal;
import java.util.UUID;

public class LedgerPosting {

    private final String id;
    private final String journalEntryId;
    private final String accountId;
    private final PostingSide side;
    private final BigDecimal amount;
    private final String currency;

    public LedgerPosting(String id, String journalEntryId, String accountId,
                         PostingSide side, BigDecimal amount, String currency) {
        if (accountId == null || accountId.isBlank()) {
            throw new IllegalArgumentException("Ledger posting account id must not be null or blank");
        }
        if (side == null) {
            throw new IllegalArgumentException("Ledger posting side must not be null");
        }
        if (amount == null || amount.signum() <= 0) {
            throw new IllegalArgumentException("Ledger posting amount must be strictly positive");
        }
        this.id = (id == null || id.isBlank()) ? UUID.randomUUID().toString() : id;
        this.journalEntryId = journalEntryId;
        this.accountId = accountId;
        this.side = side;
        this.amount = amount;
        this.currency = currency != null ? currency : "VND";
    }

    /** Bút toán đảo chiều (phục vụ chứng từ bù REVERSAL, giữ nguyên số dư tài khoản gốc) */
    public LedgerPosting invert() {
        return new LedgerPosting(UUID.randomUUID().toString(), journalEntryId, accountId,
                side == PostingSide.DEBIT ? PostingSide.CREDIT : PostingSide.DEBIT, amount, currency);
    }

    public String getId() { return id; }
    public String getJournalEntryId() { return journalEntryId; }
    public String getAccountId() { return accountId; }
    public PostingSide getSide() { return side; }
    public BigDecimal getAmount() { return amount; }
    public String getCurrency() { return currency; }
}
