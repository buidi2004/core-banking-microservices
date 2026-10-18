package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.model.User;
import com.fintech.wallet.domain.port.in.GetWalletUseCase;
import com.fintech.wallet.domain.port.out.UserPersistencePort;
import com.fintech.wallet.infrastructure.security.JwtTokenProvider;
import com.fintech.wallet.infrastructure.security.RedisRateLimiter;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class AuthServiceTest {

    private static final String JWT_SECRET =
            "SuperSecretKeyForFintechWalletAppShouldBeAtLeast32BytesLong!";

    private UserPersistencePort userPersistencePort;
    private GetWalletUseCase getWalletUseCase;
    private PasswordEncoder passwordEncoder;
    private JwtTokenProvider tokenProvider;
    private AuthService authService;

    @BeforeEach
    void setUp() {
        userPersistencePort = Mockito.mock(UserPersistencePort.class);
        getWalletUseCase   = Mockito.mock(GetWalletUseCase.class);
        passwordEncoder    = new BCryptPasswordEncoder();
        // JwtTokenProvider is a @Component with no interface — use real instance
        tokenProvider      = new JwtTokenProvider(JWT_SECRET);
        // RedisRateLimiter cannot be mocked on Java 25 with inline mocking.
        // Use a real instance: it falls back to "allow-all" when redisTemplate is null.
        RedisRateLimiter rateLimiter = new RedisRateLimiter();

        authService = new AuthService(
                userPersistencePort,
                getWalletUseCase,
                passwordEncoder,
                tokenProvider,
                rateLimiter);
    }

    @Test
    void register_shouldCreateUserAndAutoGenerateWallet() {
        String phone    = "0987654321";
        String password = "password123";

        when(userPersistencePort.findUserByPhoneNumber(phone)).thenReturn(Optional.empty());
        when(userPersistencePort.saveUser(any(User.class)))
                .thenAnswer(inv -> inv.getArgument(0));

        User registered = authService.register(phone, "Test Name", password);

        assertNotNull(registered);
        assertEquals(phone, registered.getPhoneNumber());
        assertTrue(passwordEncoder.matches(password, registered.getPasswordHash()));

        // Auto-create default VND wallet must be called
        verify(getWalletUseCase).createWallet(eq(registered.getId()), eq("VND"));
    }

    @Test
    void register_duplicatePhone_shouldThrow() {
        String phone = "0987654321";
        User existing = new User("u1", phone, "Test Name", "hash", null, null, null, null);
        when(userPersistencePort.findUserByPhoneNumber(phone)).thenReturn(Optional.of(existing));

        assertThrows(IllegalArgumentException.class,
                () -> authService.register(phone, "Test Name", "password123"));
    }

    @Test
    void register_shortPassword_shouldThrow() {
        when(userPersistencePort.findUserByPhoneNumber(any())).thenReturn(Optional.empty());
        assertThrows(IllegalArgumentException.class,
                () -> authService.register("0987654321", "Test Name", "123"));
    }

    @Test
    void login_shouldReturnAccessTokenForValidCredentials() {
        String phone    = "0987654321";
        String password = "password123";
        String encoded  = passwordEncoder.encode(password);
        User user = new User("user_1", phone, "Test Name", encoded, null, null, null, null);

        when(userPersistencePort.findUserByPhoneNumber(phone)).thenReturn(Optional.of(user));

        com.fintech.wallet.domain.model.AuthTokens tokens = authService.login(phone, password, "dev1", "127.0.0.1", "Agent");

        assertNotNull(tokens);
        assertNotNull(tokens.getAccessToken());
        assertTrue(tokenProvider.validateToken(tokens.getAccessToken()));
        assertEquals("user_1", tokenProvider.getUserIdFromToken(tokens.getAccessToken()));
    }

    @Test
    void login_wrongPassword_shouldThrow() {
        String phone   = "0987654321";
        String encoded = passwordEncoder.encode("correct");
        User user = new User("u1", phone, "Test Name", encoded, null, null, null, null);

        when(userPersistencePort.findUserByPhoneNumber(phone)).thenReturn(Optional.of(user));

        assertThrows(IllegalArgumentException.class,
                () -> authService.login(phone, "wrong", "dev1", "127.0.0.1", "Agent"));
    }

    @Test
    void login_unknownPhone_shouldThrow() {
        when(userPersistencePort.findUserByPhoneNumber(any())).thenReturn(Optional.empty());
        assertThrows(IllegalArgumentException.class,
                () -> authService.login("0000000000", "pass", "dev1", "127.0.0.1", "Agent"));
    }
}
