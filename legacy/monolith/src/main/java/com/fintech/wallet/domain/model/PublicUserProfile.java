package com.fintech.wallet.domain.model;

/**
 * Read-only projection of a User exposed to other users (e.g. P2P recipient lookup).
 * Never includes passwordHash, pinHash, or any security-sensitive field.
 */
public class PublicUserProfile {

    private final String userId;
    private final String phoneNumber;
    private final KycStatus kycStatus;

    public PublicUserProfile(String userId, String phoneNumber, KycStatus kycStatus) {
        this.userId = userId;
        this.phoneNumber = phoneNumber;
        this.kycStatus = kycStatus;
    }

    public static PublicUserProfile from(User user) {
        // Mask phone: 09*****321
        String phone = user.getPhoneNumber();
        String masked = phone.length() > 6
                ? phone.substring(0, 2) + "*****" + phone.substring(phone.length() - 3)
                : phone;
        return new PublicUserProfile(user.getId(), masked, user.getKycStatus());
    }

    public String getUserId()      { return userId; }
    public String getPhoneNumber() { return phoneNumber; }
    public KycStatus getKycStatus() { return kycStatus; }
}
