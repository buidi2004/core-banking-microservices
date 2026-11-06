package com.fintech.identity.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fintech.identity.dto.AuthResponse;
import com.fintech.identity.dto.ForgotPasswordRequest;
import com.fintech.identity.dto.LoginRequest;
import com.fintech.identity.dto.OtpSendResponse;
import com.fintech.identity.dto.RefreshTokenRequest;
import com.fintech.identity.dto.RegisterRequest;
import com.fintech.identity.service.AuthService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.is;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(controllers = AuthController.class)
@AutoConfigureMockMvc(addFilters = false) // Bypass security filter trong Controller slice test
class AuthControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private AuthService authService;

    @MockBean
    private com.fintech.identity.service.OtpService otpService;

    @MockBean
    private com.fintech.identity.repository.UserRepository userRepository;

    @Test
    @DisplayName("API POST /api/v1/auth/register - Đăng ký thành công trả về HTTP 201 Created")
    void shouldReturn201WhenRegisterSuccessfully() throws Exception {
        RegisterRequest request = RegisterRequest.builder()
                .phoneNumber("0987654321")
                .fullName("Nguyen Van A")
                .password("Password123")
                .email("nguyen@gmail.com")
                .build();

        AuthResponse mockResponse = AuthResponse.builder()
                .token("mock-jwt-token")
                .refreshToken("mock-refresh-token")
                .tokenType("Bearer")
                .expiresIn(3600L)
                .userId("user-123")
                .phoneNumber("0987654321")
                .fullName("Nguyen Van A")
                .role("ROLE_USER")
                .kycTier("UNVERIFIED")
                .build();

        when(authService.register(any(RegisterRequest.class))).thenReturn(mockResponse);

        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.token", is("mock-jwt-token")))
                .andExpect(jsonPath("$.data.userId", is("user-123")))
                .andExpect(jsonPath("$.data.phoneNumber", is("0987654321")))
                .andExpect(jsonPath("$.data.fullName", is("Nguyen Van A")));

        verify(authService).register(any(RegisterRequest.class));
    }

    @Test
    @DisplayName("API POST /api/v1/auth/register - Báo lỗi 400 Bad Request khi định dạng SĐT không đúng")
    void shouldReturn400WhenPhoneNumberIsInvalid() throws Exception {
        RegisterRequest request = RegisterRequest.builder()
                .phoneNumber("12345") // SĐT không hợp lệ
                .fullName("Nguyen Van A")
                .password("Pass123")
                .build();

        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success", is(false)))
                .andExpect(jsonPath("$.error", is("VALIDATION_FAILED")));
    }

    @Test
    @DisplayName("API POST /api/v1/auth/login - Đăng nhập thành công trả về HTTP 200 OK")
    void shouldReturn200WhenLoginSuccessfully() throws Exception {
        LoginRequest request = LoginRequest.builder()
                .phoneNumber("0987654321")
                .password("Password123")
                .deviceId("device-xyz")
                .build();

        AuthResponse mockResponse = AuthResponse.builder()
                .token("jwt-login-token")
                .userId("user-123")
                .phoneNumber("0987654321")
                .role("ROLE_USER")
                .build();

        when(authService.login(any(LoginRequest.class), any(), any())).thenReturn(mockResponse);

        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.token", is("jwt-login-token")))
                .andExpect(jsonPath("$.data.userId", is("user-123")));
    }

    @Test
    @DisplayName("API POST /api/v1/auth/login - Đăng nhập bằng username teller1 trả về đầy đủ roles, branchId, token")
    void shouldReturn200WhenLoginWithUsernameSuccessfully() throws Exception {
        LoginRequest request = LoginRequest.builder()
                .username("teller1")
                .password("DemoPass#2026!")
                .build();

        AuthResponse mockResponse = AuthResponse.builder()
                .token("mock-jwt-teller-token")
                .userId("t0000001-0000-0000-0000-000000000001")
                .username("teller1")
                .fullName("Teller Nguyễn Văn A")
                .phoneNumber("0911000001")
                .email("teller1@banking.example.com")
                .role("ROLE_TELLER")
                .roles(java.util.List.of("ROLE_TELLER"))
                .branchId("BR_Q1")
                .kycTier("VERIFIED")
                .build();

        when(authService.login(any(LoginRequest.class), any(), any())).thenReturn(mockResponse);

        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.token", is("mock-jwt-teller-token")))
                .andExpect(jsonPath("$.data.username", is("teller1")))
                .andExpect(jsonPath("$.data.fullName", is("Teller Nguyễn Văn A")))
                .andExpect(jsonPath("$.data.role", is("ROLE_TELLER")))
                .andExpect(jsonPath("$.data.roles[0]", is("ROLE_TELLER")))
                .andExpect(jsonPath("$.data.branchId", is("BR_Q1")));
    }

    @Test
    @DisplayName("API POST /api/v1/auth/refresh - Refresh token thành công trả về HTTP 200 OK")
    void shouldReturn200WhenRefreshTokenSuccessfully() throws Exception {
        RefreshTokenRequest request = RefreshTokenRequest.builder()
                .refreshToken("valid-refresh-token")
                .deviceId("device-xyz")
                .build();

        AuthResponse mockResponse = AuthResponse.builder()
                .token("new-jwt-token")
                .userId("user-123")
                .build();

        when(authService.refreshToken(any(RefreshTokenRequest.class))).thenReturn(mockResponse);

        mockMvc.perform(post("/api/v1/auth/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.token", is("new-jwt-token")));
    }

    @Test
    @DisplayName("API POST /api/v1/auth/logout - Đăng xuất thành công trả về HTTP 200 OK")
    void shouldReturn200WhenLogoutSuccessfully() throws Exception {
        mockMvc.perform(post("/api/v1/auth/logout")
                        .header(HttpHeaders.AUTHORIZATION, "Bearer valid-token")
                        .header("X-User-Id", "user-123")
                        .param("deviceId", "device-xyz"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.message", is("Đăng xuất thành công")));

        verify(authService).logout("Bearer valid-token", "user-123", "device-xyz");
    }

    @Test
    @DisplayName("API POST /api/v1/auth/forgot-password - Gửi OTP khôi phục mật khẩu thành công trả về HTTP 200")
    void shouldReturn200WhenForgotPasswordSuccessfully() throws Exception {
        ForgotPasswordRequest request = ForgotPasswordRequest.builder()
                .phoneNumber("0901234567")
                .build();

        OtpSendResponse mockResponse = OtpSendResponse.builder()
                .phoneNumber("0901234567")
                .expiresInSeconds(180)
                .referenceId("REF-1234567890")
                .maskedEmail("al***e@banking.com")
                .message("Mã xác thực OTP đã được gửi đến Gmail chính chủ của Quý khách")
                .build();

        when(otpService.forgotPassword("0901234567")).thenReturn(mockResponse);

        mockMvc.perform(post("/api/v1/auth/forgot-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.phoneNumber", is("0901234567")))
                .andExpect(jsonPath("$.data.expiresInSeconds", is(180)))
                .andExpect(jsonPath("$.data.maskedEmail", is("al***e@banking.com")));

        verify(otpService).forgotPassword("0901234567");
    }

    @Test
    @DisplayName("API POST /api/v1/auth/forgot-password - Báo lỗi 400 khi thiếu số điện thoại")
    void shouldReturn400WhenForgotPasswordPhoneIsBlank() throws Exception {
        mockMvc.perform(post("/api/v1/auth/forgot-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success", is(false)))
                .andExpect(jsonPath("$.error", is("BAD_REQUEST")));
    }

    @Test
    @DisplayName("API POST /api/v1/auth/forgot-password - Báo lỗi 400 khi SĐT không tồn tại trong hệ thống")
    void shouldReturn400WhenForgotPasswordUserNotFound() throws Exception {
        ForgotPasswordRequest request = ForgotPasswordRequest.builder()
                .phoneNumber("0999999999")
                .build();

        when(otpService.forgotPassword("0999999999"))
                .thenThrow(new IllegalArgumentException("Số điện thoại không tồn tại trong hệ thống."));

        mockMvc.perform(post("/api/v1/auth/forgot-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success", is(false)))
                .andExpect(jsonPath("$.error", is("BAD_REQUEST")))
                .andExpect(jsonPath("$.message", is("Số điện thoại không tồn tại trong hệ thống.")));

        verify(otpService).forgotPassword("0999999999");
    }
}
