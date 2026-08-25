package com.fintech.wallet.domain.model;

import com.fintech.wallet.domain.exception.InsufficientBalanceException;
import com.fintech.wallet.domain.exception.InvalidMoneyException;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.Instant;

import static org.junit.jupiter.api.Assertions.*;

class WalletTest {

    @Test
    void constructor_shouldInitialize() {
        Wallet wallet = new Wallet("w-1", "user-1", Money.of(new BigDecimal("1000"), "VND"), Instant.now(), Instant.now(), 0L);
        assertEquals("w-1", wallet.getId());
        assertEquals("user-1", wallet.getOwnerId());
        assertEquals(new BigDecimal("1000.00"), wallet.getBalance().getAmount());
    }

    @Test
    void deposit_validAmount_shouldIncreaseBalance() {
        Wallet wallet = new Wallet("w-1", "user-1", Money.zero("VND"), Instant.now(), Instant.now(), 0L);
        wallet.deposit(Money.of(new BigDecimal("500"), "VND"));
        assertEquals(new BigDecimal("500.00"), wallet.getBalance().getAmount());
    }

    @Test
    void deposit_nullAmount_shouldThrow() {
        Wallet wallet = new Wallet("w-1", "user-1", Money.zero("VND"), Instant.now(), Instant.now(), 0L);
        assertThrows(InvalidMoneyException.class, () -> wallet.deposit(null));
    }

    @Test
    void deposit_currencyMismatch_shouldThrow() {
        Wallet wallet = new Wallet("w-1", "user-1", Money.zero("VND"), Instant.now(), Instant.now(), 0L);
        assertThrows(InvalidMoneyException.class, () -> wallet.deposit(Money.of(new BigDecimal("500"), "USD")));
    }

    @Test
    void withdraw_sufficientBalance_shouldDecreaseBalance() {
        Wallet wallet = new Wallet("w-1", "user-1", Money.of(new BigDecimal("1000"), "VND"), Instant.now(), Instant.now(), 0L);
        wallet.withdraw(Money.of(new BigDecimal("300"), "VND"));
        assertEquals(new BigDecimal("700.00"), wallet.getBalance().getAmount());
    }

    @Test
    void withdraw_insufficientBalance_shouldThrow() {
        Wallet wallet = new Wallet("w-1", "user-1", Money.of(new BigDecimal("200"), "VND"), Instant.now(), Instant.now(), 0L);
        assertThrows(InsufficientBalanceException.class, () -> wallet.withdraw(Money.of(new BigDecimal("300"), "VND")));
    }

    @Test
    void withdraw_nullAmount_shouldThrow() {
        Wallet wallet = new Wallet("w-1", "user-1", Money.zero("VND"), Instant.now(), Instant.now(), 0L);
        assertThrows(InvalidMoneyException.class, () -> wallet.withdraw(null));
    }
}
