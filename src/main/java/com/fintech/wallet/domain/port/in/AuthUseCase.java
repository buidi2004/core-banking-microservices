package com.fintech.wallet.domain.port.in;

import com.fintech.wallet.domain.model.AuthTokens;
import com.fintech.wallet.domain.model.User;

public interface AuthUseCase {
    User register(String phoneNumber, String password);
    AuthTokens login(String phoneNumber, String password, String deviceId, String ipAddress, String userAgent);
    boolean sendOtp(String phoneNumber);
    boolean verifyOtp(String phoneNumber, String otp);
    AuthTokens refreshToken(String refreshToken, String ipAddress);
    boolean sendPasswordResetOtp(String phoneNumber);
    boolean resetPassword(String phoneNumber, String otp, String newPassword);

    /** Invalidate the supplied access (or refresh) token immediately. */
    void logout(String token);
}
