package com.fintech.wallet;

import com.fintech.wallet.presentation.request.RegisterRequest;
import com.fintech.wallet.presentation.response.ApiResponse;
import com.fintech.wallet.presentation.response.AuthResponse;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

import org.springframework.test.context.ActiveProfiles;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
public class RegisterIntegrationTest {

    @Autowired
    private TestRestTemplate restTemplate;

    @Test
    public void testRegister() {
        RegisterRequest req = new RegisterRequest();
        req.setPhoneNumber("0988111333");
        req.setPassword("password123");
        req.setDeviceId("device-1");

        ResponseEntity<ApiResponse> response = restTemplate.postForEntity("/api/v1/auth/register", req, ApiResponse.class);
        
        System.out.println("RESPONSE STATUS: " + response.getStatusCode());
        System.out.println("RESPONSE BODY: " + response.getBody());
        
        assertEquals(HttpStatus.CREATED, response.getStatusCode());
    }
}
