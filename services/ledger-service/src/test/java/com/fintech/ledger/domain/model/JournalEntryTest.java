package com.fintech.ledger.domain.model;

import com.fintech.ledger.domain.exception.LedgerUnbalancedException;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class JournalEntryTest {

    private static final LedgerAccount BANK = LedgerAccount.create("BANK", "Bank", AccountType.ASSET, "VND");
    private static final LedgerAccount WALLET = LedgerAccount.create("W002", "Wallet", AccountType.LIABILITY, "VND");

    @Test
    void shouldBalanceAfterPosting() {
        // Arrange
        List<LedgerPosting> postings = balanced("250000.00");

        // Act
        JournalEntry entry = JournalEntry.createOriginal("tx-1", "Transfer posting", "event-1", postings);

        // Assert: bất biến Tổng Nợ = Tổng Có
        assertThat(total(entry, PostingSide.DEBIT)).isEqualByComparingTo(total(entry, PostingSide.CREDIT));
        assertThat(entry.getStatus()).isEqualTo(JournalEntryStatus.POSTED);
        assertThat(entry.getPostings()).allSatisfy(p ->
                assertThat(p.getJournalEntryId()).isEqualTo(entry.getId()));
    }

    @Test
    void shouldFailWhenUnbalanced() {
        // Act & Assert
        assertThatThrownBy(() -> JournalEntry.createOriginal("tx-2", "Unbalanced", "event-2",
                List.of(
                        new LedgerPosting(null, null, BANK.getId(), PostingSide.DEBIT, new BigDecimal("250000.00"), "VND"),
                        new LedgerPosting(null, null, WALLET.getId(), PostingSide.CREDIT, new BigDecimal("290000.00"), "VND"))))
                .isInstanceOf(LedgerUnbalancedException.class)
                .hasMessageContaining("Unbalanced journal entry");
    }

    @Test
    void shouldFailWithSingleSidePosting() {
        // Act & Assert: chỉ có 1 dòng bút toán
        assertThatThrownBy(() -> JournalEntry.createOriginal("tx-3", "Single side", "event-3",
                List.of(new LedgerPosting(null, null, BANK.getId(), PostingSide.DEBIT, new BigDecimal("100.00"), "VND"))))
                .isInstanceOf(LedgerUnbalancedException.class);
    }

    @Test
    void shouldRejectEmptyPostings() {
        // Act & Assert
        assertThatThrownBy(() -> JournalEntry.createOriginal("tx-4", "Empty", "event-4", List.of()))
                .isInstanceOf(LedgerUnbalancedException.class);
    }

    @Test
    void shouldRejectZeroAmount() {
        // Act & Assert
        assertThatThrownBy(() -> JournalEntry.createOriginal("tx-5", "Zero", "event-5", List.of(
                new LedgerPosting(null, null, BANK.getId(), PostingSide.DEBIT, BigDecimal.ZERO, "VND"),
                new LedgerPosting(null, null, WALLET.getId(), PostingSide.CREDIT, BigDecimal.ZERO, "VND"))))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("strictly positive");
    }

    @Test
    void reversalShouldBalancedAndSwapSides() {
        // Arrange
        JournalEntry original = JournalEntry.createOriginal("tx-6", "Deposit", "event-6", balanced("250000.00"));

        // Act: bút toán bù đảo chiều 1:1
        List<LedgerPosting> compensating = original.compensatePostings();
        JournalEntry reversal = JournalEntry.createReversal("tx-6", "Reversal", "event-reversal-6",
                original.getId(), compensating);

        // Assert: chứng từ bù cân Nợ/Có, tham chiếu chứng từ gốc, không sửa chứng từ gốc
        assertThat(total(reversal, PostingSide.DEBIT)).isEqualByComparingTo(total(reversal, PostingSide.CREDIT));
        assertThat(reversal.getStatus()).isEqualTo(JournalEntryStatus.REVERSAL);
        assertThat(reversal.getReversalOf()).isEqualTo(original.getId());
        assertThat(reversal.getPostings().get(0).getSide()).isEqualTo(original.getPostings().get(1).getSide());
        assertThat(reversal.getPostings().get(1).getSide()).isEqualTo(original.getPostings().get(0).getSide());
        // Số tiền của chứng từ gốc không bị thay đổi (append-only)
        assertThat(original.getPostings().get(0).getAmount()).isEqualByComparingTo("250000.00");
    }

    @Test
    void reversalMustReferenceOriginal() {
        // Act & Assert
        assertThatThrownBy(() -> JournalEntry.createReversal("tx-7", "Reversal", "event-7",
                null, List.of()))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("original entry");
    }

    private List<LedgerPosting> balanced(String amount) {
        return List.of(
                new LedgerPosting(null, null, BANK.getId(), PostingSide.DEBIT, new BigDecimal(amount), "VND"),
                new LedgerPosting(null, null, WALLET.getId(), PostingSide.CREDIT, new BigDecimal(amount), "VND"));
    }

    private BigDecimal total(JournalEntry entry, PostingSide side) {
        return entry.getPostings().stream()
                .filter(p -> p.getSide() == side)
                .map(LedgerPosting::getAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }
}
