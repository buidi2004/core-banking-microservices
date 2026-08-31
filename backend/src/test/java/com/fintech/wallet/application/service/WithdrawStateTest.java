package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.model.Money;
import com.fintech.wallet.domain.model.Transaction;
import com.fintech.wallet.domain.model.TransactionStatus;
import com.fintech.wallet.domain.model.Wallet;
import com.fintech.wallet.domain.port.out.BankGatewayPort;
import com.fintech.wallet.domain.port.out.DistributedLockPort;
import com.fintech.wallet.domain.port.out.NotificationPort;
import com.fintech.wallet.domain.port.out.TransactionPersistencePort;
import com.fintech.wallet.domain.port.out.TransactionalOperationPort;
import com.fintech.wallet.domain.port.out.WalletPersistencePort;
import com.fintech.wallet.domain.port.in.LedgerUseCase;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.math.BigDecimal;
import java.util.Optional;
import com.fintech.wallet.domain.port.out.UserPersistencePort;
import com.fintech.wallet.domain.model.User;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

class WithdrawStateTest {

    private WalletPersistencePort walletPersistencePort;
    private TransactionPersistencePort transactionPersistencePort;
    private BankGatewayPort bankGatewayPort;
    private TransactionalOperationPort transactionalOperationPort;
    private UserPersistencePort userPersistencePort;
    private WalletService walletService;

    @BeforeEach
    void setUp() {
        walletPersistencePort = mock(WalletPersistencePort.class);
        transactionPersistencePort = mock(TransactionPersistencePort.class);
        bankGatewayPort = mock(BankGatewayPort.class);
        DistributedLockPort lockPort = mock(DistributedLockPort.class);
        NotificationPort notificationPort = mock(NotificationPort.class);
        LedgerUseCase ledgerUseCase = mock(LedgerUseCase.class);
        userPersistencePort = mock(UserPersistencePort.class);
        
        User mockUser = new User("user-1", "user", "hash", null, com.fintech.wallet.domain.model.KycStatus.VERIFIED, java.time.Instant.now(), java.time.Instant.now());
        when(userPersistencePort.findUserById(anyString())).thenReturn(Optional.of(mockUser));
        when(transactionPersistencePort.calculateDailySpentByWalletId(anyString(), any())).thenReturn(java.math.BigDecimal.ZERO);
        when(transactionPersistencePort.calculateMonthlySpentByWalletId(anyString(), any())).thenReturn(java.math.BigDecimal.ZERO);
        

        
        when(lockPort.executeWithLock(anyString(), org.mockito.ArgumentMatchers.anyLong(), any())).thenAnswer(invocation -> {
            java.util.function.Supplier<?> supplier = invocation.getArgument(2);
            return supplier.get();
        });

        transactionalOperationPort = new TransactionalOperationPort() {
            @Override
            public <T> T executeInTransaction(java.util.function.Supplier<T> operation) {
                return operation.get();
            }
        };

        walletService = new WalletService(
                walletPersistencePort,
                transactionPersistencePort,
                lockPort,
                notificationPort,
                transactionalOperationPort,
                bankGatewayPort,
                userPersistencePort,
                mock(com.fintech.wallet.domain.port.out.AuditLogPersistencePort.class),
                mock(com.fintech.wallet.domain.port.out.ClientInfoPort.class),
                ledgerUseCase,
                null
        );
    }

    @Test
    void withdraw_gatewaySuccess_shouldMarkSuccess() {
        Wallet wallet = Wallet.createNew("user-1", "VND");
        wallet.deposit(Money.of(new BigDecimal("100000"), "VND"));
        
        when(walletPersistencePort.findWalletById(anyString())).thenReturn(Optional.of(wallet));
        when(transactionPersistencePort.saveTransaction(any(Transaction.class))).thenAnswer(i -> i.getArgument(0));
        when(transactionPersistencePort.findTransactionById(anyString())).thenAnswer(i -> {
            Transaction tx = Transaction.createWithdrawal("req-1", wallet.getId(), Money.of(new BigDecimal("50000"), "VND"));
            tx.markProcessing();
            return Optional.of(tx);
        });
        
        when(bankGatewayPort.transferToBank(anyString(), any(Money.class), anyString())).thenReturn(true);

        Transaction result = walletService.withdraw("req-1", "user-1", wallet.getId(), "bank-1", Money.of(new BigDecimal("50000"), "VND"));

        assertEquals(TransactionStatus.SUCCESS, result.getStatus());
        assertEquals(new BigDecimal("50000.00"), wallet.getBalance().getAmount());
    }

    @Test
    void withdraw_gatewayFailure_shouldAutoReverse() {
        Wallet wallet = Wallet.createNew("user-1", "VND");
        wallet.deposit(Money.of(new BigDecimal("100000"), "VND"));
        
        when(walletPersistencePort.findWalletById(anyString())).thenReturn(Optional.of(wallet));
        when(transactionPersistencePort.saveTransaction(any(Transaction.class))).thenAnswer(i -> i.getArgument(0));
        when(transactionPersistencePort.findTransactionById(anyString())).thenAnswer(i -> {
            Transaction tx = Transaction.createWithdrawal("req-2", wallet.getId(), Money.of(new BigDecimal("50000"), "VND"));
            tx.markProcessing();
            return Optional.of(tx);
        });
        
        when(bankGatewayPort.transferToBank(anyString(), any(Money.class), anyString())).thenThrow(new RuntimeException("Gateway Timeout"));

        Transaction result = walletService.withdraw("req-2", "user-1", wallet.getId(), "bank-1", Money.of(new BigDecimal("50000"), "VND"));

        // Since it's mocked without resilience4j actually retrying in unit test (unless we use Spring Boot Test),
        // it will just fail once and trigger reversal.
        assertEquals(TransactionStatus.REVERSED, result.getStatus());
        
        // Balance should be restored to 100000
        assertEquals(new BigDecimal("100000.00"), wallet.getBalance().getAmount());
        
        ArgumentCaptor<Transaction> txCaptor = ArgumentCaptor.forClass(Transaction.class);
        verify(transactionPersistencePort, atLeastOnce()).saveTransaction(txCaptor.capture());
        
        boolean hasReversal = txCaptor.getAllValues().stream()
                .anyMatch(tx -> tx.getStatus() == TransactionStatus.PENDING_REVERSAL || tx.getStatus() == TransactionStatus.REVERSED);
        assertTrue(hasReversal, "Should save transaction with REVERSED status");
    }
}
