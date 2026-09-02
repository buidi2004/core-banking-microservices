package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.model.PublicUserProfile;
import com.fintech.wallet.domain.model.User;
import com.fintech.wallet.domain.port.in.AccountUseCase;
import com.fintech.wallet.domain.port.in.AuthUseCase;
import com.fintech.wallet.domain.port.out.UserPersistencePort;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

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
                user.getFullName(),
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
                user.getFullName(),
                passwordEncoder.encode(newPassword),
                user.getPinHash(),
                user.getKycStatus(),
                user.getCreatedAt(),
                java.time.Instant.now()
        );
        userPersistencePort.saveUser(updatedUser);
    }

    /**
     * P2P recipient lookup: returns a masked public profile when found,
     * empty when no account exists for that phone number.
     * Validates phone format to prevent enumeration via malformed input.
     */
    @Override
    public Optional<PublicUserProfile> searchByPhone(String phoneNumber) {
        if (phoneNumber == null || !phoneNumber.matches("^0\\d{9}$")) {
            throw new IllegalArgumentException(
                    "Phone number must be a valid 10-digit Vietnamese mobile number starting with 0");
        }
        return userPersistencePort.searchByPhoneNumber(phoneNumber)
                .map(PublicUserProfile::from);
    }
}
