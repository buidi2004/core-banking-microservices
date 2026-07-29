package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.model.KycStatus;
import com.fintech.wallet.domain.model.User;
import com.fintech.wallet.domain.model.UserProfile;
import com.fintech.wallet.domain.port.in.UserProfileUseCase;
import com.fintech.wallet.domain.port.out.UserPersistencePort;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class ProfileService implements UserProfileUseCase {

    private final UserPersistencePort userPersistencePort;
    private final Map<String, UserProfile> profileCache = new ConcurrentHashMap<>();

    public ProfileService(UserPersistencePort userPersistencePort) {
        this.userPersistencePort = userPersistencePort;
    }

    @Override
    public UserProfile getProfile(String userId) {
        User user = userPersistencePort.findUserById(userId).orElse(null);
        KycStatus status = user != null ? user.getKycStatus() : KycStatus.UNVERIFIED;
        String phone = user != null ? user.getPhoneNumber() : "0900000000";

        return profileCache.computeIfAbsent(userId, k ->
                new UserProfile(userId, "User " + phone.substring(Math.max(0, phone.length() - 4)),
                        "user" + userId.substring(0, 4) + "@fintech.com", "1995-01-01",
                        "https://api.dicebear.com/7.x/avataaars/svg?seed=" + userId, status, Instant.now())
        );
    }

    @Override
    public UserProfile updateProfile(String userId, String fullName, String email, String dob) {
        UserProfile profile = getProfile(userId);
        profile.updateInfo(fullName, email, dob);
        profileCache.put(userId, profile);
        return profile;
    }

    @Override
    public UserProfile updateAvatar(String userId, String avatarUrl) {
        UserProfile profile = getProfile(userId);
        profile.updateAvatar(avatarUrl);
        profileCache.put(userId, profile);
        return profile;
    }

    @Override
    public UserProfile getPublicRecipientInfo(String userId) {
        UserProfile profile = getProfile(userId);
        return new UserProfile(userId, profile.getFullName(), null, null, profile.getAvatarUrl(), profile.getKycStatus(), null);
    }
}
