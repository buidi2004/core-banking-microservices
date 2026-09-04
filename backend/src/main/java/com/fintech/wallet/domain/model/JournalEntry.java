package com.fintech.wallet.domain.model;

import com.fintech.wallet.domain.exception.LedgerUnbalancedException;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.UUID;

public class JournalEntry {
    private final String id;
    private final String transactionId;
    private final String description;
    private final String idempotencyKey;
    private final Instant createdAt;
    private final List<LedgerPosting> postings;

    public JournalEntry(String id, String transactionId, String description, String idempotencyKey, Instant createdAt, List<LedgerPosting> postings) {
        this.id = id != null ? id : UUID.randomUUID().toString();
        this.transactionId = transactionId;
        this.description = description;
        this.idempotencyKey = idempotencyKey;
        this.createdAt = createdAt != null ? createdAt : Instant.now();
        
        List<LedgerPosting> linkedPostings = new ArrayList<>();
        if (postings != null) {
            for (LedgerPosting p : postings) {
                linkedPostings.add(new LedgerPosting(p.getId(), this.id, p.getAccountId(), p.getEntryType(), p.getAmount()));
            }
        }
        this.postings = linkedPostings;
        validateBalanced();
    }

    public static JournalEntry create(String transactionId, String description, String idempotencyKey, List<LedgerPosting> postings) {
        return new JournalEntry(UUID.randomUUID().toString(), transactionId, description, idempotencyKey, Instant.now(), postings);
    }

    private void validateBalanced() {
        if (postings.isEmpty()) return;

        BigDecimal totalDebit = BigDecimal.ZERO;
        BigDecimal totalCredit = BigDecimal.ZERO;

        for (LedgerPosting posting : postings) {
            if (posting.getEntryType() == EntryType.DEBIT) {
                totalDebit = totalDebit.add(posting.getAmount());
            } else if (posting.getEntryType() == EntryType.CREDIT) {
                totalCredit = totalCredit.add(posting.getAmount());
            }
        }

        if (totalDebit.compareTo(totalCredit) != 0) {
            throw new LedgerUnbalancedException("Unbalanced journal entry! Total DEBIT (" + totalDebit + ") != Total CREDIT (" + totalCredit + ")");
        }
    }

    public String getId() { return id; }
    public String getTransactionId() { return transactionId; }
    public String getDescription() { return description; }
    public String getIdempotencyKey() { return idempotencyKey; }
    public Instant getCreatedAt() { return createdAt; }
    public List<LedgerPosting> getPostings() { return Collections.unmodifiableList(postings); }
}
