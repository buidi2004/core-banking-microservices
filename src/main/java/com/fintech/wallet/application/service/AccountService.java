package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.model.User;
import com.fintech.wallet.domain.port.in.AccountUseCase;
import com.fintech.wallet.domain.port.in.AuthUseCase;
import com.fintech.wallet.domain.port.out.UserPersistencePort;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AccountService implements AccountUseCase {

    private final UserPersistencePort userPersistencePort;
    private final PasswordEncoder passwordEncoder;
    private final AuthUseCase authUseCase;

    public AccountService(UserPersistencePort userPersistencePort, PasswordEncoder passwordEncoder, AuthUseCase authUseCase) {
        this.userPersistencePort = userPersistencePort;
        this.passwordEncoder = passwordEncoder;
        this.authUseCase = authUseCase;
    }

    @Override
    @Transactional
    public void changePassword(String userId, String oldPassword, String newPassword) {
        if (newPassword == null || newPassword.length() < 6) {
            throw new IllegalArgumentException("New password must be at least 6 characters");
        }
        User user = userPersistencePort.findUserById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found: " + userId));

        if (!passwordEncoder.matches(oldPassword, user.getPasswordHash())) {
            throw new IllegalArgumentException("Incorrect current password");
        }

        User updatedUser = new User(
                user.getId(),
                user.getPhoneNumber(),
                passwordEncoder.encode(newPassword),
                user.getPinHash(),
                user.getKycStatus(),
                user.getCreatedAt(),
                java.time.Instant.now()
        );
        userPersistencePort.saveUser(updatedUser);
    }

    @Override
    @Transactional
    public void resetPassword(String phoneNumber, String otp, String newPassword) {
        if (!authUseCase.verifyOtp(phoneNumber, otp)) {
            throw new IllegalArgumentException("Invalid OTP for password reset");
        }

        User user = userPersistencePort.findUserByPhoneNumber(phoneNumber)
                .orElseThrow(() -> new IllegalArgumentException("User with phone number " + phoneNumber + " not found"));

        User updatedUser = new User(
                user.getId(),
                user.getPhoneNumber(),
                passwordEncoder.encode(newPassword),
                user.getPinHash(),
                user.getKycStatus(),
                user.getCreatedAt(),
                java.time.Instant.now()
        );
        userPersistencePort.saveUser(updatedUser);
    }
}
