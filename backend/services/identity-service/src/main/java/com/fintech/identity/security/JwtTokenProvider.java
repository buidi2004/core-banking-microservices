package com.fintech.identity.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.Instant;
import java.util.Date;
import java.util.UUID;

@Slf4j
@Component
public class JwtTokenProvider {

    private final SecretKey secretKey;
    private final long accessTokenExpirationSeconds;
    private final long refreshTokenExpirationSeconds;
    private final StringRedisTemplate redisTemplate;

    public static final String TOKEN_TYPE_ACCESS = "ACCESS";
    public static final String TOKEN_TYPE_REFRESH = "REFRESH";
    private static final String BLACKLIST_KEY_PREFIX = "identity:blacklist:";

    public JwtTokenProvider(
            @Value("${wallet.jwt.secret:SuperSecretKeyForFintechWalletAppShouldBeAtLeast32BytesLong!}") String secret,
            @Value("${wallet.jwt.access-token-expiration-seconds:3600}") long accessTokenExpirationSeconds,
            @Value("${wallet.jwt.refresh-token-expiration-seconds:604800}") long refreshTokenExpirationSeconds,
            StringRedisTemplate redisTemplate) {
        this.secretKey = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        this.accessTokenExpirationSeconds = accessTokenExpirationSeconds;
        this.refreshTokenExpirationSeconds = refreshTokenExpirationSeconds;
        this.redisTemplate = redisTemplate;
    }

    public String generateAccessToken(String userId, String phoneNumber, String role, String kycTier) {
        return generateAccessToken(userId, phoneNumber, role, kycTier, "BR_MAIN", null);
    }

    public String generateAccessToken(String userId, String phoneNumber, String role, String kycTier, String branchId, String fullName) {
        Instant now = Instant.now();
        Instant expiry = now.plusSeconds(accessTokenExpirationSeconds);
        String jti = UUID.randomUUID().toString();

        String resolvedRole = (role != null && !role.isBlank()) ? role : "ROLE_USER";
        String resolvedBranchId = (branchId != null && !branchId.isBlank()) ? branchId : "BR_MAIN";
        java.util.List<String> rolesList = java.util.List.of(resolvedRole);

        var builder = Jwts.builder()
                .id(jti)
                .subject(userId)
                .claim("phone", phoneNumber)
                .claim("role", resolvedRole)
                .claim("roles", rolesList)
                .claim("kycTier", kycTier != null ? kycTier : "UNVERIFIED")
                .claim("branch_id", resolvedBranchId)
                .claim("branchId", resolvedBranchId)
                .claim("type", TOKEN_TYPE_ACCESS);

        if (fullName != null && !fullName.isBlank()) {
            builder.claim("full_name", fullName)
                   .claim("name", fullName);
        }

        return builder
                .issuedAt(Date.from(now))
                .expiration(Date.from(expiry))
                .signWith(secretKey)
                .compact();
    }

    public String generateRefreshToken(String userId) {
        Instant now = Instant.now();
        Instant expiry = now.plusSeconds(refreshTokenExpirationSeconds);
        String jti = UUID.randomUUID().toString();

        return Jwts.builder()
                .id(jti)
                .subject(userId)
                .claim("type", TOKEN_TYPE_REFRESH)
                .issuedAt(Date.from(now))
                .expiration(Date.from(expiry))
                .signWith(secretKey)
                .compact();
    }

    public String generatePinToken(String userId) {
        Instant now = Instant.now();
        Instant expiry = now.plusSeconds(300); // Có hiệu lực trong 5 phút
        String jti = UUID.randomUUID().toString();

        return Jwts.builder()
                .id(jti)
                .subject(userId)
                .claim("type", "PIN_TOKEN")
                .claim("scope", "TRANSACTION_AUTH")
                .issuedAt(Date.from(now))
                .expiration(Date.from(expiry))
                .signWith(secretKey)
                .compact();
    }

    public String generateOtpToken(String phoneNumber, String purpose) {
        Instant now = Instant.now();
        Instant expiry = now.plusSeconds(600); // 10 phút
        String jti = UUID.randomUUID().toString();

        return Jwts.builder()
                .id(jti)
                .subject(phoneNumber)
                .claim("type", "OTP_TOKEN")
                .claim("purpose", purpose)
                .issuedAt(Date.from(now))
                .expiration(Date.from(expiry))
                .signWith(secretKey)
                .compact();
    }

    public boolean validateOtpToken(String token, String expectedPhone, String expectedPurpose) {
        if (token == null || token.isBlank()) return false;
        try {
            Claims claims = Jwts.parser()
                    .verifyWith(secretKey)
                    .build()
                    .parseSignedClaims(token)
                    .getPayload();

            String jti = claims.getId();
            if (isBlacklisted(jti, token)) {
                return false;
            }

            return "OTP_TOKEN".equals(claims.get("type"))
                    && expectedPhone.equals(claims.getSubject())
                    && expectedPurpose.equals(claims.get("purpose"));
        } catch (Exception e) {
            log.warn("Mã xác thực OTP token không hợp lệ: {}", e.getMessage());
            return false;
        }
    }

    public Claims parseAndValidateToken(String token) {
        try {
            Claims claims = Jwts.parser()
                    .verifyWith(secretKey)
                    .build()
                    .parseSignedClaims(token)
                    .getPayload();

            String jti = claims.getId();
            if (isBlacklisted(jti, token)) {
                throw new JwtException("Token đã bị thu hồi (đăng xuất)");
            }
            return claims;
        } catch (JwtException | IllegalArgumentException e) {
            log.warn("Token không hợp lệ hoặc hết hạn: {}", e.getMessage());
            throw e;
        }
    }

    public void blacklistToken(String token) {
        try {
            Claims claims = Jwts.parser()
                    .verifyWith(secretKey)
                    .build()
                    .parseSignedClaims(token)
                    .getPayload();

            String jti = claims.getId();
            Date expiration = claims.getExpiration();
            long remainingSeconds = (expiration.getTime() - System.currentTimeMillis()) / 1000;

            if (remainingSeconds > 0) {
                String key = BLACKLIST_KEY_PREFIX + (jti != null ? jti : Integer.toHexString(token.hashCode()));
                redisTemplate.opsForValue().set(key, "REVOKED", Duration.ofSeconds(remainingSeconds));
                log.info("Đã đưa token jti={} vào Redis Blacklist trong {} giây", jti, remainingSeconds);
            }
        } catch (Exception e) {
            log.error("Không thể blacklist token: {}", e.getMessage());
        }
    }

    public boolean isBlacklisted(String jti, String token) {
        String key = BLACKLIST_KEY_PREFIX + (jti != null ? jti : Integer.toHexString(token.hashCode()));
        return Boolean.TRUE.equals(redisTemplate.hasKey(key));
    }

    public long getAccessTokenExpirationSeconds() {
        return accessTokenExpirationSeconds;
    }
}
