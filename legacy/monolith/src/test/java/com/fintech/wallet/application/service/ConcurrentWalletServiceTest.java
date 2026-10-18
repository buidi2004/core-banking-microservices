package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.model.Money;
import com.fintech.wallet.domain.model.Wallet;
import com.fintech.wallet.domain.model.Transaction;
import com.fintech.wallet.domain.port.in.LedgerUseCase;
import com.fintech.wallet.domain.port.out.AuditLogPersistencePort;
import com.fintech.wallet.domain.port.out.DistributedLockPort;
import com.fintech.wallet.domain.port.out.TransactionPersistencePort;
import com.fintech.wallet.domain.port.out.TransactionalOperationPort;
import com.fintech.wallet.domain.port.out.UserPersistencePort;
import com.fintech.wallet.domain.port.out.WalletPersistencePort;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Optional;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.atomic.AtomicReference;
import java.util.concurrent.locks.ReentrantLock;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

class ConcurrentWalletServiceTest {

    private WalletService walletService;
    private WalletPersistencePort walletPersistencePort;
    private TransactionPersistencePort transactionPersistencePort;

    @BeforeEach
    void setUp() {
        walletPersistencePort = mock(WalletPersistencePort.class);
        transactionPersistencePort = mock(TransactionPersistencePort.class);
        DistributedLockPort distributedLockPort = mock(DistributedLockPort.class);
        TransactionalOperationPort transactionalOperationPort = mock(TransactionalOperationPort.class);
        UserPersistencePort userPersistencePort = mock(UserPersistencePort.class);
        AuditLogPersistencePort auditLogPersistencePort = mock(AuditLogPersistencePort.class);
        LedgerUseCase ledgerUseCase = mock(LedgerUseCase.class);

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
    void testConcurrentWithdrawals_ShouldNotResultInNegativeBalance() throws Exception {
        Wallet sharedWallet = new Wallet("w1", "u1", Money.of(new BigDecimal("100"), "VND"), Instant.now(), Instant.now(), 0L);
        ReentrantLock lock = new ReentrantLock();

        when(walletPersistencePort.findWalletById("w1")).thenAnswer(inv -> {
            lock.lock();
            try {
                return Optional.of(new Wallet(sharedWallet.getId(), sharedWallet.getOwnerId(), sharedWallet.getBalance(), sharedWallet.getCreatedAt(), sharedWallet.getUpdatedAt(), sharedWallet.getVersion()));
            } finally {
                lock.unlock();
            }
        });

        doAnswer(inv -> {
            lock.lock();
            try {
                Wallet w = inv.getArgument(0);
                sharedWallet.withdraw(sharedWallet.getBalance()); // empty first
                sharedWallet.deposit(w.getBalance()); // set new balance
            } finally {
                lock.unlock();
            }
            return sharedWallet;
        }).when(walletPersistencePort).saveWallet(any());

        when(transactionPersistencePort.saveTransaction(any())).thenAnswer(inv -> inv.getArgument(0));
        when(transactionPersistencePort.calculateDailySpentByWalletId(any(), any())).thenReturn(BigDecimal.ZERO);
        when(transactionPersistencePort.calculateMonthlySpentByWalletId(any(), any())).thenReturn(BigDecimal.ZERO);
        when(transactionPersistencePort.findTransactionByRequestId(any())).thenReturn(Optional.empty());

        ExecutorService executor = Executors.newFixedThreadPool(2);
        CountDownLatch latch = new CountDownLatch(1);

        CompletableFuture<Void> tx1 = CompletableFuture.runAsync(() -> {
            try { latch.await(); walletService.withdraw("req1", "u1", "w1", "bank", Money.of(new BigDecimal("100"), "VND")); } catch (Exception e) {}
        }, executor);

        CompletableFuture<Void> tx2 = CompletableFuture.runAsync(() -> {
            try { latch.await(); walletService.withdraw("req2", "u1", "w1", "bank", Money.of(new BigDecimal("100"), "VND")); } catch (Exception e) {}
        }, executor);

        latch.countDown();
        CompletableFuture.allOf(tx1, tx2).join();

        assertEquals(0, new BigDecimal("0").compareTo(sharedWallet.getBalance().getAmount()));
    }
}
