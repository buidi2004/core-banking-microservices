package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.exception.InvalidPinException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.core.ValueOperations;

import java.time.Duration;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

class OtpServiceTest {

    private RedisTemplate<String, Object> redisTemplate;
    private ValueOperations<String, Object> valueOperations;
    private OtpService otpService;
    private OtpService.PinUseCaseImpl mockPinUseCase;

    @BeforeEach
    @SuppressWarnings("unchecked")
    void setUp() {
        redisTemplate = mock(RedisTemplate.class);
        valueOperations = mock(ValueOperations.class);
        when(redisTemplate.opsForValue()).thenReturn(valueOperations);

        otpService = new OtpService(redisTemplate);
        mockPinUseCase = mock(OtpService.PinUseCaseImpl.class);
    }

    @Test
    void generateAndStoreOtp_shouldStoreOtpWithTTL() {
        String txId = "tx123";
        String otp = otpService.generateAndStoreOtp(txId);

        assertNotNull(otp);
        assertEquals(6, otp.length());

        ArgumentCaptor<Duration> durationCaptor = ArgumentCaptor.forClass(Duration.class);
        verify(valueOperations).set(eq("otp:trans:" + txId), eq(otp), durationCaptor.capture());
        assertEquals(5, durationCaptor.getValue().toMinutes());
    }

    @Test
    void verifyOtpOrPin_withCorrectOtp_shouldSucceed() {
        String userId = "u1";
        String txId = "tx1";
        String correctOtp = "123456";

        when(redisTemplate.hasKey("locked_user:" + userId)).thenReturn(false);
        when(valueOperations.get("otp:trans:" + txId)).thenReturn(correctOtp);

        assertDoesNotThrow(() -> otpService.verifyOtpOrPin(userId, txId, correctOtp, null, mockPinUseCase));

        verify(redisTemplate).delete("otp:trans:" + txId);
        verify(redisTemplate).delete("failed_confirm:" + userId);
    }

    @Test
    void verifyOtpOrPin_withIncorrectOtp_shouldIncrementFailedAttempts() {
        String userId = "u1";
        String txId = "tx1";

        when(redisTemplate.hasKey("locked_user:" + userId)).thenReturn(false);
        when(valueOperations.get("otp:trans:" + txId)).thenReturn("999999");
        when(valueOperations.increment("failed_confirm:" + userId)).thenReturn(1L);

        assertThrows(InvalidPinException.class, () -> 
            otpService.verifyOtpOrPin(userId, txId, "123456", null, mockPinUseCase)
        );

        verify(redisTemplate).expire(eq("failed_confirm:" + userId), any(Duration.class));
    }

    @Test
    void verifyOtpOrPin_withMaxFailedAttempts_shouldLockUser() {
        String userId = "u1";
        String txId = "tx1";

        when(redisTemplate.hasKey("locked_user:" + userId)).thenReturn(false);
        when(valueOperations.get("otp:trans:" + txId)).thenReturn("999999");
        when(valueOperations.increment("failed_confirm:" + userId)).thenReturn(3L); // 3rd failure

        assertThrows(InvalidPinException.class, () -> 
            otpService.verifyOtpOrPin(userId, txId, "123456", null, mockPinUseCase)
        );

        verify(valueOperations).set(eq("locked_user:" + userId), eq("LOCKED"), any(Duration.class));
        verify(redisTemplate).delete("failed_confirm:" + userId);
    }

    @Test
    void verifyOtpOrPin_whenUserLocked_shouldThrowExceptionImmediately() {
        String userId = "u1";
        String txId = "tx1";

        when(redisTemplate.hasKey("locked_user:" + userId)).thenReturn(true);

        InvalidPinException ex = assertThrows(InvalidPinException.class, () -> 
            otpService.verifyOtpOrPin(userId, txId, "123456", null, mockPinUseCase)
        );

        assertTrue(ex.getMessage().contains("locked"));
        verify(valueOperations, never()).get(anyString());
    }

    @Test
    void verifyOtpOrPin_withCorrectPin_shouldSucceed() {
        String userId = "u1";
        String txId = "tx1";
        String correctPin = "111111";

        when(redisTemplate.hasKey("locked_user:" + userId)).thenReturn(false);
        when(mockPinUseCase.verifyPin(userId, correctPin)).thenReturn(true);

        assertDoesNotThrow(() -> otpService.verifyOtpOrPin(userId, txId, null, correctPin, mockPinUseCase));

        verify(redisTemplate).delete("failed_confirm:" + userId);
    }
}
