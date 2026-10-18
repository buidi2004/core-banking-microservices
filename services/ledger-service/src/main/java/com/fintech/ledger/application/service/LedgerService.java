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

    public record LedgerReconciliationResult(BigDecimal totalDebit, BigDecimal totalCredit, boolean balanced) {
    }
}
