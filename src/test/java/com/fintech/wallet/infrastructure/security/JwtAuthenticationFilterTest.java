package com.fintech.wallet.infrastructure.security;

import com.fintech.wallet.domain.model.DeviceSession;
import com.fintech.wallet.domain.port.in.SessionManagementUseCase;
import com.fintech.wallet.domain.port.out.TokenBlacklistPort;
import jakarta.servlet.FilterChain;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class JwtAuthenticationFilterTest {

    @Mock
    private JwtTokenProvider tokenProvider;

    @Mock
    private TokenBlacklistPort tokenBlacklistPort;

    @Mock
    private SessionManagementUseCase sessionManagementUseCase;

    @Mock
    private HttpServletRequest request;

    @Mock
    private HttpServletResponse response;

    @Mock
    private FilterChain filterChain;

    @InjectMocks
    private JwtAuthenticationFilter filter;

    @BeforeEach
    void setUp() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void doFilterInternal_validTokenAndSession_setsAuthentication() throws Exception {
        String token = "valid-token";
        when(request.getHeader("Authorization")).thenReturn("Bearer " + token);
        when(tokenProvider.validateToken(token)).thenReturn(true);
        when(tokenBlacklistPort.isBlacklisted(token)).thenReturn(false);
        when(tokenProvider.getUserIdFromToken(token)).thenReturn("user-1");
        when(tokenProvider.getTokenType(token)).thenReturn("ACCESS");
        when(tokenProvider.getDeviceIdFromToken(token)).thenReturn("device-1");
        
        DeviceSession session = DeviceSession.createNew("user-1", "device-1", "127.0.0.1", "agent", java.time.Instant.now().plusSeconds(100));
        when(sessionManagementUseCase.validateSession("user-1", "device-1")).thenReturn(Optional.of(session));

        filter.doFilterInternal(request, response, filterChain);

        assertNotNull(SecurityContextHolder.getContext().getAuthentication());
        verify(filterChain).doFilter(request, response);
    }

    @Test
    void doFilterInternal_validTokenButSessionRevoked_returnsUnauthorized() throws Exception {
        String token = "valid-token";
        when(request.getHeader("Authorization")).thenReturn("Bearer " + token);
        when(tokenProvider.validateToken(token)).thenReturn(true);
        when(tokenBlacklistPort.isBlacklisted(token)).thenReturn(false);
        when(tokenProvider.getUserIdFromToken(token)).thenReturn("user-1");
        when(tokenProvider.getTokenType(token)).thenReturn("ACCESS");
        when(tokenProvider.getDeviceIdFromToken(token)).thenReturn("device-1");

        // Session not found or revoked
        when(sessionManagementUseCase.validateSession("user-1", "device-1")).thenReturn(Optional.empty());

        filter.doFilterInternal(request, response, filterChain);

        assertNull(SecurityContextHolder.getContext().getAuthentication());
        verify(response).sendError(eq(HttpServletResponse.SC_UNAUTHORIZED), any());
        verify(filterChain, never()).doFilter(request, response);
    }

    @Test
    void doFilterInternal_blacklistedToken_doesNotSetAuthentication() throws Exception {
        String token = "valid-token";
        when(request.getHeader("Authorization")).thenReturn("Bearer " + token);
        when(tokenProvider.validateToken(token)).thenReturn(true);
        when(tokenBlacklistPort.isBlacklisted(token)).thenReturn(true);

        filter.doFilterInternal(request, response, filterChain);

        assertNull(SecurityContextHolder.getContext().getAuthentication());
        verify(filterChain).doFilter(request, response);
    }
}
