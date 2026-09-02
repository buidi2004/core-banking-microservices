package com.fintech.wallet.domain.model;

import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * Domain Entity: User
 * Pure Java - No Spring / JPA annotations.
 */
public class User {
    private final String id;
    private final String phoneNumber;
    private String fullName;
    private String passwordHash;
    private String pinHash;
    private KycStatus kycStatus;
    private final Instant createdAt;
    private Instant updatedAt;

    public User(String id, String phoneNumber, String fullName, String passwordHash, String pinHash, KycStatus kycStatus, Instant createdAt, Instant updatedAt) {
        this.id = id != null ? id : UUID.randomUUID().toString();
        this.phoneNumber = phoneNumber;
        this.fullName = fullName;
        this.passwordHash = passwordHash;
        this.pinHash = pinHash;
        this.kycStatus = kycStatus != null ? kycStatus : KycStatus.UNVERIFIED;
        this.createdAt = createdAt != null ? createdAt : Instant.now();
        this.updatedAt = updatedAt != null ? updatedAt : Instant.now();
    }

    public static User createNew(String phoneNumber, String fullName, String passwordHash) {
        return new User(
            UUID.randomUUID().toString(),
            phoneNumber,
            fullName,
            passwordHash,
            null,
            KycStatus.UNVERIFIED,
            Instant.now(),
            Instant.now()
        );
    }

    public void updatePin(String pinHash) {
        this.pinHash = pinHash;
        this.updatedAt = Instant.now();
    }

    public void updatePassword(String passwordHash) {
        this.passwordHash = passwordHash;
        this.updatedAt = Instant.now();
    }

    public void updateKycStatus(KycStatus kycStatus) {
        this.kycStatus = kycStatus;
        this.updatedAt = Instant.now();
    }

    public String getId() { return id; }
    public String getPhoneNumber() { return phoneNumber; }
    public String getFullName() { return fullName; }
    public String getPasswordHash() { return passwordHash; }
    public String getPinHash() { return pinHash; }
    public KycStatus getKycStatus() { return kycStatus; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        User user = (User) o;
        return Objects.equals(id, user.id);
    }

    @Override
    public int hashCode() {
        return Objects.hash(id);
    }
}
