package com.fintech.identity.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fintech.identity.security.JwtTokenProvider;
import com.fintech.identity.service.AuthService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Map;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(controllers = SecurityBiometricController.class)
@AutoConfigureMockMvc(addFilters = false)
class SecurityBiometricControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private JwtTokenProvider jwtTokenProvider;

    @MockBean
    private AuthService authService;

    private final String userId = UUID.randomUUID().toString();

    @Test
    @DisplayName("POST /api/v1/security/biometric/verify: Xác thực sinh trắc học thiết bị và cấp PinToken")
    void verifyBiometric_Success() throws Exception {
        when(jwtTokenProvider.generateBiometricToken(userId)).thenReturn("mock-pin-jwt-token-12345");

        mockMvc.perform(post("/api/v1/security/biometric/verify")
                        .header("X-User-Id", userId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("signature", "bio-sig-abc"))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.pinToken").value("mock-pin-jwt-token-12345"));
    }

    @Test
    @DisplayName("POST /api/v1/security/emergency-lock: Khóa khẩn cấp tài khoản an toàn")
    void emergencyLock_Success() throws Exception {
        when(authService.emergencyLock(any(), eq(userId), any())).thenReturn(Map.of("status", "BLOCKED"));

        mockMvc.perform(post("/api/v1/security/emergency-lock")
                        .header("X-User-Id", userId)
                        .header("Authorization", "Bearer test-token")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("reason", "Nghi lừa đảo"))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.status").value("BLOCKED"));
    }
}

