package com.fintech.ledger.application.service;

import com.fintech.ledger.application.dto.TransactionEventMessage;
import com.fintech.ledger.application.port.LedgerPersistencePort;
import com.fintech.ledger.domain.exception.LedgerUnbalancedException;
import com.fintech.ledger.domain.model.AccountType;
import com.fintech.ledger.domain.model.JournalEntry;
import com.fintech.ledger.domain.model.JournalEntryStatus;
import com.fintech.ledger.domain.model.LedgerAccount;
import com.fintech.ledger.domain.model.LedgerPosting;
import com.fintech.ledger.domain.model.PostingSide;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.NoSuchElementException;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class LedgerServiceTest {

    private LedgerPersistencePort persistencePort;
    private LedgerService ledgerService;

    private LedgerAccount bank;
    private LedgerAccount walletSource;
    private LedgerAccount walletTarget;

    @BeforeEach
    void setUp() {
        persistencePort = mock(LedgerPersistencePort.class);
        ledgerService = new LedgerService(persistencePort);

        bank = LedgerAccount.bankSettlement("VND");
        walletSource = LedgerAccount.create("Waaaaaaaaaaaa", "CUSTOMER_DEPOSITS:source-wallet",
                AccountType.LIABILITY, "VND");
        walletTarget = LedgerAccount.create("Wbbbbbbbbbbbb", "CUSTOMER_DEPOSITS:target-wallet",
                AccountType.LIABILITY, "VND");

        // Seed port trả về các tài khoản đã tồn tại → không phải tạo mới
        when(persistencePort.findAccountByCode("BANK_SETTLEMENT")).thenReturn(Optional.of(bank));
        when(persistencePort.findAccountByName("CUSTOMER_DEPOSITS:source-wallet"))
                .thenReturn(Optional.of(walletSource));
        when(persistencePort.findAccountByName("CUSTOMER_DEPOSITS:target-wallet"))
                .thenReturn(Optional.of(walletTarget));
        when(persistencePort.existsJournalEntryByReference(any())).thenReturn(false);
        when(persistencePort.saveJournalEntry(any())).thenAnswer(inv -> inv.getArgument(0));
    }

    @Test
    void depositPostingIsBalancedDebitEqualsCredit() {
        // Act: nạp tiền 250.000 cho target-wallet
        JournalEntry entry = ledgerService.recordTransactionPosting(event(
                "DEPOSIT", "SUCCESS", null, "target-wallet", "250000.00", "event-1", "tx-1"));

        // Assert: tổng Nợ = tổng Có, đúng 2 dòng bút toán DEBIT + CREDIT
        assertThat(entry).isNotNull();
        BigDecimal debit = total(entry, PostingSide.DEBIT);
        BigDecimal credit = total(entry, PostingSide.CREDIT);
        assertThat(debit).isEqualByComparingTo(credit);
        assertThat(debit).isEqualByComparingTo("250000.00");
        assertThat(entry.getPostings()).extracting(LedgerPosting::getSide)
                .containsExactlyInAnyOrder(PostingSide.DEBIT, PostingSide.CREDIT);
        assertThat(entry.getStatus()).isEqualTo(JournalEntryStatus.POSTED);
    }

    @Test
    void transferPostingIsBalancedAndMatchesAccountSemantics() {
        // Act: chuyển nội bộ source-wallet → target-wallet
        JournalEntry entry = ledgerService.recordTransactionPosting(event(
                "TRANSFER", "SUCCESS", "source-wallet", "target-wallet", "90000.00", "event-2", "tx-2"));

        // Assert: Nợ = Có; Nợ vào tài khoản người gửi, Có vào tài khoản người nhận
        assertThat(total(entry, PostingSide.DEBIT)).isEqualByComparingTo(total(entry, PostingSide.CREDIT));
        assertThat(entry.getPostings().stream()
                .filter(p -> p.getSide() == PostingSide.DEBIT)
                .findFirst().orElseThrow().getAccountId())
                .isEqualTo(walletSource.getId());
        assertThat(entry.getPostings().stream()
                .filter(p -> p.getSide() == PostingSide.CREDIT)
                .findFirst().orElseThrow().getAccountId())
                .isEqualTo(walletTarget.getId());
    }

    @Test
    void reversalPostingIsBalancedAndCompensatesOriginalEntry() {
        // Given: giao dịch source → target đã được ghi chứng từ gốc
        JournalEntry original = ledgerService.recordTransactionPosting(event(
                "TRANSFER", "SUCCESS", "source-wallet", "target-wallet", "70000.00", "event-3", "tx-9"));
        when(persistencePort.findPostedEntryByTransactionId(original.getTransactionId()))
                .thenReturn(Optional.of(original));

        // When: sự kiện REVERSED của cùng giao dịch
        JournalEntry reversal = ledgerService.recordTransactionPosting(event(
                "TRANSFER", "REVERSED", "source-wallet", "target-wallet", "70000.00", "reversal-event-3", "tx-9"));

        // Assert: chứng từ bù REVERSAL, tham chiếu chứng từ gốc, đảo chiều 1:1 và vẫn cân Nợ/Có
        assertThat(reversal.getStatus()).isEqualTo(JournalEntryStatus.REVERSAL);
        assertThat(reversal.getReversalOf()).isEqualTo(original.getId());
        assertThat(total(reversal, PostingSide.DEBIT)).isEqualByComparingTo(total(reversal, PostingSide.CREDIT));

        PostingSide originalDebitSide = original.getPostings().stream()
                .filter(p -> p.getAccountId().equals(walletSource.getId())).findFirst().orElseThrow().getSide();
        PostingSide reversalSourceSide = reversal.getPostings().stream()
                .filter(p -> p.getAccountId().equals(walletSource.getId())).findFirst().orElseThrow().getSide();
        assertThat(reversalSourceSide).isNotEqualTo(originalDebitSide);
    }

    @Test
    void duplicateEventIdIsIgnoredIdempotently() {
        // Given: sự kiện đã được ghi sổ trước đó
        when(persistencePort.existsJournalEntryByReference("event-dup", "tx-dup")).thenReturn(true);

        // When
        JournalEntry result = ledgerService.recordTransactionPosting(event(
                "DEPOSIT", "SUCCESS", null, "target-wallet", "111.00", "event-dup", "tx-dup"));

        // Assert: không ghi thêm chứng từ nào
        assertThat(result).isNull();
        verify(persistencePort, never()).saveJournalEntry(any());
    }

    @Test
    void nonPositiveAmountIsRejected() {
        // Then: amount = 0 → chống ghi bút toán số 0 (hợp đồng sự kiện sai)
        assertThatThrownBy(() -> ledgerService.recordTransactionPosting(event(
                "DEPOSIT", "SUCCESS", null, "target-wallet", "0.00", "event-zero", "tx-zero")))
                .isInstanceOf(LedgerUnbalancedException.class)
                .hasMessageContaining("strictly positive");
    }

    @Test
    void unknownTransactionTypeIsRejected() {
        // Then: loại giao dịch ngoài hợp đồng → consumer phải đẩy xuống DLQ
        assertThatThrownBy(() -> ledgerService.recordTransactionPosting(event(
                "MYSTERY_TYPE", "SUCCESS", "source-wallet", "target-wallet", "100.00", "event-x", "tx-x")))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Unsupported transaction type");
    }

    @Test
    void currencyMismatchWithExistingAccountIsRejected() {
        // Given: BANK_SETTLEMENT tồn tại nhưng USD trong khi sự kiện VND
        LedgerAccount usdBank = LedgerAccount.of(UUID.randomUUID().toString(), "BANK_SETTLEMENT",
                "Bank Settlement (USD)", AccountType.ASSET, java.math.BigDecimal.ZERO, "USD");
        when(persistencePort.findAccountByCode("BANK_SETTLEMENT")).thenReturn(Optional.of(usdBank));

        // Then: không cho phép trộn tiền tệ trên cùng tài khoản
        assertThatThrownBy(() -> ledgerService.recordTransactionPosting(event(
                "DEPOSIT", "SUCCESS", null, "target-wallet", "500.00", "event-currency", "tx-cur")))
                .isInstanceOf(LedgerUnbalancedException.class)
                .hasMessageContaining("Currency mismatch");
    }

    @Test
    void statementQueryFailsForWalletWithoutLedgerAccount() {
        assertThatThrownBy(() -> ledgerService.getWalletAccount("ghost-wallet"))
                .isInstanceOf(NoSuchElementException.class)
                .hasMessageContaining("ghost-wallet");
    }

    @Test
    void reconciliationComparesDebitAndCreditTotals() {
        when(persistencePort.sumAmount(PostingSide.DEBIT)).thenReturn(new java.math.BigDecimal("1000.00"));
        when(persistencePort.sumAmount(PostingSide.CREDIT)).thenReturn(new java.math.BigDecimal("1000.00"));

        LedgerService.LedgerReconciliationResult result = ledgerService.verifyLedgerBalance();

        assertThat(result.balanced()).isTrue();
        assertThat(result.totalDebit()).isEqualByComparingTo(result.totalCredit());
    }

    private TransactionEventMessage event(String type, String status, String source,
                                          String target, String amount, String eventId, String transactionId) {
        TransactionEventMessage event = new TransactionEventMessage();
        event.setEventId(eventId);
        event.setTransactionId(transactionId);
        event.setType(type);
        event.setStatus(status);
        event.setSourceWalletId(source);
        event.setTargetWalletId(target);
        event.setAmount(new java.math.BigDecimal(amount));
        event.setCurrency("VND");
        return event;
    }

    private BigDecimal total(JournalEntry entry, PostingSide side) {
        return entry.getPostings().stream()
                .filter(p -> p.getSide() == side)
                .map(LedgerPosting::getAmount)
                .reduce(java.math.BigDecimal.ZERO, java.math.BigDecimal::add);
    }
}
