package com.fintech.wallet;

import com.fintech.wallet.presentation.request.LoginRequest;
import com.fintech.wallet.presentation.request.RegisterRequest;
import com.fintech.wallet.presentation.response.ApiResponse;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.springframework.test.context.ActiveProfiles;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
public class LoginIntegrationTest {

    @Autowired
    private TestRestTemplate restTemplate;

    @Test
    public void testLogin() {
        // Register
        RegisterRequest req = new RegisterRequest();
        req.setPhoneNumber("0988111444");
        req.setPassword("password123");
        req.setDeviceId("device-1");
        ResponseEntity<ApiResponse> response = restTemplate.postForEntity("/api/v1/auth/register", req, ApiResponse.class);
        assertEquals(HttpStatus.CREATED, response.getStatusCode());

        // Login
        LoginRequest loginReq = new LoginRequest();
        loginReq.setPhoneNumber("0988111444");
        loginReq.setPassword("password123");
        loginReq.setDeviceId("device-1");

        ResponseEntity<ApiResponse> loginResponse = restTemplate.postForEntity("/api/v1/auth/login", loginReq, ApiResponse.class);
        System.out.println("LOGIN RESPONSE STATUS: " + loginResponse.getStatusCode());
        System.out.println("LOGIN RESPONSE BODY: " + loginResponse.getBody());
        assertEquals(HttpStatus.OK, loginResponse.getStatusCode());
    }
}
