package com.fintech.wallet.domain.model;

import com.fintech.wallet.domain.exception.InvalidMoneyException;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.Objects;
import java.util.regex.Pattern;

/**
 * Value Object: Money
 * Pure Java - No Spring / JPA annotations.
 */
public class Money {
    private static final Pattern CURRENCY_PATTERN = Pattern.compile("^[A-Za-z]{3}$");

    private final BigDecimal amount;
    private final String currency;

    public Money(BigDecimal amount, String currency) {
        if (amount == null || amount.compareTo(BigDecimal.ZERO) < 0) {
            throw new InvalidMoneyException("Money amount cannot be null or negative");
        }
        if (currency == null || currency.isBlank()) {
            throw new InvalidMoneyException("Currency cannot be null or empty");
        }
        if (!CURRENCY_PATTERN.matcher(currency).matches()) {
            throw new InvalidMoneyException("Currency must be a valid 3-letter ISO 4217 code, got: " + currency);
        }
        this.amount = amount.setScale(2, RoundingMode.HALF_UP);
        this.currency = currency.toUpperCase();
    }

    public static Money zero(String currency) {
        return new Money(BigDecimal.ZERO, currency);
    }

    public static Money of(BigDecimal amount, String currency) {
        return new Money(amount, currency);
    }

    /**
     * @deprecated Use {@link #of(BigDecimal, String)} or {@link #of(String, String)} instead.
     *             Double precision can cause rounding errors in financial calculations.
     */
    @Deprecated
    public static Money of(double amount, String currency) {
        return new Money(BigDecimal.valueOf(amount), currency);
    }

    public static Money of(String amount, String currency) {
        return new Money(new BigDecimal(amount), currency);
    }

    public BigDecimal getAmount() {
        return amount;
    }

    public String getCurrency() {
        return currency;
    }

    public Money add(Money money) {
        validateSameCurrency(money);
        return new Money(this.amount.add(money.getAmount()), this.currency);
    }

    public Money subtract(Money money) {
        validateSameCurrency(money);
        if (isLessThan(money)) {
            throw new InvalidMoneyException("Resulting money amount would be negative");
        }
        return new Money(this.amount.subtract(money.getAmount()), this.currency);
    }

    public boolean isGreaterThanOrEqual(Money money) {
        validateSameCurrency(money);
        return this.amount.compareTo(money.getAmount()) >= 0;
    }

    public boolean isLessThan(Money money) {
        validateSameCurrency(money);
        return this.amount.compareTo(money.getAmount()) < 0;
    }

    private void validateSameCurrency(Money money) {
        if (money == null || !this.currency.equalsIgnoreCase(money.getCurrency())) {
            throw new InvalidMoneyException("Currency mismatch: " + this.currency + " vs " + (money != null ? money.getCurrency() : "null"));
        }
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Money money = (Money) o;
        return Objects.equals(amount, money.amount) && Objects.equals(currency, money.currency);
    }

    @Override
    public int hashCode() {
        return Objects.hash(amount, currency);
    }

    @Override
    public String toString() {
        return amount + " " + currency;
    }
}
