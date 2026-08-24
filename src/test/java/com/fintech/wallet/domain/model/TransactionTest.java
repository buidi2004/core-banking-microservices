package com.fintech.wallet.domain.model;

import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.Instant;

import static org.junit.jupiter.api.Assertions.*;

class TransactionTest {

    @Test
    void createDeposit_shouldSetCorrectTypeAndStatus() {
        Transaction tx = Transaction.createDeposit("tx-1", "w-1", Money.of(new BigDecimal("500"), "VND"));
        assertEquals(TransactionType.DEPOSIT, tx.getType());
        assertEquals(TransactionStatus.PENDING, tx.getStatus());
        assertEquals("w-1", tx.getTargetWalletId());
        assertNull(tx.getSourceWalletId());
    }

    @Test
    void createTransfer_shouldSetCorrectFields() {
        Transaction tx = Transaction.createTransfer("tx-2", "w-1", "w-2", Money.of(new BigDecimal("500"), "VND"));
        assertEquals(TransactionType.TRANSFER, tx.getType());
        assertEquals(TransactionStatus.PENDING_CONFIRMATION, tx.getStatus());
        assertEquals("w-1", tx.getSourceWalletId());
        assertEquals("w-2", tx.getTargetWalletId());
    }

    @Test
    void createWithdrawal_shouldSetCorrectFields() {
        Transaction tx = Transaction.createWithdrawal("tx-3", "w-1", Money.of(new BigDecimal("500"), "VND"));
        assertEquals(TransactionType.WITHDRAWAL, tx.getType());
        assertEquals(TransactionStatus.PENDING, tx.getStatus());
        assertEquals("w-1", tx.getSourceWalletId());
        assertNull(tx.getTargetWalletId());
    }

    @Test
    void markSuccess_shouldChangeStatus() {
        Transaction tx = Transaction.createDeposit("tx-1", "w-1", Money.of(new BigDecimal("500"), "VND"));
        tx.markSuccess();
        assertEquals(TransactionStatus.SUCCESS, tx.getStatus());
    }

    @Test
    void markFailed_shouldChangeStatus() {
        Transaction tx = Transaction.createDeposit("tx-1", "w-1", Money.of(new BigDecimal("500"), "VND"));
        tx.markFailed();
        assertEquals(TransactionStatus.FAILED, tx.getStatus());
    }
}
