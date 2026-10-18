package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.model.KycStatus;
import com.fintech.wallet.domain.model.Money;
import com.fintech.wallet.domain.model.User;
import com.fintech.wallet.domain.model.UserKyc;
import com.fintech.wallet.domain.model.Wallet;
import com.fintech.wallet.domain.port.in.LedgerUseCase;
import com.fintech.wallet.domain.port.out.*;
import com.fintech.wallet.presentation.response.RecipientInfoResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
public class RecipientInfoTest {

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
    @Mock
    private KycPersistencePort kycPersistencePort;

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
        // Inject kycPersistencePort using reflection or setter
        org.springframework.test.util.ReflectionTestUtils.setField(walletService, "kycPersistencePort", kycPersistencePort);
    }

    @Test
    void testGetRecipientInfoByWalletId_WithKyc_ReturnsMaskedName() {
        String walletId = "wallet-123";
        String userId = "user-456";
        String phone = "0987654321";

        Wallet wallet = new Wallet(walletId, userId, Money.of(BigDecimal.ZERO, "VND"), Instant.now(), Instant.now(), 0L);
        User user = new User(userId, phone, "Test Name", "hash", "123456", KycStatus.VERIFIED, Instant.now(), Instant.now());
        UserKyc kyc = new UserKyc("kyc-1", userId, "123456789", "Nguyen Van An", "2000-01-01", "f", "b", "s", KycStatus.VERIFIED, Instant.now(), Instant.now());

        when(walletPersistencePort.findWalletById(walletId)).thenReturn(Optional.of(wallet));
        when(userPersistencePort.findUserById(userId)).thenReturn(Optional.of(user));
        when(kycPersistencePort.findKycByUserId(userId)).thenReturn(Optional.of(kyc));

        RecipientInfoResponse response = walletService.getRecipientInfo(walletId, null);

        assertNotNull(response);
        assertEquals(walletId, response.getWalletId());
        assertEquals(phone, response.getPhoneNumber());
        assertEquals("NGUYEN V** AN", response.getMaskedName());
    }

    @Test
    void testGetRecipientInfoByPhoneNumber_WithoutKyc_ReturnsMaskedPhoneFallback() {
        String walletId = "wallet-789";
        String userId = "user-789";
        String phone = "0912345678";

        Wallet wallet = new Wallet(walletId, userId, Money.of(BigDecimal.ZERO, "VND"), Instant.now(), Instant.now(), 0L);
        User user = new User(userId, phone, "Test Name", "hash", "123456", KycStatus.UNVERIFIED, Instant.now(), Instant.now());

        when(userPersistencePort.findUserByPhoneNumber(phone)).thenReturn(Optional.of(user));
        when(walletPersistencePort.findWalletByOwnerId(userId)).thenReturn(Optional.of(wallet));

        RecipientInfoResponse response = walletService.getRecipientInfo(null, phone);

        assertNotNull(response);
        assertEquals(walletId, response.getWalletId());
        assertEquals(phone, response.getPhoneNumber());
        assertEquals("T*** NAME", response.getMaskedName());
    }

    @Test
    void testGetRecipientInfo_NoParams_ThrowsException() {
        assertThrows(IllegalArgumentException.class, () -> {
            walletService.getRecipientInfo(null, null);
        });
    }
}
