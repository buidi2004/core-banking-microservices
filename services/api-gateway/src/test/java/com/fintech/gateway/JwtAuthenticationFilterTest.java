package com.fintech.gateway;

import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.data.redis.core.ReactiveStringRedisTemplate;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.mock.http.server.reactive.MockServerHttpRequest;
import org.springframework.mock.web.server.MockServerWebExchange;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;
import reactor.test.StepVerifier;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Date;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class JwtAuthenticationFilterTest {

    private static final String SECRET = "SuperSecretKeyForFintechWalletAppShouldBeAtLeast32BytesLong!";
    private SecretKey secretKey;

    @Mock
    private ReactiveStringRedisTemplate redisTemplate;

    @Mock
    private GatewayFilterChain filterChain;

    private JwtAuthenticationFilter filter;

    @BeforeEach
    void setUp() {
        secretKey = Keys.hmacShaKeyFor(SECRET.getBytes(StandardCharsets.UTF_8));
        filter = new JwtAuthenticationFilter(SECRET, redisTemplate);
    }

    private String createToken(String userId, String phone, String role, String kycTier, String type, long expirySeconds) {
        Instant now = Instant.now();
        return Jwts.builder()
                .id(UUID.randomUUID().toString())
                .subject(userId)
                .claim("phone", phone)
                .claim("role", role)
                .claim("kycTier", kycTier)
                .claim("type", type)
                .issuedAt(Date.from(now))
                .expiration(Date.from(now.plusSeconds(expirySeconds)))
                .signWith(secretKey)
                .compact();
    }

    @Test
    @DisplayName("1. Token hợp lệ: trích xuất claims và inject header X-User-Id, X-User-Phone, X-User-Role, X-User-Kyc-Tier")
    void shouldExtractAndInjectHeadersWhenTokenIsValid() {
        String userId = "user-uuid-12345";
        String phone = "0987654321";
        String role = "ROLE_USER";
        String kycTier = "VERIFIED";
        String token = createToken(userId, phone, role, kycTier, "ACCESS", 3600);

        MockServerHttpRequest request = MockServerHttpRequest
                .get("/api/v1/users/me")
                .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                .build();
        MockServerWebExchange exchange = MockServerWebExchange.from(request);

        when(redisTemplate.hasKey(anyString())).thenReturn(Mono.just(false));
        when(filterChain.filter(any(ServerWebExchange.class))).thenReturn(Mono.empty());

        StepVerifier.create(filter.filter(exchange, filterChain))
                .verifyComplete();

        ArgumentCaptor<ServerWebExchange> captor = ArgumentCaptor.forClass(ServerWebExchange.class);
        verify(filterChain).filter(captor.capture());

        ServerWebExchange downstreamExchange = captor.getValue();
        HttpHeaders downstreamHeaders = downstreamExchange.getRequest().getHeaders();

        assertEquals(userId, downstreamHeaders.getFirst("X-User-Id"));
        assertEquals(phone, downstreamHeaders.getFirst("X-User-Phone"));
        assertEquals(kycTier, downstreamHeaders.getFirst("X-User-Kyc-Tier"));
        assertEquals(role, downstreamHeaders.getFirst("X-User-Role"));
        assertEquals(role, downstreamHeaders.getFirst("X-User-Roles"));
    }

    @Test
    @DisplayName("2. Gỡ bỏ (strip) header X-User-* giả mạo từ client để chống Spoofing")
    void shouldStripSpoofedHeadersFromClient() {
        String realUserId = "real-user-001";
        String token = createToken(realUserId, "0911222333", "ROLE_USER", "VERIFIED", "ACCESS", 3600);

        MockServerHttpRequest request = MockServerHttpRequest
                .get("/api/v1/users/profile")
                .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                .header("X-User-Id", "attacker-impersonated-id")
                .header("X-User-Role", "ROLE_ADMIN")
                .header("X-User-Roles", "ROLE_SUPERADMIN")
                .build();
        MockServerWebExchange exchange = MockServerWebExchange.from(request);

        when(redisTemplate.hasKey(anyString())).thenReturn(Mono.just(false));
        when(filterChain.filter(any(ServerWebExchange.class))).thenReturn(Mono.empty());

        StepVerifier.create(filter.filter(exchange, filterChain))
                .verifyComplete();

        ArgumentCaptor<ServerWebExchange> captor = ArgumentCaptor.forClass(ServerWebExchange.class);
        verify(filterChain).filter(captor.capture());

        HttpHeaders downstreamHeaders = captor.getValue().getRequest().getHeaders();
        assertEquals(realUserId, downstreamHeaders.getFirst("X-User-Id"), "Header X-User-Id phải là user thực trong token");
        assertEquals("ROLE_USER", downstreamHeaders.getFirst("X-User-Role"), "Header X-User-Role giả mạo phải bị gỡ bỏ");
        assertEquals("ROLE_USER", downstreamHeaders.getFirst("X-User-Roles"), "Header X-User-Roles giả mạo phải bị gỡ bỏ");
    }

    @Test
    @DisplayName("3. Từ chối 401 khi không có Authorization header trên protected route")
    void shouldReturn401WhenMissingAuthorizationHeader() {
        MockServerHttpRequest request = MockServerHttpRequest
                .get("/api/v1/users/me")
                .build();
        MockServerWebExchange exchange = MockServerWebExchange.from(request);

        StepVerifier.create(filter.filter(exchange, filterChain))
                .verifyComplete();

        assertEquals(HttpStatus.UNAUTHORIZED, exchange.getResponse().getStatusCode());
        verify(filterChain, never()).filter(any());
    }

    @Test
    @DisplayName("4. Cho phép bypass trên các public path (/api/v1/auth/**, /actuator/health)")
    void shouldBypassPublicPathsWithoutToken() {
        MockServerHttpRequest request = MockServerHttpRequest
                .post("/api/v1/auth/login")
                .header("X-User-Id", "spoofed-user") // Thử gửi spoof header
                .build();
        MockServerWebExchange exchange = MockServerWebExchange.from(request);

        when(filterChain.filter(any(ServerWebExchange.class))).thenReturn(Mono.empty());

        StepVerifier.create(filter.filter(exchange, filterChain))
                .verifyComplete();

        ArgumentCaptor<ServerWebExchange> captor = ArgumentCaptor.forClass(ServerWebExchange.class);
        verify(filterChain).filter(captor.capture());

        // Header giả mạo vẫn bị xóa
        assertNull(captor.getValue().getRequest().getHeaders().getFirst("X-User-Id"));
    }

    @Test
    @DisplayName("5. Từ chối 401 khi token bị blacklist trong Redis (đã logout)")
    void shouldReturn401WhenTokenIsBlacklisted() {
        String token = createToken("user-logged-out", "0900000000", "ROLE_USER", "VERIFIED", "ACCESS", 3600);

        MockServerHttpRequest request = MockServerHttpRequest
                .get("/api/v1/users/me")
                .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                .build();
        MockServerWebExchange exchange = MockServerWebExchange.from(request);

        // Redis báo token đang nằm trong blacklist
        when(redisTemplate.hasKey(anyString())).thenReturn(Mono.just(true));

        StepVerifier.create(filter.filter(exchange, filterChain))
                .verifyComplete();

        assertEquals(HttpStatus.UNAUTHORIZED, exchange.getResponse().getStatusCode());
        verify(filterChain, never()).filter(any());
    }

    @Test
    @DisplayName("6. Từ chối 401 khi token sai chữ ký HMAC")
    void shouldReturn401WhenSignatureIsInvalid() {
        SecretKey otherKey = Keys.hmacShaKeyFor("AnotherDifferentSecretKeyThatDoesNotMatch32Bytes!".getBytes(StandardCharsets.UTF_8));
        String tamperedToken = Jwts.builder()
                .subject("tampered-user")
                .claim("type", "ACCESS")
                .expiration(new Date(System.currentTimeMillis() + 3600000))
                .signWith(otherKey)
                .compact();

        MockServerHttpRequest request = MockServerHttpRequest
                .get("/api/v1/users/me")
                .header(HttpHeaders.AUTHORIZATION, "Bearer " + tamperedToken)
                .build();
        MockServerWebExchange exchange = MockServerWebExchange.from(request);

        StepVerifier.create(filter.filter(exchange, filterChain))
                .verifyComplete();

        assertEquals(HttpStatus.UNAUTHORIZED, exchange.getResponse().getStatusCode());
        verify(filterChain, never()).filter(any());
    }

    @Test
    @DisplayName("7. Từ chối 401 khi type token là REFRESH thay vì ACCESS")
    void shouldReturn401WhenTokenTypeIsNotAccess() {
        String refreshToken = createToken("user-refresh", "0912345678", "ROLE_USER", "VERIFIED", "REFRESH", 86400);

        MockServerHttpRequest request = MockServerHttpRequest
                .get("/api/v1/users/me")
                .header(HttpHeaders.AUTHORIZATION, "Bearer " + refreshToken)
                .build();
        MockServerWebExchange exchange = MockServerWebExchange.from(request);

        StepVerifier.create(filter.filter(exchange, filterChain))
                .verifyComplete();

        assertEquals(HttpStatus.UNAUTHORIZED, exchange.getResponse().getStatusCode());
        verify(filterChain, never()).filter(any());
    }

    @Test
    @DisplayName("8. Forward header X-Branch-Id từ client request và inject X-User-Roles")
    void shouldForwardBranchIdAndUserRoles() {
        String userId = "teller-001";
        String token = createToken(userId, "0911222333", "ROLE_TELLER", "VERIFIED", "ACCESS", 3600);

        MockServerHttpRequest request = MockServerHttpRequest
                .get("/api/v1/cash/deposit")
                .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                .header("X-Branch-Id", "BRANCH_HN_01")
                .build();
        MockServerWebExchange exchange = MockServerWebExchange.from(request);

        when(redisTemplate.hasKey(anyString())).thenReturn(Mono.just(false));
        when(filterChain.filter(any(ServerWebExchange.class))).thenReturn(Mono.empty());

        StepVerifier.create(filter.filter(exchange, filterChain))
                .verifyComplete();

        ArgumentCaptor<ServerWebExchange> captor = ArgumentCaptor.forClass(ServerWebExchange.class);
        verify(filterChain).filter(captor.capture());

        HttpHeaders downstreamHeaders = captor.getValue().getRequest().getHeaders();
        assertEquals(userId, downstreamHeaders.getFirst("X-User-Id"));
        assertEquals("ROLE_TELLER", downstreamHeaders.getFirst("X-User-Roles"));
        assertEquals("BRANCH_HN_01", downstreamHeaders.getFirst("X-Branch-Id"), "Header X-Branch-Id phải được forward xuống downstream");
    }
}
