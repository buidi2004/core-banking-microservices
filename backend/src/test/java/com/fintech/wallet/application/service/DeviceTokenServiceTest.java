package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.model.DeviceToken;
import com.fintech.wallet.domain.port.out.DeviceTokenPersistencePort;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.mockito.Mockito;

import java.time.Instant;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class DeviceTokenServiceTest {

    private DeviceTokenPersistencePort persistencePort;
    private DeviceTokenService deviceTokenService;

    @BeforeEach
    void setUp() {
        persistencePort = mock(DeviceTokenPersistencePort.class);
        deviceTokenService = new DeviceTokenService(persistencePort);
    }

    @Test
    void registerDeviceToken_whenNewToken_shouldCreateAndSave() {
        String userId = "user-123";
        String fcmToken = "fcm-token-abc";
        String deviceType = "ANDROID";

        when(persistencePort.findByFcmToken(fcmToken)).thenReturn(Optional.empty());
        when(persistencePort.save(any(DeviceToken.class))).thenAnswer(invocation -> invocation.getArgument(0));

        DeviceToken result = deviceTokenService.registerDeviceToken(userId, fcmToken, deviceType);

        assertNotNull(result);
        assertEquals(userId, result.getUserId());
        assertEquals(fcmToken, result.getFcmToken());
        assertEquals("ANDROID", result.getDeviceType());
        assertNotNull(result.getId());
        assertNotNull(result.getCreatedAt());

        verify(persistencePort).save(any(DeviceToken.class));
    }

    @Test
    void registerDeviceToken_whenTokenExistsForOtherUser_shouldReassignToNewUser() {
        String oldUserId = "user-old";
        String newUserId = "user-new";
        String fcmToken = "fcm-token-shared";

        DeviceToken existing = new DeviceToken("token-id-1", oldUserId, fcmToken, "IOS", Instant.now().minusSeconds(3600), Instant.now().minusSeconds(3600));
        when(persistencePort.findByFcmToken(fcmToken)).thenReturn(Optional.of(existing));
        when(persistencePort.save(any(DeviceToken.class))).thenAnswer(invocation -> invocation.getArgument(0));

        DeviceToken result = deviceTokenService.registerDeviceToken(newUserId, fcmToken, "IOS");

        assertNotNull(result);
        assertEquals(newUserId, result.getUserId());
        assertEquals("token-id-1", result.getId());
        assertEquals(fcmToken, result.getFcmToken());
        assertEquals("IOS", result.getDeviceType());

        ArgumentCaptor<DeviceToken> captor = ArgumentCaptor.forClass(DeviceToken.class);
        verify(persistencePort).save(captor.capture());
        assertEquals(newUserId, captor.getValue().getUserId());
    }

    @Test
    void registerDeviceToken_withBlankInputs_shouldThrowException() {
        assertThrows(IllegalArgumentException.class, () -> deviceTokenService.registerDeviceToken("", "token", "ANDROID"));
        assertThrows(IllegalArgumentException.class, () -> deviceTokenService.registerDeviceToken("user", "", "ANDROID"));
    }

    @Test
    void unregisterDeviceToken_shouldDeleteFromPersistence() {
        String userId = "user-123";
        String fcmToken = "fcm-token-to-delete";

        deviceTokenService.unregisterDeviceToken(userId, fcmToken);

        verify(persistencePort).deleteByFcmToken(fcmToken);
    }
}
