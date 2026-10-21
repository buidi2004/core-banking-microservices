package com.fintech.identity.service;

import com.fintech.identity.domain.entity.UserEntity;
import com.fintech.identity.dto.*;
import com.fintech.identity.repository.UserRepository;
import com.fintech.identity.repository.UserSessionRepository;
import com.fintech.identity.security.JwtTokenProvider;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ValueOperations;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.time.Duration;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class OtpServiceTest {

    @Mock
    private StringRedisTemplate redisTemplate;

    @Mock
    private ValueOperations<String, String> valueOperations;

    @Mock
    private UserRepository userRepository;

    @Mock
    private UserSessionRepository userSessionRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private JwtTokenProvider tokenProvider;

    @Mock
    private EmailService emailService;

    private OtpService otpService;

    @BeforeEach
    void setUp() {
        lenient().when(redisTemplate.opsForValue()).thenReturn(valueOperations);
        otpService = new OtpService(redisTemplate, userRepository, userSessionRepository, passwordEncoder, tokenProvider, emailService);
    }

    @Test
    @DisplayName("sendOtp: Sinh mã 6 số ngẫu nhiên và lưu Redis với TTL 180s thành công")
    void sendOtp_Success() {
        String phone = "0987654321";
        String purpose = "FORGOT_PASSWORD";

        OtpSendResponse response = otpService.sendOtp(phone, purpose);

        assertThat(response).isNotNull();
        assertThat(response.getPhoneNumber()).isEqualTo(phone);
        assertThat(response.getExpiresInSeconds()).isEqualTo(180);
        assertThat(response.getReferenceId()).isNotBlank();

        verify(valueOperations).set(eq("identity:otp:" + phone + ":" + purpose), anyString(), eq(Duration.ofSeconds(180)));
    }

    @Test
    @DisplayName("verifyOtp: Xác thực đúng mã OTP, xóa cache và trả về otpToken hợp lệ")
    void verifyOtp_Success() {
        String phone = "0987654321";
        String purpose = "FORGOT_PASSWORD";
        String code = "123456";

        when(valueOperations.get("identity:otp:" + phone + ":" + purpose)).thenReturn("123456");
        when(tokenProvider.generateOtpToken(phone, purpose)).thenReturn("valid-jwt-otp-token");

        OtpVerifyResponse response = otpService.verifyOtp(phone, code, purpose);

        assertThat(response).isNotNull();
        assertThat(response.isVerified()).isTrue();
        assertThat(response.getOtpToken()).isEqualTo("valid-jwt-otp-token");

        verify(redisTemplate).delete("identity:otp:" + phone + ":" + purpose);
    }

    @Test
    @DisplayName("verifyOtp: Nhập sai mã OTP bị tăng số lần thử và báo lỗi")
    void verifyOtp_WrongCode() {
        String phone = "0987654321";
        String purpose = "FORGOT_PASSWORD";

        when(valueOperations.get("identity:otp:" + phone + ":" + purpose)).thenReturn("123456");
        when(valueOperations.increment("identity:otp:attempts:" + phone + ":" + purpose)).thenReturn(1L);

        assertThatThrownBy(() -> otpService.verifyOtp(phone, "999999", purpose))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Mã OTP không chính xác");

        verify(redisTemplate, never()).delete("identity:otp:" + phone + ":" + purpose);
    }

    @Test
    @DisplayName("verifyOtp: Hết hạn OTP báo lỗi rõ ràng")
    void verifyOtp_Expired() {
        String phone = "0987654321";
        String purpose = "FORGOT_PASSWORD";

        when(valueOperations.get("identity:otp:" + phone + ":" + purpose)).thenReturn(null);

        assertThatThrownBy(() -> otpService.verifyOtp(phone, "123456", purpose))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Mã OTP đã hết hạn hoặc không tồn tại");
    }

    @Test
    @DisplayName("forgotPassword: Người dùng tồn tại sẽ kích hoạt gửi OTP")
    void forgotPassword_Success() {
        String phone = "0987654321";
        UserEntity user = UserEntity.builder()
                .id(UUID.randomUUID().toString())
                .phoneNumber(phone)
                .build();

        when(userRepository.findByPhoneNumber(phone)).thenReturn(Optional.of(user));

        OtpSendResponse response = otpService.forgotPassword(phone);

        assertThat(response).isNotNull();
        verify(valueOperations).set(eq("identity:otp:" + phone + ":FORGOT_PASSWORD"), anyString(), eq(Duration.ofSeconds(180)));
    }

    @Test
    @DisplayName("forgotPassword: SĐT không tồn tại báo lỗi bảo mật")
    void forgotPassword_UserNotFound() {
        String phone = "0999999999";
        when(userRepository.findByPhoneNumber(phone)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> otpService.forgotPassword(phone))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Số điện thoại không tồn tại");
    }

    @Test
    @DisplayName("resetPassword: Cập nhật mật khẩu mới bằng otpToken và thu hồi session cũ")
    void resetPassword_Success() {
        String phone = "0987654321";
        String token = "valid-otp-token";
        String newPassword = "NewSecurePassword@123";

        UserEntity user = UserEntity.builder()
                .id("user-uuid-123")
                .phoneNumber(phone)
                .passwordHash("old-hash")
                .build();

        when(tokenProvider.validateOtpToken(token, phone, "FORGOT_PASSWORD")).thenReturn(true);
        when(userRepository.findByPhoneNumber(phone)).thenReturn(Optional.of(user));
        when(passwordEncoder.encode(newPassword)).thenReturn("encoded-new-hash");

        otpService.resetPassword(phone, token, newPassword);

        assertThat(user.getPasswordHash()).isEqualTo("encoded-new-hash");
        verify(userRepository).save(user);
        verify(userSessionRepository).deleteByUserId("user-uuid-123");
    }
}

