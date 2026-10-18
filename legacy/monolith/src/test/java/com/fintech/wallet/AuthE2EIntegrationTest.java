package com.fintech.wallet;

import com.fintech.wallet.presentation.request.LoginRequest;
import com.fintech.wallet.presentation.request.RegisterRequest;
import com.fintech.wallet.presentation.response.ApiResponse;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.http.*;
import org.springframework.test.context.ActiveProfiles;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
public class AuthE2EIntegrationTest {

    @Autowired
    private TestRestTemplate restTemplate;

    @Autowired
    private ObjectMapper objectMapper;

    // Use the default secret from JwtTokenProvider
    private final String jwtSecret = "SuperSecretKeyForFintechWalletAppShouldBeAtLeast32BytesLong!";
    private final SecretKey secretKey = Keys.hmacShaKeyFor(jwtSecret.getBytes(StandardCharsets.UTF_8));

    @Test
    public void testFullAuthenticationLifecycle() throws Exception {
        String testPhone = "09" + (System.currentTimeMillis() % 100000000);
        String testPassword = "strongPassword123";
        String deviceId = "test-device-uuid-999";

        // ==========================================
        // 1. REGISTER NEW ACCOUNT
        // ==========================================
        RegisterRequest registerReq = new RegisterRequest();
        registerReq.setPhoneNumber(testPhone);
        registerReq.setPassword(testPassword);
        registerReq.setDeviceId(deviceId);
        registerReq.setFullName("Test User");

        ResponseEntity<ApiResponse> registerRes = restTemplate.postForEntity(
                "/api/v1/auth/register",
                registerReq,
                ApiResponse.class
        );
        assertEquals(HttpStatus.CREATED, registerRes.getStatusCode());

        // ==========================================
        // 2. SIMULATE FRONTEND SAVED ACCOUNT LOGIN
        // ==========================================
        LoginRequest loginReq = new LoginRequest();
        loginReq.setPhoneNumber(testPhone);
        loginReq.setPassword(testPassword); // User only enters password because FE saved phone
        loginReq.setDeviceId(deviceId);

        ResponseEntity<ApiResponse> loginRes = restTemplate.postForEntity(
                "/api/v1/auth/login",
                loginReq,
                ApiResponse.class
        );
        assertEquals(HttpStatus.OK, loginRes.getStatusCode());
        assertNotNull(loginRes.getBody());

        // Extract token
        Map<String, Object> data = (Map<String, Object>) loginRes.getBody().getData();
        String accessToken = (String) data.get("accessToken");
        assertNotNull(accessToken, "Access token should be returned");

        // ==========================================
        // 3. VERIFY 5-MINUTE TOKEN EXPIRATION
        // ==========================================
        Claims claims = Jwts.parser().verifyWith(secretKey).build().parseSignedClaims(accessToken).getPayload();
        
        Date iat = claims.getIssuedAt();
        Date exp = claims.getExpiration();
        assertNotNull(iat);
        assertNotNull(exp);

        long diffInSeconds = (exp.getTime() - iat.getTime()) / 1000;
        
        // Exact 5-minute timeout requirement
        assertEquals(300, diffInSeconds, "Access token must expire exactly in 5 minutes (300 seconds) to ensure security timeout!");
        assertEquals(testPhone, claims.get("phone", String.class));
        assertEquals(deviceId, claims.get("deviceId", String.class));

        // ==========================================
        // 4. TEST ACCESSING PROTECTED ENDPOINT
        // ==========================================
        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(accessToken);
        HttpEntity<Void> entity = new HttpEntity<>(headers);

        ResponseEntity<ApiResponse> profileRes = restTemplate.exchange(
                "/api/v1/users/me",
                HttpMethod.GET,
                entity,
                ApiResponse.class
        );
        assertEquals(HttpStatus.OK, profileRes.getStatusCode());
        
        // Verify 403 when missing token (Spring Security default for unauthenticated access to secured endpoint)
        ResponseEntity<ApiResponse> unauthorizedRes = restTemplate.exchange(
                "/api/v1/users/me",
                HttpMethod.GET,
                null,
                ApiResponse.class
        );
        assertEquals(HttpStatus.FORBIDDEN, unauthorizedRes.getStatusCode());
    }
}
