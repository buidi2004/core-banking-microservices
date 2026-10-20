package com.fintech.payment.security;

import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Date;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class PinTokenValidatorTest {

    private static final String SECRET = "SuperSecretKeyForFintechWalletAppShouldBeAtLeast32BytesLong!";
    private PinTokenValidator validator;
    private SecretKey secretKey;

    @BeforeEach
    void setUp() {
        secretKey = Keys.hmacShaKeyFor(SECRET.getBytes(StandardCharsets.UTF_8));
        validator = new PinTokenValidator(SECRET);
    }

    private String createToken(String userId, String type, String scope, Instant expiry) {
        return Jwts.builder()
                .id(UUID.randomUUID().toString())
                .subject(userId)
                .claim("type", type)
                .claim("scope", scope)
                .issuedAt(Date.from(Instant.now()))
                .expiration(Date.from(expiry))
                .signWith(secretKey)
                .compact();
    }

    @Test
    @DisplayName("PinToken hợp lệ: đúng userId, type=PIN_TOKEN, scope=TRANSACTION_AUTH và chưa hết hạn -> true")
    void validPinToken_ShouldReturnTrue() {
        String token = createToken("user-123", "PIN_TOKEN", "TRANSACTION_AUTH", Instant.now().plusSeconds(300));
        boolean isValid = validator.validatePinToken(token, "user-123");
        assertThat(isValid).isTrue();
    }

    @Test
    @DisplayName("PinToken sai userId -> false")
    void wrongUserId_ShouldReturnFalse() {
        String token = createToken("user-999", "PIN_TOKEN", "TRANSACTION_AUTH", Instant.now().plusSeconds(300));
        boolean isValid = validator.validatePinToken(token, "user-123");
        assertThat(isValid).isFalse();
    }

    @Test
    @DisplayName("PinToken hết hạn -> false")
    void expiredPinToken_ShouldReturnFalse() {
        String token = createToken("user-123", "PIN_TOKEN", "TRANSACTION_AUTH", Instant.now().minusSeconds(10));
        boolean isValid = validator.validatePinToken(token, "user-123");
        assertThat(isValid).isFalse();
    }

    @Test
    @DisplayName("PinToken sai scope hoặc type -> false")
    void wrongScopeOrType_ShouldReturnFalse() {
        String wrongType = createToken("user-123", "ACCESS", "TRANSACTION_AUTH", Instant.now().plusSeconds(300));
        assertThat(validator.validatePinToken(wrongType, "user-123")).isFalse();

        String wrongScope = createToken("user-123", "PIN_TOKEN", "USER_PROFILE", Instant.now().plusSeconds(300));
        assertThat(validator.validatePinToken(wrongScope, "user-123")).isFalse();
    }

    @Test
    @DisplayName("Token null hoặc chuỗi rác -> false")
    void invalidTokenString_ShouldReturnFalse() {
        assertThat(validator.validatePinToken(null, "user-123")).isFalse();
        assertThat(validator.validatePinToken("", "user-123")).isFalse();
        assertThat(validator.validatePinToken("not-a-valid-jwt-token", "user-123")).isFalse();
    }
}

