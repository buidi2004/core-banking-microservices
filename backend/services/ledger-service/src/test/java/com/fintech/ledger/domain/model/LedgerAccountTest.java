package com.fintech.ledger.domain.model;

import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class LedgerAccountTest {

    @Test
    void shouldCreateWalletAccountFromWalletId() {
        // Arrange
        String walletId = "a3f1c2d4-e5f6-4789-a1b2-c3d4e5f6a7b8";

        // Act
        String code = LedgerAccount.walletAccountCode(walletId);
        String name = LedgerAccount.walletAccountName(walletId);

        // Assert: mã tài khoản dạng W:<walletId>
        assertThat(code).hasSizeLessThanOrEqualTo(100).startsWith("W:").isEqualTo("W:" + walletId);
        assertThat(name).isEqualTo("CUSTOMER_DEPOSITS:" + walletId);
    }

    @Test
    void bankSettlementShouldBeAssetAccount() {
        // Act
        LedgerAccount bank = LedgerAccount.bankSettlement("VND");

        // Assert
        assertThat(bank.getCode()).isEqualTo("BANK_SETTLEMENT");
        assertThat(bank.getType()).isEqualTo(AccountType.ASSET);
        assertThat(bank.getBalance()).isEqualByComparingTo(BigDecimal.ZERO);
        assertThat(bank.getType().isDebitNormal()).isTrue();
    }

    @Test
    void customerDepositIsLiability() {
        // Assert: tiền khách gửi là nợ phải của hệ thống → Credit(+), Debit(-)
        LedgerAccount deposits = LedgerAccount.create("W003", "Deposits", AccountType.LIABILITY, "VND");
        assertThat(deposits.getType().isDebitNormal()).isFalse();
    }

    @Test
    void codeMustBeShortEnough() {
        // Act & Assert
        assertThatThrownBy(() -> LedgerAccount.create(
                "CODE_" + "X".repeat(105), "Too long", AccountType.EQUITY, "VND"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("100 characters");
    }
}
