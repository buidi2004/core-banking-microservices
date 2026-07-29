package com.fintech.wallet.domain.port.in;

import com.fintech.wallet.domain.model.User;

public interface AuthUseCase {
    User register(String phoneNumber, String password);
    String login(String phoneNumber, String password);
    boolean sendOtp(String phoneNumber);
    boolean verifyOtp(String phoneNumber, String otp);
    String refreshToken(String refreshToken);
    boolean sendPasswordResetOtp(String phoneNumber);
    boolean resetPassword(String phoneNumber, String otp, String newPassword);
}
