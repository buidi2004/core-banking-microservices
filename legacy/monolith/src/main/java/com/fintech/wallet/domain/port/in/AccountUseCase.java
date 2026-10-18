package com.fintech.wallet.domain.port.in;

import com.fintech.wallet.domain.model.PublicUserProfile;

import java.util.Optional;

public interface AccountUseCase {
    void changePassword(String userId, String oldPassword, String newPassword);
    void resetPassword(String phoneNumber, String otp, String newPassword);

    /**
     * Look up a recipient's public profile by phone number.
     * Called before the P2P transfer screen so the sender can confirm
     * they are sending to the right person.
     * Returns empty when no wallet account is registered for that number.
     */
    Optional<PublicUserProfile> searchByPhone(String phoneNumber);
}
