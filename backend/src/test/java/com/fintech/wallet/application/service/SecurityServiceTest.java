package com.fintech.wallet.application.service;

import com.fintech.wallet.infrastructure.security.JwtTokenProvider;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

class SecurityServiceTest {

    private static final String JWT_SECRET =
            "SuperSecretKeyForFintechWalletAppShouldBeAtLeast32BytesLong!";

    private SecurityService securityService;
    private JwtTokenProvider tokenProvider;

    @BeforeEach
    void setUp() {
        // JwtTokenProvider is a concrete @Component with no interface.
        // Mockito inline mocking fails on Java 25 — use a real instance instead.
        tokenProvider   = new JwtTokenProvider(JWT_SECRET);
        securityService = new SecurityService(tokenProvider);
    }

    // ─── Biometric ───────────────────────────────────────────────────────────

    @Test
    void registerBiometric_shouldStoreTokenWithoutException() {
        assertDoesNotThrow(() -> securityService.registerBiometric("u1", "bio-token-abc"));
    }

    @Test
    void verifyBiometric_correctToken_shouldReturnPinJwt() {
        securityService.registerBiometric("u1", "bio-token-abc");

        String pinToken = securityService.verifyBiometric("u1", "bio-token-abc");

        assertNotNull(pinToken);
        assertTrue(tokenProvider.validateToken(pinToken));
        assertEquals("u1", tokenProvider.getUserIdFromToken(pinToken));
        assertEquals("PIN_VERIFIED", tokenProvider.getTokenType(pinToken));
    }

    @Test
    void verifyBiometric_wrongToken_shouldThrow() {
        securityService.registerBiometric("u1", "correct-token");

        assertThrows(IllegalArgumentException.class,
                () -> securityService.verifyBiometric("u1", "wrong-token"));
    }

    @Test
    void verifyBiometric_unregisteredUser_shouldThrow() {
        assertThrows(IllegalArgumentException.class,
                () -> securityService.verifyBiometric("unknown-user", "any-token"));
    }

    // ─── Login history ────────────────────────────────────────────────────────

    @Test
    void getLoginHistory_shouldReturnNonEmptyList() {
        List<Map<String, Object>> history = securityService.getLoginHistory("u1");

        assertNotNull(history);
        assertFalse(history.isEmpty());
        assertTrue(history.get(0).containsKey("timestamp"));
        assertTrue(history.get(0).containsKey("status"));
    }

    // ─── 2FA ─────────────────────────────────────────────────────────────────

    @Test
    void enable2FA_shouldNotThrow() {
        assertDoesNotThrow(() -> securityService.enable2FA("u1"));
    }

    @Test
    void disable2FA_shouldNotThrow() {
        securityService.enable2FA("u1");
        assertDoesNotThrow(() -> securityService.disable2FA("u1"));
    }
}
