package com.fintech.wallet.domain.port.in;

public interface AccountUseCase {
    void changePassword(String userId, String oldPassword, String newPassword);
    void resetPassword(String phoneNumber, String otp, String newPassword);
}
