package com.fintech.wallet.presentation.controller;

import com.fintech.wallet.domain.model.UserSession;
import com.fintech.wallet.domain.port.in.SessionUseCase;
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
    private SessionUseCase sessionUseCase;   // interface → Mockito can mock it

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
        Instant now = Instant.now();
        UserSession session = new UserSession("s1", "user-1", "iOS App", "1.1.1.1", now, now);
        when(sessionUseCase.getActiveSessions("user-1")).thenReturn(List.of(session));

        ResponseEntity<ApiResponse<List<UserSession>>> response =
                target.getActiveSessions(auth);

        assertEquals(200, response.getStatusCode().value());
        assertNotNull(response.getBody());
        assertEquals(1, response.getBody().getData().size());
        verify(sessionUseCase).getActiveSessions("user-1");
    }

    @Test
    void revokeSession_shouldCallUseCaseAndReturn200() {
        doNothing().when(sessionUseCase).revokeSession("user-1", "sess-abc");

        ResponseEntity<ApiResponse<Void>> response =
                target.revokeSession(auth, "sess-abc");

        assertEquals(200, response.getStatusCode().value());
        verify(sessionUseCase).revokeSession("user-1", "sess-abc");
    }

    @Test
    void revokeAllSessions_shouldCallUseCaseAndReturn200() {
        doNothing().when(sessionUseCase).revokeAllSessions("user-1");

        ResponseEntity<ApiResponse<Void>> response =
                target.revokeAllSessions(auth);

        assertEquals(200, response.getStatusCode().value());
        verify(sessionUseCase).revokeAllSessions("user-1");
    }
}
