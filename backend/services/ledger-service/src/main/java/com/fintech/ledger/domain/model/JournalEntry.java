package com.fintech.ledger.domain.model;

import com.fintech.ledger.domain.exception.LedgerUnbalancedException;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.UUID;

public class JournalEntry {

    private final String id;
    private final String transactionId;
    private final String entryNumber;
    private final LocalDate entryDate;
    private final String description;
    private final String referenceNumber;
    private final JournalEntryStatus status;
    private final String reversalOf;
    private final Instant postedAt;
    private final List<LedgerPosting> postings;

    private JournalEntry(String id, String transactionId, String entryNumber, LocalDate entryDate,
                         String description, String referenceNumber, JournalEntryStatus status,
                         String reversalOf, Instant postedAt, List<LedgerPosting> postings) {
        if (transactionId == null || transactionId.isBlank()) {
            throw new IllegalArgumentException("Journal entry transaction id must not be null or blank");
        }
        if (description == null || description.isBlank()) {
            throw new IllegalArgumentException("Journal entry description must not be null or blank");
        }
        this.id = (id == null || id.isBlank()) ? UUID.randomUUID().toString() : id;
        this.transactionId = transactionId;
        this.entryNumber = entryNumber;
        this.entryDate = entryDate != null ? entryDate : LocalDate.now();
        this.description = description;
        this.referenceNumber = referenceNumber;
        this.status = status != null ? status : JournalEntryStatus.POSTED;
        this.reversalOf = reversalOf;
        this.postedAt = postedAt != null ? postedAt : Instant.now();
        this.postings = linkPostings(postings);
        validateBalanced();
    }

    /**
     * Chứng từ gốc (POSTED): áp đặt bất biến Debit = Credit.
     */
    public static JournalEntry createOriginal(String transactionId, String description,
                                              String referenceNumber, List<LedgerPosting> postings) {
        return new JournalEntry(null, transactionId, null, null, description,
                referenceNumber, JournalEntryStatus.POSTED, null, null, postings);
    }

    /**
     * Chứng từ bù (REVERSAL): đạt tính bất biến Debit = Credit - không sửa xóa chứng từ gốc.
     */
    public static JournalEntry createReversal(String transactionId, String description,
                                              String referenceNumber, String reversalOf,
                                              List<LedgerPosting> compensatingPostings) {
        if (reversalOf == null || reversalOf.isBlank()) {
            throw new IllegalArgumentException("Reversal journal entry must reference the original entry");
        }
        return new JournalEntry(null, transactionId, null, null, description,
                referenceNumber, JournalEntryStatus.REVERSAL, reversalOf, null, compensatingPostings);
    }

    /** Khôi phục chứng từ đã được lưu (vẫn kiểm tra ràng buộc Debit = Credit) */
    public static JournalEntry rehydrate(String id, String transactionId, String entryNumber,
                                         LocalDate entryDate, String description, String referenceNumber,
                                         JournalEntryStatus status, String reversalOf, Instant postedAt,
                                         List<LedgerPosting> postings) {
        return new JournalEntry(id, transactionId, entryNumber, entryDate, description,
                referenceNumber, status, reversalOf, postedAt, postings);
    }

    private List<LedgerPosting> linkPostings(List<LedgerPosting> postings) {
        List<LedgerPosting> linked = new ArrayList<>();
        if (postings != null) {
            for (LedgerPosting p : postings) {
                linked.add(new LedgerPosting(p.getId(), this.id, p.getAccountId(), p.getSide(),
                        p.getAmount(), p.getCurrency()));
            }
        }
        if (linked.size() < 2) {
            throw new LedgerUnbalancedException("Journal entry must contain at least two postings (one DEBIT and one CREDIT)");
        }
        return Collections.unmodifiableList(linked);
    }

    /**
     * Ràng buộc cốt lõi của sổ kế toán kép: tổng Nợ phải bằng tổng Có.
     */
    private void validateBalanced() {
        BigDecimal totalDebit = BigDecimal.ZERO;
        BigDecimal totalCredit = BigDecimal.ZERO;
        for (LedgerPosting posting : postings) {
            if (posting.getCurrency() != null && !posting.getCurrency().equals(getPostingCurrency())) {
                throw new LedgerUnbalancedException("Journal entry contains mixed currencies");
            }
            if (posting.getSide() == PostingSide.DEBIT) {
                totalDebit = totalDebit.add(posting.getAmount());
            } else {
                totalCredit = totalCredit.add(posting.getAmount());
            }
        }
        if (totalDebit.compareTo(totalCredit) != 0) {
            throw new LedgerUnbalancedException(
                    "Unbalanced journal entry: total DEBIT (" + totalDebit + ") != total CREDIT (" + totalCredit + ")");
        }
    }

    private String getPostingCurrency() {
        return postings.get(0).getCurrency();
    }

    /** Tạo các dòng bút toán bù = đảo chiều 1:1 của các dòng bút toán gốc */
    public List<LedgerPosting> compensatePostings() {
        List<LedgerPosting> compensated = new ArrayList<>();
        for (LedgerPosting posting : postings) {
            compensated.add(new LedgerPosting(null, null, posting.getAccountId(),
                    posting.getSide() == PostingSide.DEBIT ? PostingSide.CREDIT : PostingSide.DEBIT,
                    posting.getAmount(), posting.getCurrency()));
        }
        return compensated;
    }

    public String getId() { return id; }
    public String getTransactionId() { return transactionId; }
    public String getEntryNumber() { return entryNumber; }
    public LocalDate getEntryDate() { return entryDate; }
    public String getDescription() { return description; }
    public String getReferenceNumber() { return referenceNumber; }
    public JournalEntryStatus getStatus() { return status; }
    public String getReversalOf() { return reversalOf; }
    public Instant getPostedAt() { return postedAt; }
    public List<LedgerPosting> getPostings() { return postings; }
}
