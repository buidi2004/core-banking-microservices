package com.fintech.wallet.domain.model;

import com.fintech.wallet.domain.exception.LedgerUnbalancedException;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

class JournalEntryTest {

    @Test
    void create_shouldSucceedWhenDebitEqualsCredit() {
        LedgerPosting debit = new LedgerPosting("p1", "je1", "acc_asset", EntryType.DEBIT, new BigDecimal("50000.00"));
        LedgerPosting credit = new LedgerPosting("p2", "je1", "acc_liability", EntryType.CREDIT, new BigDecimal("50000.00"));

        JournalEntry entry = JournalEntry.create("tx_100", "Deposit posting", null, List.of(debit, credit));

        assertNotNull(entry);
        assertEquals("tx_100", entry.getTransactionId());
        assertEquals(2, entry.getPostings().size());
        
        // Verify that the postings were linked with the correct JournalEntry ID
        assertEquals(entry.getId(), entry.getPostings().get(0).getJournalEntryId());
        assertEquals(entry.getId(), entry.getPostings().get(1).getJournalEntryId());
    }

    @Test
    void create_shouldThrowLedgerUnbalancedExceptionWhenDebitNotEqualsCredit() {
        LedgerPosting debit = new LedgerPosting("p1", "je1", "acc_asset", EntryType.DEBIT, new BigDecimal("50000.00"));
        LedgerPosting credit = new LedgerPosting("p2", "je1", "acc_liability", EntryType.CREDIT, new BigDecimal("49000.00"));

        assertThrows(LedgerUnbalancedException.class, () ->
            JournalEntry.create("tx_100", "Unbalanced posting", null, List.of(debit, credit))
        );
    }
}
