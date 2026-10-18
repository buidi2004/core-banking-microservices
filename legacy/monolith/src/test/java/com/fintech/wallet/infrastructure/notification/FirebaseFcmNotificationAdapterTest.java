package com.fintech.wallet.infrastructure.notification;

import com.fintech.wallet.domain.model.DeviceToken;
import com.fintech.wallet.domain.port.out.DeviceTokenPersistencePort;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.Collections;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.mockito.Mockito.*;

class FirebaseFcmNotificationAdapterTest {

    private DeviceTokenPersistencePort persistencePort;
    private com.fintech.wallet.domain.port.out.SessionPersistencePort sessionPersistencePort;
    private FirebaseFcmNotificationAdapter adapter;

    @BeforeEach
    void setUp() {
        persistencePort = mock(DeviceTokenPersistencePort.class);
        sessionPersistencePort = mock(com.fintech.wallet.domain.port.out.SessionPersistencePort.class);
        adapter = new FirebaseFcmNotificationAdapter(persistencePort, sessionPersistencePort);
    }

    @Test
    void sendPushNotification_whenNoTokensForUser_shouldSkipWithoutError() {
        String userId = "user-no-devices";
        when(persistencePort.findByUserId(userId)).thenReturn(Collections.emptyList());

        assertDoesNotThrow(() -> adapter.sendPushNotification(userId, "Title", "Body", Map.of("transactionId", "tx-123")));

        verify(persistencePort).findByUserId(userId);
    }

    @Test
    void sendPushNotification_whenTokensExistButFirebaseUninitialized_shouldLogMockAndNotThrow() {
        String userId = "user-with-device";
        DeviceToken token = DeviceToken.createNew(userId, "fcm-fake-token", "ANDROID");
        when(persistencePort.findByUserId(userId)).thenReturn(List.of(token));

        assertDoesNotThrow(() -> adapter.sendPushNotification(userId, "Biến động số dư", "TK 0901 GD thành công", Map.of("amount", "100000")));

        verify(persistencePort).findByUserId(userId);
    }

    @Test
    void sendPushNotification_withNullUserId_shouldReturnEarly() {
        assertDoesNotThrow(() -> adapter.sendPushNotification(null, "Title", "Body"));
        verifyNoInteractions(persistencePort);
    }
}
