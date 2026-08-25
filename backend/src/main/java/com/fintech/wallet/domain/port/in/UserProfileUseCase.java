package com.fintech.wallet.domain.port.in;

import com.fintech.wallet.domain.model.UserProfile;

public interface UserProfileUseCase {
    UserProfile getProfile(String userId);
    UserProfile updateProfile(String userId, String fullName, String email, String dob);
    UserProfile updateAvatar(String userId, String avatarUrl);
    UserProfile getPublicRecipientInfo(String userId);
}
