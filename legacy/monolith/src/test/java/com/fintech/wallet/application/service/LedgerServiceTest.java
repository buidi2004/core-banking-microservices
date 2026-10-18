package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.model.AccountType;
import com.fintech.wallet.domain.model.EntryType;
import com.fintech.wallet.domain.model.LedgerAccount;
import com.fintech.wallet.domain.model.LedgerPosting;
import com.fintech.wallet.domain.port.out.LedgerPersistencePort;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class LedgerServiceTest {

    @Mock
    private LedgerPersistencePort ledgerPersistencePort;

    @InjectMocks
    private LedgerService ledgerService;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void createAccount_shouldSaveAndReturn() {
        LedgerAccount acc = new LedgerAccount("a1", "SYSTEM", AccountType.ASSET, "VND", new BigDecimal("0"));
        when(ledgerPersistencePort.saveAccount(any())).thenReturn(acc);

        LedgerAccount result = ledgerService.createAccount("SYSTEM", AccountType.ASSET, "VND");
        
        assertNotNull(result);
        assertEquals("SYSTEM", result.getAccountName());
    }

    @Test
    void recordJournalEntry_shouldUpdateAccounts() {
        LedgerAccount assetAcc = new LedgerAccount("a1", "ASSET", AccountType.ASSET, "VND", new BigDecimal("100"));
        LedgerAccount liabAcc = new LedgerAccount("l1", "LIABILITY", AccountType.LIABILITY, "VND", new BigDecimal("100"));
        
        when(ledgerPersistencePort.findAccountById("a1")).thenReturn(Optional.of(assetAcc));
        when(ledgerPersistencePort.findAccountById("l1")).thenReturn(Optional.of(liabAcc));

        ledgerService.recordJournalEntry("tx1", "tx1", null, List.of(
            new LedgerPosting(null, null, "a1", EntryType.DEBIT, new BigDecimal("50")),
            new LedgerPosting(null, null, "l1", EntryType.CREDIT, new BigDecimal("50"))
        ));

        assertEquals(new BigDecimal("150"), assetAcc.getBalance());
        assertEquals(new BigDecimal("150"), liabAcc.getBalance());
        
        verify(ledgerPersistencePort, times(2)).saveAccount(any());
        verify(ledgerPersistencePort).saveJournalEntry(any());
    }

    @Test
    void recordJournalEntry_accountNotFound_shouldThrow() {
        when(ledgerPersistencePort.findAccountById("a1")).thenReturn(Optional.empty());
        assertThrows(IllegalArgumentException.class, () -> ledgerService.recordJournalEntry("tx1", "tx1", null, List.of(
            new LedgerPosting(null, null, "a1", EntryType.DEBIT, new BigDecimal("50")),
            new LedgerPosting(null, null, "l1", EntryType.CREDIT, new BigDecimal("50"))
        )));
    }
}
