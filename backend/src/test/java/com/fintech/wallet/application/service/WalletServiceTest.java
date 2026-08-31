package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.exception.TransactionLimitExceededException;
import com.fintech.wallet.domain.exception.InsufficientBalanceException;
import com.fintech.wallet.domain.model.KycStatus;
import com.fintech.wallet.domain.model.Money;
import com.fintech.wallet.domain.model.User;
import com.fintech.wallet.domain.model.Wallet;
import com.fintech.wallet.domain.port.out.AuditLogPersistencePort;
import com.fintech.wallet.domain.port.out.DistributedLockPort;
import com.fintech.wallet.domain.port.out.TransactionPersistencePort;
import com.fintech.wallet.domain.port.out.TransactionalOperationPort;
import com.fintech.wallet.domain.port.out.UserPersistencePort;
import com.fintech.wallet.domain.port.out.WalletPersistencePort;
import com.fintech.wallet.domain.port.in.LedgerUseCase;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;
import static org.mockito.Mockito.verify;

class WalletServiceTest {

    private WalletPersistencePort walletPersistencePort;
    private TransactionPersistencePort transactionPersistencePort;
    private DistributedLockPort distributedLockPort;
    private TransactionalOperationPort transactionalOperationPort;
    private UserPersistencePort userPersistencePort;
    private AuditLogPersistencePort auditLogPersistencePort;

    private LedgerUseCase ledgerUseCase;
    private WalletService walletService;

    @BeforeEach
    void setUp() {
        walletPersistencePort = mock(WalletPersistencePort.class);
        transactionPersistencePort = mock(TransactionPersistencePort.class);
        distributedLockPort = mock(DistributedLockPort.class);
        transactionalOperationPort = mock(TransactionalOperationPort.class);
        userPersistencePort = mock(UserPersistencePort.class);
        auditLogPersistencePort = mock(AuditLogPersistencePort.class);
        ledgerUseCase = mock(LedgerUseCase.class);

        walletService = new WalletService(
                walletPersistencePort,
                transactionPersistencePort,
                distributedLockPort,
                null,
                transactionalOperationPort,
                null,
                userPersistencePort, auditLogPersistencePort, mock(com.fintech.wallet.domain.port.out.ClientInfoPort.class), ledgerUseCase, null);

        when(distributedLockPort.executeWithLock(anyString(), org.mockito.ArgumentMatchers.anyLong(), any())).thenAnswer(invocation -> {
            java.util.function.Supplier<Object> supplier = invocation.getArgument(2);
            return supplier.get();
        });

        when(transactionalOperationPort.executeInTransaction(any())).thenAnswer(invocation -> {
            java.util.function.Supplier<Object> supplier = invocation.getArgument(0);
            return supplier.get();
        });
    }

    @Test
    void testTransferExceedsUnverifiedLimit_throwsException() {
        String userId = "user-123";
        User user = new User(userId, "0987654321", "hash", "123456", KycStatus.UNVERIFIED, Instant.now(), Instant.now());
        when(userPersistencePort.findUserById(userId)).thenReturn(Optional.of(user));

        Wallet sourceWallet = new Wallet("wallet-1", userId, Money.of(new BigDecimal("10000000"), "VND"), Instant.now(), Instant.now(), 0L);
        Wallet targetWallet = new Wallet("wallet-2", "user-456", Money.of(new BigDecimal("1000000"), "VND"), Instant.now(), Instant.now(), 0L);

        when(walletPersistencePort.findWalletById("wallet-1")).thenReturn(Optional.of(sourceWallet));
        when(walletPersistencePort.findWalletById("wallet-1")).thenReturn(Optional.of(sourceWallet));
        when(walletPersistencePort.findWalletById("wallet-2")).thenReturn(Optional.of(targetWallet));
        when(walletPersistencePort.findWalletById("wallet-2")).thenReturn(Optional.of(targetWallet));

        when(transactionPersistencePort.calculateDailySpentByWalletId(eq("wallet-1"), any())).thenReturn(new BigDecimal("4000000"));

        assertThrows(TransactionLimitExceededException.class, () -> {
            walletService.transfer("req-1", "wallet-1", "wallet-2", Money.of(new BigDecimal("2000000"), "VND"));
        });
    }

    @Test
    void getWalletById_shouldReturnWallet() {
        Wallet wallet = new Wallet("w1", "u1", Money.zero("VND"), Instant.now(), Instant.now(), 0L);
        when(walletPersistencePort.findWalletById("w1")).thenReturn(Optional.of(wallet));
        when(walletPersistencePort.findWalletById("w1")).thenReturn(Optional.of(wallet));
        Wallet result = walletService.getWalletById("w1");
        assertEquals("w1", result.getId());
    }

    @Test
    void createWallet_shouldCreateNewWallet() {
        when(walletPersistencePort.findWalletByOwnerId("u1")).thenReturn(Optional.empty());
        Wallet wallet = new Wallet("w1", "u1", Money.zero("VND"), Instant.now(), Instant.now(), 0L);
        when(walletPersistencePort.saveWallet(any())).thenReturn(wallet);

        Wallet result = walletService.createWallet("u1", "VND");
        assertEquals("w1", result.getId());
        verify(walletPersistencePort).saveWallet(any());
    }

    @Test
    void createWallet_duplicateOwner_shouldThrow() {
        Wallet wallet = new Wallet("w1", "u1", Money.zero("VND"), Instant.now(), Instant.now(), 0L);
        when(walletPersistencePort.findWalletByOwnerId("u1")).thenReturn(Optional.of(wallet));
        assertThrows(IllegalArgumentException.class, () -> walletService.createWallet("u1", "VND"));
    }

    @Test
    void withdraw_success_shouldReturnTransaction() {
        Wallet wallet = new Wallet("w1", "u1", Money.of(new BigDecimal("1000"), "VND"), Instant.now(), Instant.now(), 0L);
        when(walletPersistencePort.findWalletById("w1")).thenReturn(Optional.of(wallet));
        when(walletPersistencePort.findWalletById("w1")).thenReturn(Optional.of(wallet));
        
        com.fintech.wallet.domain.model.Transaction tx = com.fintech.wallet.domain.model.Transaction.createWithdrawal("req1", "w1", Money.of(new BigDecimal("100"), "VND"));
        when(transactionPersistencePort.saveTransaction(any())).thenReturn(tx);
        when(transactionPersistencePort.calculateDailySpentByWalletId(any(), any())).thenReturn(BigDecimal.ZERO);
        when(transactionPersistencePort.calculateMonthlySpentByWalletId(any(), any())).thenReturn(BigDecimal.ZERO);

        com.fintech.wallet.domain.model.Transaction result = walletService.withdraw("req1", "u1", "w1", "bank1", Money.of(new BigDecimal("100"), "VND"));
        assertNotNull(result.getId());
        assertEquals("req1", result.getRequestId());
    }
    @Test
    void testTransfer_InsufficientFunds_ShouldThrow() {
        Wallet sourceWallet = new Wallet("w1", "u1", Money.of(new BigDecimal("5000"), "VND"), Instant.now(), Instant.now(), 0L);
        Wallet targetWallet = new Wallet("w2", "u2", Money.of(new BigDecimal("1000"), "VND"), Instant.now(), Instant.now(), 0L);
        when(walletPersistencePort.findWalletById("w1")).thenReturn(Optional.of(sourceWallet));
        when(walletPersistencePort.findWalletById("w2")).thenReturn(Optional.of(targetWallet));
        when(transactionPersistencePort.calculateDailySpentByWalletId(any(), any())).thenReturn(BigDecimal.ZERO);

        assertThrows(InsufficientBalanceException.class, () -> {
            walletService.transfer("req2", "w1", "w2", Money.of(new BigDecimal("6000"), "VND"));
        });
    }

    @Test
    void testTransfer_SameWallet_ShouldThrow() {
        Wallet wallet = new Wallet("w1", "u1", Money.of(new BigDecimal("1000"), "VND"), Instant.now(), Instant.now(), 0L);
        when(walletPersistencePort.findWalletById("w1")).thenReturn(Optional.of(wallet));

        assertThrows(IllegalArgumentException.class, () -> {
            walletService.transfer("req3", "w1", "w1", Money.of(new BigDecimal("1000"), "VND"));
        });
    }

    @Test
    void testTransfer_NegativeAmount_ShouldThrow() {
        Wallet sourceWallet = new Wallet("w1", "u1", Money.of(new BigDecimal("1000"), "VND"), Instant.now(), Instant.now(), 0L);
        Wallet targetWallet = new Wallet("w2", "u2", Money.of(new BigDecimal("1000"), "VND"), Instant.now(), Instant.now(), 0L);
        when(walletPersistencePort.findWalletById("w1")).thenReturn(Optional.of(sourceWallet));
        when(walletPersistencePort.findWalletById("w2")).thenReturn(Optional.of(targetWallet));

        assertThrows(com.fintech.wallet.domain.exception.InvalidMoneyException.class, () -> {
            walletService.transfer("req4", "w1", "w2", Money.of(new BigDecimal("-100"), "VND"));
        });
    }
}
