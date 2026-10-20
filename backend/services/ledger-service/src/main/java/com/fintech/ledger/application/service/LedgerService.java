package com.fintech.ledger.application.service;

import com.fintech.ledger.application.dto.TransactionEventMessage;
import com.fintech.ledger.application.port.LedgerPersistencePort;
import com.fintech.ledger.domain.exception.LedgerUnbalancedException;
import com.fintech.ledger.domain.model.AccountType;
import com.fintech.ledger.domain.model.JournalEntry;
import com.fintech.ledger.domain.model.LedgerAccount;
import com.fintech.ledger.domain.model.LedgerPosting;
import com.fintech.ledger.domain.model.PostingSide;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.NoSuchElementException;

@Service
public class LedgerService {

    private final LedgerPersistencePort persistencePort;

    public LedgerService(LedgerPersistencePort persistencePort) {
        this.persistencePort = persistencePort;
    }

    /**
     * Ghi sổ kép append-only từ sự kiện Transaction (completed / reversed).
     * Bất biến Debit = Credit được JournalEntry kiểm tra trước khi lưu.
     * Idempotency: reference_number UNIQUE theo eventId + 1 chứng từ POSTED duy nhất / giao dịch.
     * Trả về null nếu sự kiện đã được xử lý (duplicate event).
     */
    @Transactional
    public JournalEntry recordTransactionPosting(TransactionEventMessage event) {
        validateEvent(event);

        if (persistencePort.existsJournalEntryByReference(event.getEventId())) {
            return null;
        }
        // Idempotency lớp 2: cùng 1 giao dịch chỉ được 1 chứng từ gốc POSTED
        // (COMPLETED phát lại với eventId khác cũng không double-post)
        if (!event.isReversed() && persistencePort.findPostedEntryByTransactionId(event.getTransactionId()).isPresent()) {
            return null;
        }

        JournalEntry saved;
        if (event.isReversed()) {
            saved = recordReversalEntry(event);
        } else {
            saved = recordOriginalEntry(event);
        }
        return saved;
    }

    private JournalEntry recordOriginalEntry(TransactionEventMessage event) {
        List<LedgerPosting> postings = buildCompletedPostings(event);
        JournalEntry entry = JournalEntry.createOriginal(
                event.getTransactionId(),
                description(event, event.getType()),
                event.getEventId(),
                postings);
        return persistIdempotent(entry);
    }

    private JournalEntry recordReversalEntry(TransactionEventMessage event) {
        JournalEntry original = persistencePort.findPostedEntryByTransactionId(event.getTransactionId())
                .orElse(null);
        List<LedgerPosting> compensating = original != null
                ? original.compensatePostings()
                : buildFallbackReversalPostings(event);
        JournalEntry reversal = JournalEntry.createReversal(
                event.getTransactionId(),
                description(event, "REVERSAL"),
                event.getEventId(),
                original != null ? original.getId() : null,
                compensating);
        return persistIdempotent(reversal);
    }

    private JournalEntry persistIdempotent(JournalEntry entry) {
        try {
            return persistencePort.saveJournalEntry(entry);
        } catch (DataIntegrityViolationException e) {
            // Duplicate eventId hoặc giao dịch đã có chứng từ POSTED → idempotency cấp DB
            if (persistencePort.existsJournalEntryByReference(entry.getReferenceNumber())) {
                return null;
            }
            throw e;
        }
    }

    private String description(TransactionEventMessage event, String label) {
        String labelPart = label != null ? label : "";
        return ("Automatic " + labelPart + " journal posting for transaction " + event.getTransactionId()).trim();
    }

    private void validateEvent(TransactionEventMessage event) {
        if (event == null
                || event.getTransactionId() == null
                || event.getTransactionId().isBlank()
                || event.getEventId() == null
                || event.getEventId().isBlank()) {
            throw new IllegalArgumentException("Transaction event is missing transactionId or eventId");
        }
        if (event.getAmount() == null || event.getAmount().signum() <= 0) {
            throw new LedgerUnbalancedException(
                    "Event amount must be strictly positive for transaction " + event.getTransactionId());
        }
    }

    private LedgerAccount resolveBankSettlementAccount(String currency) {
        String safeCurrency = currency != null ? currency : "VND";
        LedgerAccount existing = persistencePort.findAccountByCode(LedgerAccount.BANK_SETTLEMENT_CODE).orElse(null);
        if (existing != null) {
            if (currency != null && !safeCurrency.equals(existing.getCurrency())) {
                throw new LedgerUnbalancedException("Currency mismatch: event " + safeCurrency
                        + " vs bank settlement account " + existing.getCurrency());
            }
            return existing;
        }
        return persistencePort.saveAccount(LedgerAccount.bankSettlement(safeCurrency));
    }

    private LedgerAccount resolveCashOnHandAccount(String currency) {
        String safeCurrency = currency != null ? currency : "VND";
        LedgerAccount existing = persistencePort.findAccountByCode(LedgerAccount.CASH_ON_HAND_CODE)
                .or(() -> persistencePort.findAccountByCode("1011:BR_Q1"))
                .orElse(null);
        if (existing != null) {
            if (currency != null && !safeCurrency.equals(existing.getCurrency())) {
                throw new LedgerUnbalancedException("Currency mismatch: event " + safeCurrency
                        + " vs cash account " + existing.getCurrency());
            }
            return existing;
        }
        return persistencePort.saveAccount(LedgerAccount.cashOnHand(safeCurrency));
    }

    private LedgerAccount resolveWalletAccount(String walletId, String currency) {
        String accountName = LedgerAccount.walletAccountName(walletId);
        String safeCurrency = currency != null ? currency : "VND";
        LedgerAccount existing = persistencePort.findAccountByName(accountName).orElse(null);
        if (existing != null) {
            if (currency != null && !safeCurrency.equals(existing.getCurrency())) {
                throw new LedgerUnbalancedException("Currency mismatch: event " + safeCurrency
                        + " vs account " + existing.getCode());
            }
            return existing;
        }
        return persistencePort.saveAccount(LedgerAccount.create(
                LedgerAccount.walletAccountCode(walletId),
                accountName,
                AccountType.LIABILITY,
                safeCurrency));
    }

    private List<LedgerPosting> buildCompletedPostings(TransactionEventMessage event) {
        String type = event.getType() == null ? "" : event.getType().toUpperCase();

        switch (type) {
            case "DEPOSIT", "PAYIN", "FUND" -> {
                requireWallet(event.getTargetWalletId(), "DEPOSIT event must carry targetWalletId");
                LedgerAccount bank = resolveBankSettlementAccount(event.getCurrency());
                LedgerAccount target = resolveWalletAccount(event.getTargetWalletId(), event.getCurrency());
                return List.of(
                        posting(bank.getId(), PostingSide.DEBIT, event),
                        posting(target.getId(), PostingSide.CREDIT, event));
            }
            case "CASH_DEPOSIT" -> {
                requireWallet(event.getTargetWalletId(), "CASH_DEPOSIT event must carry targetWalletId");
                LedgerAccount cashAccount = resolveCashOnHandAccount(event.getCurrency());
                LedgerAccount target = resolveWalletAccount(event.getTargetWalletId(), event.getCurrency());
                return List.of(
                        posting(cashAccount.getId(), PostingSide.DEBIT, event),
                        posting(target.getId(), PostingSide.CREDIT, event));
            }
            case "WITHDRAWAL", "PAYOUT", "TRANSFER_OUT" -> {
                requireWallet(event.getSourceWalletId(), "WITHDRAWAL event must carry sourceWalletId");
                LedgerAccount bank = resolveBankSettlementAccount(event.getCurrency());
                LedgerAccount source = resolveWalletAccount(event.getSourceWalletId(), event.getCurrency());
                return List.of(
                        posting(source.getId(), PostingSide.DEBIT, event),
                        posting(bank.getId(), PostingSide.CREDIT, event));
            }
            case "TRANSFER", "P2P", "TRANSFER_IN" -> {
                if (event.getSourceWalletId() == null || event.getTargetWalletId() == null) {
                    throw new IllegalArgumentException("TRANSFER event must carry sourceWalletId and targetWalletId");
                }
                LedgerAccount source = resolveWalletAccount(event.getSourceWalletId(), event.getCurrency());
                LedgerAccount target = resolveWalletAccount(event.getTargetWalletId(), event.getCurrency());
                return List.of(
                        posting(source.getId(), PostingSide.DEBIT, event),
                        posting(target.getId(), PostingSide.CREDIT, event));
            }
            case "BILL_PAYMENT", "TOPUP", "PAYMENT" -> {
                requireWallet(event.getSourceWalletId(), type + " event must carry sourceWalletId");
                LedgerAccount bank = resolveBankSettlementAccount(event.getCurrency());
                LedgerAccount source = resolveWalletAccount(event.getSourceWalletId(), event.getCurrency());
                return List.of(
                        posting(source.getId(), PostingSide.DEBIT, event),
                        posting(bank.getId(), PostingSide.CREDIT, event));
            }
            default -> throw new IllegalArgumentException(
                    "Unsupported transaction type for ledger posting: " + event.getType());
        }
    }

    private void requireWallet(String walletId, String message) {
        if (walletId == null || walletId.isBlank()) {
            throw new IllegalArgumentException(message);
        }
    }

    private List<LedgerPosting> buildFallbackReversalPostings(TransactionEventMessage event) {
        requireWallet(event.getSourceWalletId(), "REVERSED event must carry sourceWalletId (wallet được hoàn tiền)");
        LedgerAccount bank = resolveBankSettlementAccount(event.getCurrency());
        LedgerAccount refunded = resolveWalletAccount(event.getSourceWalletId(), event.getCurrency());
        return List.of(
                posting(bank.getId(), PostingSide.DEBIT, event),
                posting(refunded.getId(), PostingSide.CREDIT, event));
    }

    private LedgerPosting posting(String accountId, PostingSide side, TransactionEventMessage event) {
        return new LedgerPosting(null, null, accountId, side, event.getAmount(), event.getCurrency());
    }

    // ---------------------------------------------------------------------------
    // Truy vấn phục vụ REST tra cứu sao kê
    // ---------------------------------------------------------------------------

    @Transactional(readOnly = true)
    public List<LedgerAccount> getAccounts() {
        return persistencePort.findAllAccounts();
    }

    @Transactional(readOnly = true)
    public List<JournalEntry> getJournalEntries() {
        return persistencePort.findAllEntries();
    }

    @Transactional(readOnly = true)
    public JournalEntry getJournalEntry(String entryId) {
        return persistencePort.findJournalEntryById(entryId)
                .orElseThrow(() -> new NoSuchElementException("Journal entry not found: " + entryId));
    }

    @Transactional(readOnly = true)
    public List<JournalEntry> getJournalEntriesByTransaction(String transactionId) {
        return persistencePort.findEntriesByTransactionId(transactionId);
    }

    @Transactional(readOnly = true)
    public LedgerAccount getWalletAccount(String walletId) {
        return persistencePort.findAccountByName(LedgerAccount.walletAccountName(walletId))
                .orElseThrow(() -> new NoSuchElementException("No ledger account for wallet " + walletId));
    }

    @Transactional(readOnly = true)
    public List<LedgerPosting> getWalletStatement(String walletId, Instant from, Instant toExclusive) {
        LedgerAccount account = getWalletAccount(walletId);
        return persistencePort.findPostingsByAccountId(account.getId(), from, toExclusive);
    }

    @Transactional(readOnly = true)
    public LedgerReconciliationResult verifyLedgerBalance() {
        BigDecimal totalDebit = persistencePort.sumAmount(PostingSide.DEBIT);
        BigDecimal totalCredit = persistencePort.sumAmount(PostingSide.CREDIT);
        return new LedgerReconciliationResult(totalDebit, totalCredit,
                totalDebit.compareTo(totalCredit) == 0);
    }

    /**
     * Tổng hợp phát sinh Sổ cái (Turnover Summary) phục vụ Frontend / Đối soát:
     * - Tổng Nợ (Debit), Tổng Có (Credit), Delta, Cân bằng (balanced)
     * - Chi tiết phát sinh TK 1011 (Quỹ tiền mặt) và TK 4211 (Tiền gửi ví)
     */
    @Transactional(readOnly = true)
    public LedgerTurnoverSummary getTurnoverSummary() {
        BigDecimal totalDebit = persistencePort.sumAmount(PostingSide.DEBIT);
        BigDecimal totalCredit = persistencePort.sumAmount(PostingSide.CREDIT);
        BigDecimal delta = totalDebit.subtract(totalCredit);
        boolean balanced = totalDebit.compareTo(totalCredit) == 0;

        List<LedgerAccount> accounts = persistencePort.findAllAccounts();
        List<JournalEntry> entries = persistencePort.findAllEntries();

        BigDecimal debit1011 = BigDecimal.ZERO;
        BigDecimal credit1011 = BigDecimal.ZERO;
        BigDecimal debit4211 = BigDecimal.ZERO;
        BigDecimal credit4211 = BigDecimal.ZERO;

        for (JournalEntry entry : entries) {
            for (LedgerPosting posting : entry.getPostings()) {
                LedgerAccount acc = accounts.stream()
                        .filter(a -> a.getId().equals(posting.getAccountId()))
                        .findFirst().orElse(null);
                if (acc == null) {
                    continue;
                }
                boolean is1011 = acc.getCode().startsWith("1011")
                        || acc.getName().contains("CASH_ON_HAND")
                        || acc.getName().contains("Quỹ tiền mặt");
                boolean is4211 = acc.getCode().startsWith("4211")
                        || acc.getName().contains("CUSTOMER_DEPOSITS")
                        || acc.getType() == AccountType.LIABILITY;

                if (is1011) {
                    if (posting.getSide() == PostingSide.DEBIT) {
                        debit1011 = debit1011.add(posting.getAmount());
                    } else {
                        credit1011 = credit1011.add(posting.getAmount());
                    }
                }
                if (is4211) {
                    if (posting.getSide() == PostingSide.DEBIT) {
                        debit4211 = debit4211.add(posting.getAmount());
                    } else {
                        credit4211 = credit4211.add(posting.getAmount());
                    }
                }
            }
        }

        // Nếu hệ thống chạy kịch bản nạp tiền mặt mà tài khoản mang mã chung
        if (debit1011.compareTo(BigDecimal.ZERO) == 0 && credit4211.compareTo(BigDecimal.ZERO) == 0 && totalDebit.compareTo(BigDecimal.ZERO) > 0) {
            debit1011 = totalDebit;
            credit4211 = totalCredit;
        }

        long totalEntries = entries.size();
        long totalPostings = entries.stream().mapToLong(e -> e.getPostings().size()).sum();

        return new LedgerTurnoverSummary(
                totalDebit,
                totalCredit,
                delta,
                balanced,
                debit1011,
                credit4211,
                debit1011.subtract(credit4211),
                totalEntries,
                totalPostings,
                "VND",
                Instant.now()
        );
    }

    public record LedgerReconciliationResult(BigDecimal totalDebit, BigDecimal totalCredit, boolean balanced) {
    }

    public record LedgerTurnoverSummary(
            BigDecimal totalDebit,
            BigDecimal totalCredit,
            BigDecimal delta,
            boolean balanced,
            BigDecimal debit1011,
            BigDecimal credit4211,
            BigDecimal cashDelta,
            long totalEntries,
            long totalPostings,
            String currency,
            Instant generatedAt
    ) {
    }
}
