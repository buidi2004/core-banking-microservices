package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.exception.TransactionLimitExceededException;
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
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class WalletServiceTest {

    private WalletPersistencePort walletPersistencePort;
    private TransactionPersistencePort transactionPersistencePort;
    private DistributedLockPort distributedLockPort;
    private TransactionalOperationPort transactionalOperationPort;
    private UserPersistencePort userPersistencePort;
    private AuditLogPersistencePort auditLogPersistencePort;
    private WalletService walletService;

    @BeforeEach
    void setUp() {
        walletPersistencePort = mock(WalletPersistencePort.class);
        transactionPersistencePort = mock(TransactionPersistencePort.class);
        distributedLockPort = mock(DistributedLockPort.class);
        transactionalOperationPort = mock(TransactionalOperationPort.class);
        userPersistencePort = mock(UserPersistencePort.class);
        auditLogPersistencePort = mock(AuditLogPersistencePort.class);

        walletService = new WalletService(
                walletPersistencePort,
                transactionPersistencePort,
                distributedLockPort,
                null,
                transactionalOperationPort,
                null,
                userPersistencePort,
                auditLogPersistencePort
        );

        when(distributedLockPort.executeWithLock(anyString(), any(Long.class), any())).thenAnswer(invocation -> {
            org.springframework.integration.support.Supplier<Object> supplier = invocation.getArgument(2);
            return supplier.get();
        });
    }

    @Test
    void testTransferExceedsUnverifiedLimit_throwsException() {
        String userId = "user-123";
        User user = new User(userId, "0987654321", "hash", "123456", KycStatus.UNVERIFIED, Instant.now(), Instant.now());
        when(userPersistencePort.findUserById(userId)).thenReturn(Optional.of(user));

        Wallet sourceWallet = new Wallet("wallet-1", userId, Money.of(new BigDecimal("10000000"), "VND"), "VND", Instant.now(), Instant.now());
        Wallet targetWallet = new Wallet("wallet-2", "user-456", Money.of(new BigDecimal("1000000"), "VND"), "VND", Instant.now(), Instant.now());

        when(walletPersistencePort.findWalletById("wallet-1")).thenReturn(Optional.of(sourceWallet));
        when(walletPersistencePort.findWalletById("wallet-2")).thenReturn(Optional.of(targetWallet));

        // Spent 4,000,000 today already. Trying to transfer 2,000,000 (total = 6,000,000 > 5,000,000 limit)
        when(transactionPersistencePort.calculateDailySpentByWalletId(eq("wallet-1"), any())).thenReturn(new BigDecimal("4000000"));

        assertThrows(TransactionLimitExceededException.class, () -> {
            walletService.transfer("req-1", "wallet-1", "wallet-2", Money.of(new BigDecimal("2000000"), "VND"));
        });
    }
}
