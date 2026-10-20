package com.fintech.identity.service;

import com.fintech.identity.domain.entity.UserEntity;
import com.fintech.identity.dto.PinVerifyResponse;
import com.fintech.identity.exception.InvalidPinException;
import com.fintech.identity.exception.PinLockedException;
import com.fintech.identity.exception.PinNotSetException;
import com.fintech.identity.repository.UserRepository;
import com.fintech.identity.security.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;

@Slf4j
@Service
@RequiredArgsConstructor
public class UserPinService {

    public static final int MAX_FAILED_ATTEMPTS = 5;
    public static final long LOCK_DURATION_SECONDS = 15 * 60L; // 15 phút

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider;

    @Transactional
    public void setPin(String userId, String pin) {
        validatePinFormat(pin);

        UserEntity user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy người dùng với ID: " + userId));

        user.setPinHash(passwordEncoder.encode(pin));
        user.setPinFailedAttempts(0);
        user.setPinLockedUntil(null);
        userRepository.save(user);

        log.info("Người dùng {} đã thiết lập mã PIN giao dịch thành công", userId);
    }

    @Transactional
    public PinVerifyResponse verifyPin(String userId, String pin) {
        validatePinFormat(pin);

        UserEntity user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy người dùng với ID: " + userId));

        if (user.getPinHash() == null || user.getPinHash().isBlank()) {
            throw new PinNotSetException("Mã PIN giao dịch chưa được thiết lập. Vui lòng tạo mã PIN trước khi thực hiện giao dịch.");
        }

        Instant now = Instant.now();
        if (user.getPinLockedUntil() != null) {
            if (now.isBefore(user.getPinLockedUntil())) {
                throw new PinLockedException("Mã PIN đang bị khóa do nhập sai quá nhiều lần. Vui lòng thử lại sau.");
            } else {
                // Đã hết thời gian khóa, tự động mở khóa
                user.setPinFailedAttempts(0);
                user.setPinLockedUntil(null);
            }
        }

        boolean matches = passwordEncoder.matches(pin, user.getPinHash());
        if (matches) {
            user.setPinFailedAttempts(0);
            user.setPinLockedUntil(null);
            userRepository.save(user);

            String pinToken = jwtTokenProvider.generatePinToken(userId);
            log.info("Xác thực mã PIN thành công cho người dùng {}", userId);
            return new PinVerifyResponse(pinToken, 300L);
        } else {
            int failed = (user.getPinFailedAttempts() != null ? user.getPinFailedAttempts() : 0) + 1;
            user.setPinFailedAttempts(failed);

            if (failed >= MAX_FAILED_ATTEMPTS) {
                user.setPinLockedUntil(now.plusSeconds(LOCK_DURATION_SECONDS));
                userRepository.save(user);
                log.warn("Người dùng {} đã nhập sai mã PIN 5 lần liên tiếp. Khóa PIN trong 15 phút.", userId);
                throw new PinLockedException("Bạn đã nhập sai mã PIN 5 lần. Mã PIN giao dịch bị tạm khóa trong 15 phút để bảo vệ tài khoản.");
            } else {
                userRepository.save(user);
                int remaining = MAX_FAILED_ATTEMPTS - failed;
                log.warn("Người dùng {} nhập sai mã PIN lần {}. Còn lại {} lần thử.", userId, failed, remaining);
                throw new InvalidPinException("Mã PIN không chính xác. Bạn còn " + remaining + " lần thử.", remaining);
            }
        }
    }

    private void validatePinFormat(String pin) {
        if (pin == null || !pin.matches("^\\d{6}$")) {
            throw new IllegalArgumentException("Mã PIN phải bao gồm đúng 6 chữ số.");
        }
    }
}

