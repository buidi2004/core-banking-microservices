package com.fintech.wallet.domain.model;

import com.fintech.wallet.domain.exception.InvalidMoneyException;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.*;

class MoneyTest {

    @Test
    void constructor_validAmountAndCurrency_shouldCreate() {
        Money money = Money.of(new BigDecimal("100.00"), "VND");
        assertEquals(new BigDecimal("100.00"), money.getAmount());
        assertEquals("VND", money.getCurrency());
    }

    @Test
    void constructor_negativeAmount_shouldThrow() {
        assertThrows(InvalidMoneyException.class, () -> Money.of(new BigDecimal("-100.00"), "VND"));
    }

    @Test
    void constructor_nullAmount_shouldThrow() {
        assertThrows(InvalidMoneyException.class, () -> Money.of((BigDecimal) null, "VND"));
    }

    @Test
    void constructor_invalidCurrency_shouldThrow() {
        assertThrows(InvalidMoneyException.class, () -> Money.of(new BigDecimal("100.00"), null));
        assertThrows(InvalidMoneyException.class, () -> Money.of(new BigDecimal("100.00"), ""));
    }

    @Test
    void add_sameCurrency_shouldReturnSum() {
        Money m1 = Money.of(new BigDecimal("100.00"), "VND");
        Money m2 = Money.of(new BigDecimal("50.00"), "VND");
        Money result = m1.add(m2);
        assertEquals(new BigDecimal("150.00"), result.getAmount());
    }

    @Test
    void add_differentCurrency_shouldThrow() {
        Money m1 = Money.of(new BigDecimal("100.00"), "VND");
        Money m2 = Money.of(new BigDecimal("50.00"), "USD");
        assertThrows(InvalidMoneyException.class, () -> m1.add(m2));
    }

    @Test
    void subtract_sufficientBalance_shouldReturnDifference() {
        Money m1 = Money.of(new BigDecimal("100.00"), "VND");
        Money m2 = Money.of(new BigDecimal("50.00"), "VND");
        Money result = m1.subtract(m2);
        assertEquals(new BigDecimal("50.00"), result.getAmount());
    }

    @Test
    void subtract_insufficientBalance_shouldThrow() {
        Money m1 = Money.of(new BigDecimal("50.00"), "VND");
        Money m2 = Money.of(new BigDecimal("100.00"), "VND");
        assertThrows(InvalidMoneyException.class, () -> m1.subtract(m2));
    }

    @Test
    void isGreaterThanOrEqual_shouldCompareCorrectly() {
        Money m1 = Money.of(new BigDecimal("100.00"), "VND");
        Money m2 = Money.of(new BigDecimal("50.00"), "VND");
        assertTrue(m1.isGreaterThanOrEqual(m2));
        assertTrue(m1.isGreaterThanOrEqual(m1));
        assertFalse(m2.isGreaterThanOrEqual(m1));
    }

    @Test
    void isLessThan_shouldCompareCorrectly() {
        Money m1 = Money.of(new BigDecimal("50.00"), "VND");
        Money m2 = Money.of(new BigDecimal("100.00"), "VND");
        assertTrue(m1.isLessThan(m2));
        assertFalse(m2.isLessThan(m1));
    }

    @Test
    void zero_shouldReturnZeroMoney() {
        Money money = Money.zero("VND");
        assertEquals(new BigDecimal("0.00"), money.getAmount());
        assertEquals("VND", money.getCurrency());
    }
}
