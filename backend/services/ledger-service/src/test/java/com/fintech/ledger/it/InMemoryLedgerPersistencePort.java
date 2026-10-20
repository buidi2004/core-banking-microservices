package com.fintech.ledger.it;

import com.fintech.ledger.application.port.LedgerPersistencePort;
import com.fintech.ledger.domain.model.JournalEntry;
import com.fintech.ledger.domain.model.LedgerAccount;
import com.fintech.ledger.domain.model.LedgerPosting;
import com.fintech.ledger.domain.model.PostingSide;
import org.springframework.dao.DataIntegrityViolationException;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

/**
 * PersistencePort trong bộ nhớ cho phép kiểm thử Kịch bản Kafka:
 * mô phỏng đúng ràng buộc idempotency của ewallet_ledger_db:
 * - reference_number (eventId) UNIQUE
 * - 1 giao dịch chỉ có 1 chứng từ POSTED
 * - Thứ tự ghi sổ = thứ tự xử lý (thứ tự offset theo partition, key=walletId)
 */
public class InMemoryLedgerPersistencePort implements LedgerPersistencePort {

    private final Map<String, LedgerAccount> accountsByCode = new LinkedHashMap<>();
    private final Map<String, LedgerAccount> accountsByName = new LinkedHashMap<>();
    private final Map<String, LedgerAccount> accountsById = new LinkedHashMap<>();
    private final List<JournalEntry> entries = new ArrayList<>();
    private final Map<String, JournalEntry> entriesById = new LinkedHashMap<>();
    private final Map<String, JournalEntry> entriesByReference = new LinkedHashMap<>();

    @Override
    public synchronized LedgerAccount saveAccount(LedgerAccount account) {
        accountsById.put(account.getId(), account);
        accountsByCode.put(account.getCode(), account);
        accountsByName.put(account.getName(), account);
        return account;
    }

    @Override
    public synchronized Optional<LedgerAccount> findAccountByCode(String code) {
        return Optional.ofNullable(accountsByCode.get(code));
    }

    @Override
    public synchronized Optional<LedgerAccount> findAccountByName(String name) {
        return Optional.ofNullable(accountsByName.get(name));
    }

    @Override
    public synchronized List<LedgerAccount> findAllAccounts() {
        return new ArrayList<>(accountsById.values());
    }

    @Override
    public synchronized Optional<LedgerAccount> findAccountById(String accountId) {
        return Optional.ofNullable(accountsById.get(accountId));
    }

    @Override
    public synchronized JournalEntry saveJournalEntry(JournalEntry entry) {
        if (entry.getReferenceNumber() != null && entriesByReference.containsKey(entry.getReferenceNumber())) {
            throw new DataIntegrityViolationException(
                    "Duplicate reference_number: " + entry.getReferenceNumber());
        }
        if (entry.getStatus() == com.fintech.ledger.domain.model.JournalEntryStatus.POSTED
                && findPostedEntryByTransactionId(entry.getTransactionId()).isPresent()) {
            throw new DataIntegrityViolationException(
                    "Transaction already has a POSTED entry: " + entry.getTransactionId());
        }
        entries.add(entry);
        entriesById.put(entry.getId(), entry);
        if (entry.getReferenceNumber() != null) {
            entriesByReference.put(entry.getReferenceNumber(), entry);
        }
        return entry;
    }

    @Override
    public synchronized Optional<JournalEntry> findJournalEntryById(String entryId) {
        return Optional.ofNullable(entriesById.get(entryId));
    }

    @Override
    public synchronized Optional<JournalEntry> findJournalEntryByReference(String referenceNumber) {
        return Optional.ofNullable(entriesByReference.get(referenceNumber));
    }

    @Override
    public synchronized Optional<JournalEntry> findPostedEntryByTransactionId(String transactionId) {
        return entries.stream()
                .filter(e -> e.getTransactionId().equals(transactionId))
                .filter(e -> e.getStatus() == com.fintech.ledger.domain.model.JournalEntryStatus.POSTED)
                .findFirst();
    }

    @Override
    public synchronized List<JournalEntry> findEntriesByTransactionId(String transactionId) {
        return entries.stream()
                .filter(e -> e.getTransactionId().equals(transactionId))
                .collect(Collectors.toList());
    }

    @Override
    public synchronized List<JournalEntry> findAllEntries() {
        return new ArrayList<>(entries);
    }

    @Override
    public synchronized List<LedgerPosting> findPostingsByEntryId(String entryId) {
        JournalEntry entry = entriesById.get(entryId);
        return entry != null ? entry.getPostings() : List.of();
    }

    @Override
    public synchronized List<LedgerPosting> findPostingsByAccountId(String accountId, Instant from, Instant toExclusive) {
        return entries.stream()
                .flatMap(e -> e.getPostings().stream())
                .filter(p -> p.getAccountId().equals(accountId))
                .collect(Collectors.toList());
    }

    @Override
    public synchronized BigDecimal sumAmount(PostingSide side) {
        return entries.stream()
                .flatMap(e -> e.getPostings().stream())
                .filter(p -> p.getSide() == side)
                .map(LedgerPosting::getAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    @Override
    public synchronized boolean existsJournalEntryByReference(String referenceNumber) {
        return entriesByReference.containsKey(referenceNumber);
    }

    /** Số dư cộng dồn của 1 tài khoản theo THỨ TỰ GHI SỔ (mô phỏng strict ordering theo partition) */
    public synchronized List<BigDecimal> balanceTimeline(String accountId) {
        BigDecimal running = BigDecimal.ZERO;
        List<BigDecimal> timeline = new ArrayList<>();
        for (JournalEntry entry : entries) {
            for (LedgerPosting posting : entry.getPostings()) {
                if (!posting.getAccountId().equals(accountId)) {
                    continue;
                }
                running = running.add(posting.getSide() == PostingSide.CREDIT
                        ? posting.getAmount()
                        : posting.getAmount().negate());
                timeline.add(running);
            }
        }
        return timeline;
    }

    public synchronized LedgerAccount walletAccount(String walletId) {
        LedgerAccount account = accountsByName.get(LedgerAccount.walletAccountName(walletId));
        if (account == null) {
            throw new IllegalArgumentException("No ledger account for wallet: " + walletId);
        }
        return account;
    }
}
