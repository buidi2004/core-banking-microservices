package com.fintech.gateway;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.core.Ordered;
import org.springframework.core.io.buffer.DataBuffer;
import org.springframework.data.redis.core.ReactiveStringRedisTemplate;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.server.reactive.ServerHttpRequest;
import org.springframework.http.server.reactive.ServerHttpResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.List;

/**
 * Global filter xác thực JWT tập trung tại API Gateway (Giai đoạn 3 kiến trúc).
 *
 * Trách nhiệm:
 *  1. Bắt buộc携带 Authorization: Bearer <JWT> trên mọi route /api/v1/**.
 *  2. Kiểm tra chữ ký JWT (HMAC-SHA với secret chung Identity Service).
 *  3. Chỉ chấp nhận token type = ACCESS.
 *  4. Tra cứu Redis blacklist: identity:blacklist:{jti|token-hash} (vừa logout).
 *  5. Inject header tin cậy xuống downstream microservices:
 *       X-User-Id, X-User-Phone, X-User-Kyc-Tier, X-User-Role
 *  6. Strip mọi header X-User-* giả mạo từ client trước khi xử lý.
 *
 * Downstream services KHÔNG parse JWT - chỉ đọc header X-User-Id.
 */
@Component
public class JwtAuthenticationFilter implements GlobalFilter, Ordered {

    private static final Logger log = LoggerFactory.getLogger(JwtAuthenticationFilter.class);

    public static final String HEADER_USER_ID = "X-User-Id";
    public static final String HEADER_USER_PHONE = "X-User-Phone";
    public static final String HEADER_USER_KYC_TIER = "X-User-Kyc-Tier";
    public static final String HEADER_USER_ROLE = "X-User-Role";
    public static final String HEADER_USER_ROLES = "X-User-Roles";
    public static final String HEADER_BRANCH_ID = "X-Branch-Id";

    private static final String BLACKLIST_KEY_PREFIX = "identity:blacklist:";
    private static final String TOKEN_TYPE_ACCESS = "ACCESS";
    private static final String DEFAULT_KYC_TIER = "VERIFIED";
    private static final String DEFAULT_ROLE = "ROLE_USER";

    /** Các route được phép truy cập không cần JWT (health, auth login/register...). */
    private static final List<String> PUBLIC_PATH_PREFIXES = List.of(
            "/api/v1/auth/",
            "/actuator/health",
            "/fallback/",
            "/ws",
            "/ws-native"
    );

    private final SecretKey secretKey;
    private final ReactiveStringRedisTemplate redisTemplate;

    public JwtAuthenticationFilter(
            @Value("${wallet.jwt.secret:SuperSecretKeyForFintechWalletAppShouldBeAtLeast32BytesLong!}") String secret,
            ReactiveStringRedisTemplate redisTemplate) {
        this.secretKey = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        this.redisTemplate = redisTemplate;
    }

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        ServerHttpRequest request = exchange.getRequest();
        String path = request.getURI().getPath();

        // Bước 0: Strip header X-User-* giả mạo từ client (chống spoofing)
        ServerHttpRequest sanitizedRequest = request.mutate()
                .headers(headers -> {
                    headers.remove(HEADER_USER_ID);
                    headers.remove(HEADER_USER_PHONE);
                    headers.remove(HEADER_USER_KYC_TIER);
                    headers.remove(HEADER_USER_ROLE);
                    headers.remove(HEADER_USER_ROLES);
                })
                .build();

        if (isPublicPath(path)) {
            return chain.filter(exchange.mutate().request(sanitizedRequest).build());
        }

        String bearerToken = extractBearerToken(sanitizedRequest);
        if (bearerToken == null) {
            return unauthorized(exchange, "Missing Authorization: Bearer <JWT>");
        }

        // Bước 1: Kiểm tra chữ ký + hạn sử dụng + type = ACCESS
        Claims claims;
        try {
            claims = Jwts.parser()
                    .verifyWith(secretKey)
                    .build()
                    .parseSignedClaims(bearerToken)
                    .getPayload();
        } catch (JwtException | IllegalArgumentException e) {
            log.warn("Gateway JWT invalid: {}", e.getMessage());
            return unauthorized(exchange, "Invalid or expired JWT");
        }

        String tokenType = claims.get("type", String.class);
        if (!TOKEN_TYPE_ACCESS.equals(tokenType)) {
            return unauthorized(exchange, "Token type must be ACCESS");
        }

        String userId = claims.getSubject();
        if (userId == null || userId.isBlank()) {
            return unauthorized(exchange, "JWT missing subject (user id)");
        }

        String phone = claims.get("phone", String.class);
        String kycTier = claims.get("kycTier", String.class);
        String role = claims.get("role", String.class);
        Object rolesClaim = claims.get("roles");
        String userRoles;
        if (rolesClaim instanceof List<?> list) {
            userRoles = String.join(",", list.stream().map(Object::toString).toList());
        } else if (rolesClaim instanceof String str && !str.isBlank()) {
            userRoles = str;
        } else {
            userRoles = role != null ? role : DEFAULT_ROLE;
        }
        if (role == null) {
            role = userRoles;
        }

        String branchIdClaim = claims.get("branchId", String.class);
        if (branchIdClaim == null) {
            branchIdClaim = claims.get("branch_id", String.class);
        }

        String jti = claims.getId();
        // Fallback: hash token nếu không có jti (tương thích token phát hành trước Giai đoạn 3)
        String blacklistKey = BLACKLIST_KEY_PREFIX + (jti != null ? jti : Integer.toHexString(bearerToken.hashCode()));

        // Bước 2: Kiểm tra Redis blacklist (token vừa logout) - fail-closed nếu Redis lỗi
        String finalRole = role;
        String finalBranchIdClaim = branchIdClaim;
        return redisTemplate.hasKey(blacklistKey)
                .defaultIfEmpty(Boolean.FALSE)
                .onErrorResume(e -> {
                    log.error("Redis blacklist check failed, rejecting request: {}", e.getMessage());
                    return Mono.just(Boolean.TRUE); // fail-closed: coi như blacklisted
                })
                .flatMap(isBlacklisted -> {
                    if (Boolean.TRUE.equals(isBlacklisted)) {
                        log.warn("Gateway rejected blacklisted token for user {}", userId);
                        return unauthorized(exchange, "Token has been revoked (logout)");
                    }

                    // Bước 3: Inject header tin cậy xuống downstream microservices
                    var requestMutator = sanitizedRequest.mutate()
                            .header(HEADER_USER_ID, userId)
                            .header(HEADER_USER_PHONE, phone != null ? phone : "")
                            .header(HEADER_USER_KYC_TIER, kycTier != null ? kycTier : DEFAULT_KYC_TIER)
                            .header(HEADER_USER_ROLE, finalRole)
                            .header(HEADER_USER_ROLES, userRoles);

                    if (finalBranchIdClaim != null && !finalBranchIdClaim.isBlank()
                            && sanitizedRequest.getHeaders().getFirst(HEADER_BRANCH_ID) == null) {
                        requestMutator.header(HEADER_BRANCH_ID, finalBranchIdClaim);
                    }

                    ServerHttpRequest authenticatedRequest = requestMutator.build();

                    log.debug("Gateway authenticated user={} path={} -> injecting trusted headers", userId, path);
                    return chain.filter(exchange.mutate().request(authenticatedRequest).build());
                });
    }

    private boolean isPublicPath(String path) {
        return PUBLIC_PATH_PREFIXES.stream().anyMatch(path::startsWith);
    }

    private String extractBearerToken(ServerHttpRequest request) {
        String header = request.getHeaders().getFirst(HttpHeaders.AUTHORIZATION);
        if (header != null && header.startsWith("Bearer ")) {
            return header.substring(7);
        }
        return null;
    }

    private Mono<Void> unauthorized(ServerWebExchange exchange, String message) {
        ServerHttpResponse response = exchange.getResponse();
        response.setStatusCode(HttpStatusCode.valueOf(401));
        response.getHeaders().set("Content-Type", "application/json;charset=UTF-8");
        String body = "{\"success\":false,\"error\":\"UNAUTHORIZED\",\"message\":\"" + message + "\"}";
        DataBuffer buffer = response.bufferFactory().wrap(body.getBytes(StandardCharsets.UTF_8));
        return response.writeWith(Mono.just(buffer));
    }

    @Override
    public int getOrder() {
        // Chạy trước RouteToRequestUrlFilter (order 10000)
        return -100;
    }
}
