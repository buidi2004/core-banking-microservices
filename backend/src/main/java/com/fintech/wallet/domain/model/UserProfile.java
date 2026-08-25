package com.fintech.wallet.domain.model;

import java.time.Instant;

public class UserProfile {
    private final String userId;
    private String fullName;
    private String email;
    private String dob;
    private String avatarUrl;
    private KycStatus kycStatus;
    private final Instant updatedAt;

    public UserProfile(String userId, String fullName, String email, String dob, String avatarUrl, KycStatus kycStatus, Instant updatedAt) {
        this.userId = userId;
        this.fullName = fullName;
        this.email = email;
        this.dob = dob;
        this.avatarUrl = avatarUrl;
        this.kycStatus = kycStatus != null ? kycStatus : KycStatus.UNVERIFIED;
        this.updatedAt = updatedAt != null ? updatedAt : Instant.now();
    }

    public void updateInfo(String fullName, String email, String dob) {
        if (fullName != null) this.fullName = fullName;
        if (email != null) this.email = email;
        if (dob != null) this.dob = dob;
    }

    public void updateAvatar(String avatarUrl) {
        this.avatarUrl = avatarUrl;
    }

    public String getUserId() { return userId; }
    public String getFullName() { return fullName; }
    public String getEmail() { return email; }
    public String getDob() { return dob; }
    public String getAvatarUrl() { return avatarUrl; }
    public KycStatus getKycStatus() { return kycStatus; }
    public Instant getUpdatedAt() { return updatedAt; }
}
