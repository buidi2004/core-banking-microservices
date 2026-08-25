package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.exception.AccountLockedException;
import com.fintech.wallet.domain.model.User;
import com.fintech.wallet.domain.port.in.GetWalletUseCase;
import com.fintech.wallet.domain.port.out.TokenBlacklistPort;
import com.fintech.wallet.domain.port.out.UserPersistencePort;
import com.fintech.wallet.infrastructure.security.JwtTokenProvider;
import com.fintech.wallet.infrastructure.security.RedisRateLimiter;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ValueOperations;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.Duration;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class AuthSecurityFeaturesTest {

    private static final String JWT_SECRET =
            "SuperSecretKeyForFintechWalletAppShouldBeAtLeast32BytesLong!";

    @Mock
    private UserPersistencePort userPersistencePort;
    @Mock
    private GetWalletUseCase getWalletUseCase;
    @Mock
    private StringRedisTemplate redisTemplate;
    @Mock
    private ValueOperations<String, String> valueOperations;
    @Mock
    private TokenBlacklistPort tokenBlacklistPort;

    private PasswordEncoder passwordEncoder;
    private JwtTokenProvider tokenProvider;
    private AuthService authService;

    @BeforeEach
    void setUp() {
        passwordEncoder = new BCryptPasswordEncoder();
        tokenProvider = new JwtTokenProvider(JWT_SECRET);
        RedisRateLimiter rateLimiter = new RedisRateLimiter();

        authService = new AuthService(
                userPersistencePort,
                getWalletUseCase,
                passwordEncoder,
                tokenProvider,
                rateLimiter,
                null,
                tokenBlacklistPort
        );
        ReflectionTestUtils.setField(authService, "redisTemplate", redisTemplate);
        lenient().when(redisTemplate.opsForValue()).thenReturn(valueOperations);
    }

    @Test
    void testLogin_AccountAlreadyLocked_ThrowsAccountLockedException() {
        String phone = "0987654321";
        when(redisTemplate.hasKey("login:locked:" + phone)).thenReturn(true);

        assertThrows(AccountLockedException.class, () -> {
            authService.login(phone, "Password123", "testDevice", "127.0.0.1", "TestAgent");
        });
    }

    @Test
    void testLogin_FifthFailedAttempt_LocksAccount() {
        String phone = "0987654321";
        String encoded = passwordEncoder.encode("correct_pass");
        User user = new User("u1", phone, encoded, null, null, null, null);

        when(redisTemplate.hasKey("login:locked:" + phone)).thenReturn(false);
        when(userPersistencePort.findUserByPhoneNumber(phone)).thenReturn(Optional.of(user));
        when(valueOperations.increment("login:attempts:" + phone)).thenReturn(5L);

        AccountLockedException ex = assertThrows(AccountLockedException.class, () -> {
            authService.login(phone, "WrongPass", "testDevice", "127.0.0.1", "TestAgent");
        });

        assertTrue(ex.getMessage().contains("tạm khóa 30 phút"));
        verify(valueOperations).set(eq("login:locked:" + phone), eq("LOCKED"), eq(Duration.ofMinutes(30)));
        verify(redisTemplate).delete("login:attempts:" + phone);
    }

    @Test
    void testLogin_Success_ClearsAttempts() {
        String phone = "0987654321";
        String pass = "correct_pass";
        String encoded = passwordEncoder.encode(pass);
        User user = new User("u1", phone, encoded, null, null, null, null);

        when(redisTemplate.hasKey("login:locked:" + phone)).thenReturn(false);
        when(userPersistencePort.findUserByPhoneNumber(phone)).thenReturn(Optional.of(user));

        com.fintech.wallet.domain.model.AuthTokens tokens = authService.login(phone, pass, "dev1", "127.0.0.1", "agent1");

        assertNotNull(tokens);
        assertNotNull(tokens.getAccessToken());
        verify(redisTemplate).delete("login:attempts:" + phone);
    }

    @Test
    void testLogout_BlacklistsToken() {
        String token = tokenProvider.generateAccessToken("u123", "0901234567", "dev1");

        authService.logout(token);

        verify(tokenBlacklistPort).blacklist(eq(token), anyLong());
    }


}
