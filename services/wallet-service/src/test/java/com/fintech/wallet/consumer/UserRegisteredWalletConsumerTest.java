package com.fintech.wallet.consumer;

import com.fintech.wallet.domain.event.UserRegisteredEvent;
import com.fintech.wallet.domain.model.Wallet;
import com.fintech.wallet.domain.port.out.WalletPersistencePort;
import com.fintech.wallet.infrastructure.amqp.consumer.UserRegisteredWalletConsumer;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.math.BigDecimal;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

/**
 * Unit tests cho UserRegisteredWalletConsumer.
 * Kiểm tra idempotent creation và auto-create wallet khi user đăng ký mới.
 */
@ExtendWith(MockitoExtension.class)
class UserRegisteredWalletConsumerTest {

    @Mock
    private WalletPersistencePort walletPersistencePort;

    @InjectMocks
    private UserRegisteredWalletConsumer consumer;

    private UserRegisteredEvent createEvent(String userId, String phone) {
        return UserRegisteredEvent.of(userId, phone, "Nguyễn Văn A", 1, "VN");
    }

    @Test
    @DisplayName("Should create wallet when user has no existing wallet")
    void handleUserRegistered_createsNewWallet() {
        String userId = "user-1";
        UserRegisteredEvent event = createEvent(userId, "0987654321");

        when(walletPersistencePort.findWalletByOwnerId(userId)).thenReturn(Optional.empty());
        doAnswer(invocation -> invocation.getArgument(0)).when(walletPersistencePort).saveWallet(any(Wallet.class));

        assertDoesNotThrow(() -> consumer.handleUserRegistered(event));

        verify(walletPersistencePort).findWalletByOwnerId(userId);
        verify(walletPersistencePort).saveWallet(any(Wallet.class));
    }

    @Test
    @DisplayName("Should skip creation when wallet already exists (idempotent)")
    void handleUserRegistered_skipsWhenExists() {
        String userId = "user-2";
        Wallet existing = Wallet.createNew(userId, "VND");

        when(walletPersistencePort.findWalletByOwnerId(userId)).thenReturn(Optional.of(existing));

        assertDoesNotThrow(() -> consumer.handleUserRegistered(createEvent(userId, "0987654322")));

        verify(walletPersistencePort).findWalletByOwnerId(userId);
        // saveWallet should NOT be called — idempotent
        verify(walletPersistencePort, never()).saveWallet(any());
    }

    @Test
    @DisplayName("Should throw when userId is blank in event")
    void handleUserRegistered_invalidUserId_throws() {
        assertThrows(IllegalArgumentException.class, () ->
                consumer.handleUserRegistered(UserRegisteredEvent.of("", "0987654321", "Test", 0, "VN")));
        verifyNoInteractions(walletPersistencePort);
    }

    @Test
    @DisplayName("Should throw when phone is blank in event")
    void handleUserRegistered_invalidPhone_throws() {
        assertThrows(IllegalArgumentException.class, () ->
                consumer.handleUserRegistered(UserRegisteredEvent.of("user-3", "", "Test", 0, "VN")));
        verifyNoInteractions(walletPersistencePort);
    }

    @Test
    @DisplayName("Created wallet must have VND currency, ACTIVE status, zero balance")
    void handleUserRegistered_walletProperties() {
        String userId = "user-4";
        when(walletPersistencePort.findWalletByOwnerId(userId)).thenReturn(Optional.empty());

        ArgumentCaptor<Wallet> captor = ArgumentCaptor.forClass(Wallet.class);
        doAnswer(invocation -> invocation.getArgument(0)).when(walletPersistencePort).saveWallet(captor.capture());

        consumer.handleUserRegistered(createEvent(userId, "0987654324"));

        Wallet created = captor.getValue();
        assertEquals(userId, created.getOwnerId());
        assertEquals("VND", created.getBalance().getCurrency());
        assertEquals(0L, created.getBalance().getAmount().longValue());
        assertEquals(com.fintech.wallet.domain.model.WalletStatus.ACTIVE, created.getStatus());
        assertEquals(BigDecimal.ZERO, created.getReservedBalance());
    }
}
