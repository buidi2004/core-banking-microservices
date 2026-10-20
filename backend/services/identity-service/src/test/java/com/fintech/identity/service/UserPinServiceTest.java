package com.fintech.identity.service;

import com.fintech.identity.domain.entity.UserEntity;
import com.fintech.identity.dto.PinVerifyResponse;
import com.fintech.identity.exception.InvalidPinException;
import com.fintech.identity.exception.PinLockedException;
import com.fintech.identity.exception.PinNotSetException;
import com.fintech.identity.repository.UserRepository;
import com.fintech.identity.security.JwtTokenProvider;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.time.Instant;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class UserPinServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private JwtTokenProvider jwtTokenProvider;

    @InjectMocks
    private UserPinService userPinService;

    private UserEntity userWithPin;
    private UserEntity userWithoutPin;

    @BeforeEach
    void setUp() {
        userWithPin = UserEntity.builder()
                .id("user-123")
                .phoneNumber("0987654321")
                .pinHash("$2a$10$hashedPinValue123456")
                .pinFailedAttempts(0)
                .pinLockedUntil(null)
                .build();

        userWithoutPin = UserEntity.builder()
                .id("user-456")
                .phoneNumber("0912345678")
                .pinHash(null)
                .pinFailedAttempts(0)
                .pinLockedUntil(null)
                .build();
    }

    @Test
    @DisplayName("Set PIN: 6 chữ số hợp lệ được mã hóa BCrypt và lưu thành công")
    void testSetPin_Success() {
        when(userRepository.findById("user-456")).thenReturn(Optional.of(userWithoutPin));
        when(passwordEncoder.encode("123456")).thenReturn("$2a$10$newHashedPin");

        userPinService.setPin("user-456", "123456");

        assertThat(userWithoutPin.getPinHash()).isEqualTo("$2a$10$newHashedPin");
        assertThat(userWithoutPin.getPinFailedAttempts()).isEqualTo(0);
        assertThat(userWithoutPin.getPinLockedUntil()).isNull();
        verify(userRepository).save(userWithoutPin);
    }

    @Test
    @DisplayName("Set PIN: Mã PIN không đúng 6 chữ số sẽ bị từ chối")
    void testSetPin_InvalidLength_ThrowsException() {
        assertThatThrownBy(() -> userPinService.setPin("user-456", "12345"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Mã PIN phải bao gồm đúng 6 chữ số");

        assertThatThrownBy(() -> userPinService.setPin("user-456", "1234567"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Mã PIN phải bao gồm đúng 6 chữ số");
    }

    @Test
    @DisplayName("Set PIN: Mã PIN chứa ký tự không phải số sẽ bị từ chối")
    void testSetPin_NonNumeric_ThrowsException() {
        assertThatThrownBy(() -> userPinService.setPin("user-456", "12345a"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Mã PIN phải bao gồm đúng 6 chữ số");
    }

    @Test
    @DisplayName("Verify PIN: Nhập đúng PIN trả về pinToken và reset số lần sai về 0")
    void testVerifyPin_Success() {
        when(userRepository.findById("user-123")).thenReturn(Optional.of(userWithPin));
        when(passwordEncoder.matches("123456", userWithPin.getPinHash())).thenReturn(true);
        when(jwtTokenProvider.generatePinToken("user-123")).thenReturn("mock-signed-pin-jwt-token");

        PinVerifyResponse response = userPinService.verifyPin("user-123", "123456");

        assertThat(response.getPinToken()).isEqualTo("mock-signed-pin-jwt-token");
        assertThat(userWithPin.getPinFailedAttempts()).isEqualTo(0);
        verify(userRepository).save(userWithPin);
    }

    @Test
    @DisplayName("Verify PIN: Chưa cài đặt PIN sẽ ném lỗi PinNotSetException")
    void testVerifyPin_PinNotSet_ThrowsException() {
        when(userRepository.findById("user-456")).thenReturn(Optional.of(userWithoutPin));

        assertThatThrownBy(() -> userPinService.verifyPin("user-456", "123456"))
                .isInstanceOf(PinNotSetException.class)
                .hasMessageContaining("Mã PIN giao dịch chưa được thiết lập");
    }

    @Test
    @DisplayName("Verify PIN: Sai PIN sẽ tăng số lần sai và ném InvalidPinException kèm số lần còn lại")
    void testVerifyPin_WrongPin_IncrementsFailedAttempts() {
        when(userRepository.findById("user-123")).thenReturn(Optional.of(userWithPin));
        when(passwordEncoder.matches("654321", userWithPin.getPinHash())).thenReturn(false);

        assertThatThrownBy(() -> userPinService.verifyPin("user-123", "654321"))
                .isInstanceOf(InvalidPinException.class)
                .hasMessageContaining("Mã PIN không chính xác. Bạn còn 4 lần thử");

        assertThat(userWithPin.getPinFailedAttempts()).isEqualTo(1);
        verify(userRepository).save(userWithPin);
    }

    @Test
    @DisplayName("Verify PIN: Sai liên tiếp 5 lần sẽ khóa PIN trong 15 phút và ném PinLockedException")
    void testVerifyPin_LockoutAfter5Failures() {
        userWithPin.setPinFailedAttempts(4);
        when(userRepository.findById("user-123")).thenReturn(Optional.of(userWithPin));
        when(passwordEncoder.matches("999999", userWithPin.getPinHash())).thenReturn(false);

        assertThatThrownBy(() -> userPinService.verifyPin("user-123", "999999"))
                .isInstanceOf(PinLockedException.class)
                .hasMessageContaining("bị tạm khóa trong 15 phút");

        assertThat(userWithPin.getPinFailedAttempts()).isEqualTo(5);
        assertThat(userWithPin.getPinLockedUntil()).isAfter(Instant.now().plusSeconds(800));
        verify(userRepository).save(userWithPin);
    }

    @Test
    @DisplayName("Verify PIN: Đang trong thời gian khóa thì từ chối ngay mà không kiểm tra PIN")
    void testVerifyPin_WhileLocked_RejectsImmediately() {
        userWithPin.setPinFailedAttempts(5);
        userWithPin.setPinLockedUntil(Instant.now().plusSeconds(600)); // còn 10 phút khóa
        when(userRepository.findById("user-123")).thenReturn(Optional.of(userWithPin));

        assertThatThrownBy(() -> userPinService.verifyPin("user-123", "123456"))
                .isInstanceOf(PinLockedException.class)
                .hasMessageContaining("Mã PIN đang bị khóa");

        verify(passwordEncoder, never()).matches(any(), any());
    }

    @Test
    @DisplayName("Verify PIN: Hết thời gian khóa cho phép thử lại và reset nếu đúng")
    void testVerifyPin_LockExpired_AllowsVerifyAndResets() {
        userWithPin.setPinFailedAttempts(5);
        userWithPin.setPinLockedUntil(Instant.now().minusSeconds(10)); // đã hết hạn khóa 10s trước
        when(userRepository.findById("user-123")).thenReturn(Optional.of(userWithPin));
        when(passwordEncoder.matches("123456", userWithPin.getPinHash())).thenReturn(true);
        when(jwtTokenProvider.generatePinToken("user-123")).thenReturn("new-pin-token");

        PinVerifyResponse response = userPinService.verifyPin("user-123", "123456");

        assertThat(response.getPinToken()).isEqualTo("new-pin-token");
        assertThat(userWithPin.getPinFailedAttempts()).isEqualTo(0);
        assertThat(userWithPin.getPinLockedUntil()).isNull();
        verify(userRepository).save(userWithPin);
    }
}

