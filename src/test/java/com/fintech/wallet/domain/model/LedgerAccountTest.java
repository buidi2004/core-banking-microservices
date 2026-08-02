package com.fintech.wallet.domain.model;

import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.*;

class LedgerAccountTest {

    @Test
    void constructor_shouldInitialize() {
        LedgerAccount acc = new LedgerAccount("acc-1", "SYSTEM_FUND", AccountType.ASSET, "VND", new BigDecimal("1000"));
        assertEquals("acc-1", acc.getId());
        assertEquals(AccountType.ASSET, acc.getAccountType());
        assertEquals("SYSTEM_FUND", acc.getAccountName());
        assertEquals(new BigDecimal("1000"), acc.getBalance());
    }

    @Test
    void updateBalance_shouldAddDelta() {
        LedgerAccount acc = new LedgerAccount("acc-1", "SYSTEM_FUND", AccountType.ASSET, "VND", new BigDecimal("1000"));
        acc.updateBalance(new BigDecimal("500"));
        assertEquals(new BigDecimal("1500"), acc.getBalance());
    }

    @Test
    void updateBalance_negativeDelta_shouldSubtract() {
        LedgerAccount acc = new LedgerAccount("acc-1", "SYSTEM_FUND", AccountType.ASSET, "VND", new BigDecimal("1000"));
        acc.updateBalance(new BigDecimal("-300"));
        assertEquals(new BigDecimal("700"), acc.getBalance());
    }
}
