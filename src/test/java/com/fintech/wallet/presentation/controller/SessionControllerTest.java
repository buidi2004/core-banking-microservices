package com.fintech.wallet.presentation.controller;

import com.fintech.wallet.domain.model.DeviceSession;
import com.fintech.wallet.domain.port.in.SessionManagementUseCase;
import com.fintech.wallet.presentation.response.ApiResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;

import java.time.Instant;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class SessionControllerTest {

    @Mock
    private SessionManagementUseCase sessionManagementUseCase;

    @Mock
    private Authentication auth;

    @InjectMocks
    private SessionController target;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
        when(auth.getName()).thenReturn("user-1");
    }

    @Test
    void getActiveSessions_shouldReturnSessionList() {
        DeviceSession session = DeviceSession.createNew("user-1", "dev1", "1.1.1.1", "Agent", Instant.now().plusSeconds(3600));
        when(sessionManagementUseCase.getActiveSessions("user-1")).thenReturn(List.of(session));

        ResponseEntity<ApiResponse<List<DeviceSession>>> response =
                target.getActiveSessions(auth);

        assertEquals(200, response.getStatusCode().value());
        assertNotNull(response.getBody());
        assertEquals(1, response.getBody().getData().size());
        verify(sessionManagementUseCase).getActiveSessions("user-1");
    }

    @Test
    void revokeSession_shouldCallUseCaseAndReturn200() {
        doNothing().when(sessionManagementUseCase).revokeSession("user-1", "dev1");

        ResponseEntity<ApiResponse<Void>> response =
                target.revokeSession(auth, "dev1");

        assertEquals(200, response.getStatusCode().value());
        verify(sessionManagementUseCase).revokeSession("user-1", "dev1");
    }

    @Test
    void revokeAllSessions_shouldCallUseCaseAndReturn200() {
        doNothing().when(sessionManagementUseCase).revokeAllSessions("user-1");

        ResponseEntity<ApiResponse<Void>> response =
                target.revokeAllSessions(auth);

        assertEquals(200, response.getStatusCode().value());
        verify(sessionManagementUseCase).revokeAllSessions("user-1");
    }

    @Test
    void registerFcmToken_shouldCallUseCaseAndReturn200() {
        doNothing().when(sessionManagementUseCase).updateFcmToken("user-1", "dev1", "fcm123");

        ResponseEntity<ApiResponse<Void>> response =
                target.registerFcmToken(auth, "dev1", "fcm123");

        assertEquals(200, response.getStatusCode().value());
        verify(sessionManagementUseCase).updateFcmToken("user-1", "dev1", "fcm123");
    }
}
