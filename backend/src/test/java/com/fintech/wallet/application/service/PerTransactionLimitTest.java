package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.exception.InvalidMoneyException;
import com.fintech.wallet.domain.exception.TransactionLimitExceededException;
import com.fintech.wallet.domain.model.Money;
import com.fintech.wallet.domain.port.in.LedgerUseCase;
import com.fintech.wallet.domain.port.out.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertThrows;

@ExtendWith(MockitoExtension.class)
public class PerTransactionLimitTest {

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
    }

    @Test
    void testTransfer_LessThanMinimumAmount_ThrowsInvalidMoneyException() {
        Money belowMin = Money.of(new BigDecimal("500"), "VND"); // Min is 1,000 VND

        assertThrows(InvalidMoneyException.class, () -> {
            walletService.transfer(UUID.randomUUID().toString(), "w1", "w2", belowMin);
        });
    }

    @Test
    void testTransfer_ExceedsSingleTransactionLimit_ThrowsTransactionLimitExceededException() {
        Money overMaxSingle = Money.of(new BigDecimal("60000000"), "VND"); // Max single is 50M VND

        assertThrows(TransactionLimitExceededException.class, () -> {
            walletService.transfer(UUID.randomUUID().toString(), "w1", "w2", overMaxSingle);
        });
    }

    @Test
    void testInitTransfer_LessThanMinimumAmount_ThrowsInvalidMoneyException() {
        Money belowMin = Money.of(new BigDecimal("999"), "VND");

        assertThrows(InvalidMoneyException.class, () -> {
            walletService.initTransfer(UUID.randomUUID().toString(), "w1", "w2", belowMin);
        });
    }

    @Test
    void testInitTransfer_ExceedsSingleTransactionLimit_ThrowsTransactionLimitExceededException() {
        Money overMaxSingle = Money.of(new BigDecimal("50000001"), "VND");

        assertThrows(TransactionLimitExceededException.class, () -> {
            walletService.initTransfer(UUID.randomUUID().toString(), "w1", "w2", overMaxSingle);
        });
    }
}
