package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.exception.TransactionLimitExceededException;
import com.fintech.wallet.domain.model.KycStatus;
import com.fintech.wallet.domain.model.Money;
import com.fintech.wallet.domain.model.User;
import com.fintech.wallet.domain.model.Wallet;
import com.fintech.wallet.domain.port.in.LedgerUseCase;
import com.fintech.wallet.domain.port.out.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;
import java.util.function.Supplier;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class TransactionLimitTest {

    @Mock
    private WalletPersistencePort walletPersistencePort;
    @Mock
    private TransactionPersistencePort transactionPersistencePort;
    @Mock
    private DistributedLockPort distributedLockPort;
    @Mock
    private NotificationPort notificationPort;
    @Mock
    private TransactionalOperationPort transactionalOperationPort;
    @Mock
    private BankGatewayPort bankGatewayPort;
    @Mock
    private UserPersistencePort userPersistencePort;
    @Mock
    private AuditLogPersistencePort auditLogPersistencePort;
    @Mock
    private ClientInfoPort clientInfoPort;
    @Mock
    private LedgerUseCase ledgerUseCase;

    private WalletService walletService;

    private User verifiedUser;
    private User unverifiedUser;
    private Wallet sourceWallet;
    private Wallet targetWallet;

    @BeforeEach
    void setUp() {
        walletService = new WalletService(
                walletPersistencePort,
                transactionPersistencePort,
                distributedLockPort,
                notificationPort,
                transactionalOperationPort,
                bankGatewayPort,
                userPersistencePort,
                auditLogPersistencePort,
                clientInfoPort,
                ledgerUseCase,
                null
        );

        verifiedUser = new User("user-verified", "0900000001", "Test Name", "hash", "123456", KycStatus.VERIFIED, Instant.now(), Instant.now());
        unverifiedUser = new User("user-unverified", "0900000002", "Test Name", "hash", "123456", KycStatus.UNVERIFIED, Instant.now(), Instant.now());

        sourceWallet = new Wallet("wallet-1", "user-verified", Money.of(new BigDecimal("200000000"), "VND"), Instant.now(), Instant.now(), 0L);
        targetWallet = new Wallet("wallet-2", "user-receiver", Money.of(new BigDecimal("10000000"), "VND"), Instant.now(), Instant.now(), 0L);

        lenient().when(distributedLockPort.executeWithLock(anyString(), anyLong(), any())).thenAnswer(inv -> {
            Supplier<?> supplier = inv.getArgument(2);
            return supplier.get();
        });

        lenient().when(transactionalOperationPort.executeInTransaction(any())).thenAnswer(inv -> {
            Supplier<?> supplier = inv.getArgument(0);
            return supplier.get();
        });

        lenient().when(walletPersistencePort.findWalletById("wallet-1")).thenReturn(Optional.of(sourceWallet));
        lenient().when(walletPersistencePort.findWalletById("wallet-2")).thenReturn(Optional.of(targetWallet));
    }

    @Test
    void testTransfer_WithinDailyLimit_Success() {
        when(userPersistencePort.findUserById("user-verified")).thenReturn(Optional.of(verifiedUser));
        when(transactionPersistencePort.calculateDailySpentByWalletId(eq("wallet-1"), any())).thenReturn(new BigDecimal("10000000")); // Spent 10M today
        when(transactionPersistencePort.calculateMonthlySpentByWalletId(eq("wallet-1"), any())).thenReturn(new BigDecimal("50000000")); // Spent 50M this month
        when(transactionPersistencePort.saveTransaction(any())).thenAnswer(inv -> inv.getArgument(0));

        // Transfer 20M VND (Total today: 30M <= 100M limit)
        var tx = walletService.transfer(UUID.randomUUID().toString(), "wallet-1", "wallet-2", "SENHONG", Money.of(new BigDecimal("20000000"), "VND"), null);

        assertNotNull(tx);
        verify(walletPersistencePort, times(1)).saveWallet(sourceWallet);
        verify(walletPersistencePort, times(1)).saveWallet(targetWallet);
    }

    @Test
    void testTransfer_ExceedDailyLimit_ThrowsExceptionAndDoesNotMutateBalance() {
        when(userPersistencePort.findUserById("user-verified")).thenReturn(Optional.of(verifiedUser));
        when(transactionPersistencePort.calculateDailySpentByWalletId(eq("wallet-1"), any())).thenReturn(new BigDecimal("90000000")); // Spent 90M today

        BigDecimal initialBalance = sourceWallet.getBalance().getAmount();

        // Attempt transfer 20M VND (Total today: 110M > 100M limit)
        TransactionLimitExceededException ex = assertThrows(TransactionLimitExceededException.class, () -> {
            walletService.transfer(UUID.randomUUID().toString(), "wallet-1", "wallet-2", "SENHONG", Money.of(new BigDecimal("20000000"), "VND"), null);
        });

        assertTrue(ex.getMessage().contains("Daily transaction limit exceeded"));
        assertEquals(initialBalance, sourceWallet.getBalance().getAmount());
        verify(walletPersistencePort, never()).saveWallet(any());
    }

    @Test
    void testTransfer_ExceedMonthlyLimit_ThrowsExceptionAndDoesNotMutateBalance() {
        when(userPersistencePort.findUserById("user-verified")).thenReturn(Optional.of(verifiedUser));
        when(transactionPersistencePort.calculateDailySpentByWalletId(eq("wallet-1"), any())).thenReturn(new BigDecimal("10000000")); // Spent 10M today
        when(transactionPersistencePort.calculateMonthlySpentByWalletId(eq("wallet-1"), any())).thenReturn(new BigDecimal("490000000")); // Spent 490M this month

        BigDecimal initialBalance = sourceWallet.getBalance().getAmount();

        // Attempt transfer 20M VND (Total this month: 510M > 500M monthly limit)
        TransactionLimitExceededException ex = assertThrows(TransactionLimitExceededException.class, () -> {
            walletService.transfer(UUID.randomUUID().toString(), "wallet-1", "wallet-2", "SENHONG", Money.of(new BigDecimal("20000000"), "VND"), null);
        });

        assertTrue(ex.getMessage().contains("Monthly transaction limit exceeded"));
        assertEquals(initialBalance, sourceWallet.getBalance().getAmount());
        verify(walletPersistencePort, never()).saveWallet(any());
    }

    @Test
    void testInitTransfer_ExceedDailyLimit_ThrowsExceptionBeforeLock() {
        when(userPersistencePort.findUserById("user-verified")).thenReturn(Optional.of(verifiedUser));
        when(transactionPersistencePort.calculateDailySpentByWalletId(eq("wallet-1"), any())).thenReturn(new BigDecimal("95000000"));

        // Attempt to initialize transfer exceeding daily limit
        TransactionLimitExceededException ex = assertThrows(TransactionLimitExceededException.class, () -> {
            walletService.initTransfer(UUID.randomUUID().toString(), "wallet-1", "wallet-2", "SENHONG", Money.of(new BigDecimal("10000000"), "VND"), null);
        });

        assertTrue(ex.getMessage().contains("Daily transaction limit exceeded"));
        verify(transactionPersistencePort, never()).saveTransaction(any());
    }

    @Test
    void testUnverifiedUser_ExceedDailyLimit_ThrowsException() {
        Wallet unverifiedWallet = new Wallet("wallet-unverified", "user-unverified", Money.of(new BigDecimal("10000000"), "VND"), Instant.now(), Instant.now(), 0L);
        when(walletPersistencePort.findWalletById("wallet-unverified")).thenReturn(Optional.of(unverifiedWallet));
        when(userPersistencePort.findUserById("user-unverified")).thenReturn(Optional.of(unverifiedUser));
        when(transactionPersistencePort.calculateDailySpentByWalletId(eq("wallet-unverified"), any())).thenReturn(new BigDecimal("4000000")); // Limit is 5M

        // Attempt transfer 2M VND (Total today: 6M > 5M limit)
        TransactionLimitExceededException ex = assertThrows(TransactionLimitExceededException.class, () -> {
            walletService.transfer(UUID.randomUUID().toString(), "wallet-unverified", "wallet-2", "SENHONG", Money.of(new BigDecimal("2000000"), "VND"), null);
        });

        assertTrue(ex.getMessage().contains("Daily transaction limit exceeded"));
    }
}
