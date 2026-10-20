package com.fintech.payment.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;

@Slf4j
@Component
public class PinTokenValidator {

    private final SecretKey secretKey;

    public PinTokenValidator(
            @Value("${wallet.jwt.secret:SuperSecretKeyForFintechWalletAppShouldBeAtLeast32BytesLong!}") String secret) {
        this.secretKey = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
    }

    public boolean validatePinToken(String pinToken, String expectedUserId) {
        if (pinToken == null || pinToken.isBlank() || expectedUserId == null || expectedUserId.isBlank()) {
            return false;
        }

        try {
            Claims claims = Jwts.parser()
                    .verifyWith(secretKey)
                    .build()
                    .parseSignedClaims(pinToken)
                    .getPayload();

            boolean isPinType = "PIN_TOKEN".equals(claims.get("type"));
            boolean isTransactionScope = "TRANSACTION_AUTH".equals(claims.get("scope"));
            boolean isUserMatch = expectedUserId.equals(claims.getSubject());

            if (!isPinType || !isTransactionScope || !isUserMatch) {
                log.warn("PinToken không hợp lệ: isPinType={}, isTransactionScope={}, isUserMatch={}",
                        isPinType, isTransactionScope, isUserMatch);
                return false;
            }

            return true;
        } catch (JwtException | IllegalArgumentException e) {
            log.warn("Lỗi xác thực pinToken: {}", e.getMessage());
            return false;
        }
    }

    public void validate(String userId, String pinToken) {
        if (!validatePinToken(pinToken, userId)) {
            throw new IllegalArgumentException("Mã PIN không hợp lệ hoặc đã hết hạn xác thực");
        }
    }
}

