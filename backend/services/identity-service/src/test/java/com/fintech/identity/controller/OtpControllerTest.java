package com.fintech.identity.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fintech.identity.dto.*;
import com.fintech.identity.service.OtpService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(AuthController.class)
@AutoConfigureMockMvc(addFilters = false)
class OtpControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private com.fintech.identity.service.AuthService authService;

    @MockBean
    private OtpService otpService;

    @Test
    @DisplayName("POST /api/v1/auth/otp/send: Gửi OTP thành công")
    void sendOtp_Success() throws Exception {
        OtpSendRequest req = OtpSendRequest.builder()
                .phoneNumber("0987654321")
                .purpose("FORGOT_PASSWORD")
                .build();

        OtpSendResponse resp = OtpSendResponse.builder()
                .phoneNumber("0987654321")
                .expiresInSeconds(180)
                .referenceId("REF-123")
                .message("Mã OTP đã được gửi")
                .build();

        when(otpService.sendOtp(eq("0987654321"), eq("FORGOT_PASSWORD"))).thenReturn(resp);

        mockMvc.perform(post("/api/v1/auth/otp/send")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.phoneNumber").value("0987654321"))
                .andExpect(jsonPath("$.data.expiresInSeconds").value(180));
    }

    @Test
    @DisplayName("POST /api/v1/auth/otp/verify: Xác thực OTP thành công nhận token")
    void verifyOtp_Success() throws Exception {
        OtpVerifyRequest req = OtpVerifyRequest.builder()
                .phoneNumber("0987654321")
                .code("123456")
                .purpose("FORGOT_PASSWORD")
                .build();

        OtpVerifyResponse resp = OtpVerifyResponse.builder()
                .phoneNumber("0987654321")
                .verified(true)
                .otpToken("jwt-otp-token")
                .message("Xác thực thành công")
                .build();

        when(otpService.verifyOtp(eq("0987654321"), eq("123456"), eq("FORGOT_PASSWORD"))).thenReturn(resp);

        mockMvc.perform(post("/api/v1/auth/otp/verify")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.verified").value(true))
                .andExpect(jsonPath("$.data.otpToken").value("jwt-otp-token"));
    }

    @Test
    @DisplayName("POST /api/v1/auth/forgot-password: Yêu cầu quên mật khẩu thành công")
    void forgotPassword_Success() throws Exception {
        ForgotPasswordRequest req = ForgotPasswordRequest.builder()
                .phoneNumber("0987654321")
                .build();

        OtpSendResponse resp = OtpSendResponse.builder()
                .phoneNumber("0987654321")
                .expiresInSeconds(180)
                .referenceId("REF-999")
                .message("Mã OTP đã được gửi đến số điện thoại của bạn")
                .build();

        when(otpService.forgotPassword(eq("0987654321"))).thenReturn(resp);

        mockMvc.perform(post("/api/v1/auth/forgot-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.phoneNumber").value("0987654321"));
    }

    @Test
    @DisplayName("POST /api/v1/auth/reset-password: Đặt lại mật khẩu thành công")
    void resetPassword_Success() throws Exception {
        ResetPasswordRequest req = ResetPasswordRequest.builder()
                .phoneNumber("0987654321")
                .otpToken("valid-token")
                .newPassword("Password@2026")
                .build();

        doNothing().when(otpService).resetPassword(eq("0987654321"), eq("valid-token"), eq("Password@2026"));

        mockMvc.perform(post("/api/v1/auth/reset-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }
}

