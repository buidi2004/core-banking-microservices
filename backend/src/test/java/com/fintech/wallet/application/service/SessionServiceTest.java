package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.model.DeviceSession;
import com.fintech.wallet.domain.port.out.SessionPersistencePort;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

class SessionServiceTest {

    @Mock
    private SessionPersistencePort sessionPersistencePort;

    @InjectMocks
    private SessionService target;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void createOrUpdateSession_createNew_shouldReturnNewSession() {
        String userId = "user1";
        String deviceId = "dev1";
        
        when(sessionPersistencePort.findByUserIdAndDeviceId(userId, deviceId)).thenReturn(Optional.empty());

        DeviceSession session = target.createOrUpdateSession(userId, deviceId, "127.0.0.1", "Agent");

        assertNotNull(session);
        assertNotNull(session.getRefreshToken());
        assertEquals(userId, session.getUserId());
        assertTrue(session.isActive());
        verify(sessionPersistencePort, times(1)).save(any(DeviceSession.class));
    }

    @Test
    void createOrUpdateSession_existing_shouldUpdateSession() {
        String userId = "user1";
        String deviceId = "dev1";
        DeviceSession existingSession = DeviceSession.createNew(userId, deviceId, "127.0.0.1", "Agent", Instant.now().plusSeconds(3600));
        
        when(sessionPersistencePort.findByUserIdAndDeviceId(userId, deviceId)).thenReturn(Optional.of(existingSession));

        DeviceSession session = target.createOrUpdateSession(userId, deviceId, "127.0.0.1", "Agent");

        assertNotNull(session);
        assertEquals(userId, session.getUserId());
        assertTrue(session.isActive());
        verify(sessionPersistencePort, times(1)).save(existingSession);
    }

    @Test
    void validateSession_active_shouldReturnSession() {
        String userId = "user1";
        String deviceId = "dev1";
        DeviceSession existingSession = DeviceSession.createNew(userId, deviceId, "127.0.0.1", "Agent", Instant.now().plusSeconds(3600));
        
        when(sessionPersistencePort.findByUserIdAndDeviceId(userId, deviceId)).thenReturn(Optional.of(existingSession));

        Optional<DeviceSession> result = target.validateSession(userId, deviceId);
        
        assertTrue(result.isPresent());
    }

    @Test
    void validateSession_revoked_shouldReturnEmpty() {
        String userId = "user1";
        String deviceId = "dev1";
        DeviceSession existingSession = DeviceSession.createNew(userId, deviceId, "127.0.0.1", "Agent", Instant.now().plusSeconds(3600));
        existingSession.revoke();

        when(sessionPersistencePort.findByUserIdAndDeviceId(userId, deviceId)).thenReturn(Optional.of(existingSession));

        Optional<DeviceSession> result = target.validateSession(userId, deviceId);
        
        assertTrue(result.isEmpty());
    }

    @Test
    void revokeSession_shouldCallSaveWithRevokedSession() {
        String userId = "user1";
        String deviceId = "dev1";
        DeviceSession existingSession = DeviceSession.createNew(userId, deviceId, "127.0.0.1", "Agent", Instant.now().plusSeconds(3600));
        
        when(sessionPersistencePort.findByUserIdAndDeviceId(userId, deviceId)).thenReturn(Optional.of(existingSession));

        target.revokeSession(userId, deviceId);

        assertFalse(existingSession.isActive());
        verify(sessionPersistencePort, times(1)).save(existingSession);
    }
}
