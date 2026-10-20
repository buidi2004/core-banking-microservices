package com.fintech.identity.security;

import io.jsonwebtoken.Claims;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ValueOperations;

import java.time.Duration;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class JwtTokenProviderTest {

    private static final String SECRET = "SuperSecretKeyForFintechWalletAppShouldBeAtLeast32BytesLong!";
    private static final long ACCESS_EXPIRATION = 3600L;
    private static final long REFRESH_EXPIRATION = 604800L;

    @Mock
    private StringRedisTemplate redisTemplate;

    @Mock
    private ValueOperations<String, String> valueOperations;

    private JwtTokenProvider tokenProvider;

    @BeforeEach
    void setUp() {
        tokenProvider = new JwtTokenProvider(SECRET, ACCESS_EXPIRATION, REFRESH_EXPIRATION, redisTemplate);
    }

    @Test
    @DisplayName("Sinh JWT Access Token đầy đủ claims (sub, phone, role, kycTier, type=ACCESS)")
    void shouldGenerateValidAccessToken() {
        String userId = "usr-001";
        String phone = "0987654321";
        String role = "ROLE_USER";
        String kycTier = "VERIFIED";

        when(redisTemplate.hasKey(anyString())).thenReturn(false);

        String token = tokenProvider.generateAccessToken(userId, phone, role, kycTier);
        assertNotNull(token);

        Claims claims = tokenProvider.parseAndValidateToken(token);
        assertEquals(userId, claims.getSubject());
        assertEquals(phone, claims.get("phone", String.class));
        assertEquals(role, claims.get("role", String.class));
        assertEquals(kycTier, claims.get("kycTier", String.class));
        assertEquals(JwtTokenProvider.TOKEN_TYPE_ACCESS, claims.get("type", String.class));
        assertNotNull(claims.getId()); // jti
    }

    @Test
    @DisplayName("Sinh JWT Access Token cho cán bộ chứa đầy đủ roles, branch_id, full_name")
    void shouldGenerateValidStaffAccessTokenWithRolesBranchIdAndFullName() {
        String userId = "t0000001-0000-0000-0000-000000000001";
        String phone = "0911000001";
        String role = "ROLE_TELLER";
        String kycTier = "VERIFIED";
        String branchId = "BR_Q1";
        String fullName = "Teller Nguyễn Văn A";

        when(redisTemplate.hasKey(anyString())).thenReturn(false);

        String token = tokenProvider.generateAccessToken(userId, phone, role, kycTier, branchId, fullName);
        assertNotNull(token);

        Claims claims = tokenProvider.parseAndValidateToken(token);
        assertEquals(userId, claims.getSubject());
        assertEquals(phone, claims.get("phone", String.class));
        assertEquals(role, claims.get("role", String.class));
        assertEquals("BR_Q1", claims.get("branch_id", String.class));
        assertEquals("BR_Q1", claims.get("branchId", String.class));
        assertEquals("Teller Nguyễn Văn A", claims.get("full_name", String.class));
        assertEquals("Teller Nguyễn Văn A", claims.get("name", String.class));

        @SuppressWarnings("unchecked")
        java.util.List<String> roles = claims.get("roles", java.util.List.class);
        assertNotNull(roles);
        assertTrue(roles.contains("ROLE_TELLER"));
    }

    @Test
    @DisplayName("Sinh JWT Refresh Token với type=REFRESH")
    void shouldGenerateValidRefreshToken() {
        String userId = "usr-002";
        when(redisTemplate.hasKey(anyString())).thenReturn(false);

        String token = tokenProvider.generateRefreshToken(userId);
        assertNotNull(token);

        Claims claims = tokenProvider.parseAndValidateToken(token);
        assertEquals(userId, claims.getSubject());
        assertEquals(JwtTokenProvider.TOKEN_TYPE_REFRESH, claims.get("type", String.class));
    }

    @Test
    @DisplayName("Đưa token vào Redis Blacklist khi logout")
    void shouldBlacklistTokenInRedis() {
        when(redisTemplate.opsForValue()).thenReturn(valueOperations);

        String token = tokenProvider.generateAccessToken("usr-003", "0900000000", "ROLE_USER", "UNVERIFIED");
        tokenProvider.blacklistToken(token);

        verify(valueOperations, times(1)).set(
                startsWith("identity:blacklist:"),
                eq("REVOKED"),
                any(Duration.class)
        );
    }
}
