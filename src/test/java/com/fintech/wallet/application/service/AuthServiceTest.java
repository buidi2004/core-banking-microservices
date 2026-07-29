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

    private UserPersistencePort userPersistencePort;
    private GetWalletUseCase getWalletUseCase;
    private PasswordEncoder passwordEncoder;
    private JwtTokenProvider tokenProvider;
    private RedisRateLimiter rateLimiter;
    private AuthService authService;

    @BeforeEach
    void setUp() {
        userPersistencePort = Mockito.mock(UserPersistencePort.class);
        getWalletUseCase = Mockito.mock(GetWalletUseCase.class);
        passwordEncoder = new BCryptPasswordEncoder();
        tokenProvider = new JwtTokenProvider("SuperSecretKeyForFintechWalletAppShouldBeAtLeast32BytesLong!");
        rateLimiter = Mockito.mock(RedisRateLimiter.class);

        authService = new AuthService(userPersistencePort, getWalletUseCase, passwordEncoder, tokenProvider, rateLimiter);
    }

    @Test
    void register_shouldCreateUserAndAutoGenerateWallet() {
        String phone = "0987654321";
        String password = "password123";

        when(userPersistencePort.findUserByPhoneNumber(phone)).thenReturn(Optional.empty());
        when(userPersistencePort.saveUser(any(User.class))).thenAnswer(invocation -> invocation.getArgument(0));

        User registered = authService.register(phone, password);

        assertNotNull(registered);
        assertEquals(phone, registered.getPhoneNumber());
        assertTrue(passwordEncoder.matches(password, registered.getPasswordHash()));

        // Verify automatic default wallet creation
        verify(getWalletUseCase).createWallet(eq(registered.getId()), eq("VND"));
    }

    @Test
    void login_shouldReturnAccessTokenForValidCredentials() {
        String phone = "0987654321";
        String password = "password123";
        String encodedPassword = passwordEncoder.encode(password);
        User user = new User("user_1", phone, encodedPassword, null, null, null, null);

        when(userPersistencePort.findUserByPhoneNumber(phone)).thenReturn(Optional.of(user));

        String token = authService.login(phone, password);

        assertNotNull(token);
        assertTrue(tokenProvider.validateToken(token));
        assertEquals("user_1", tokenProvider.getUserIdFromToken(token));
    }
}
