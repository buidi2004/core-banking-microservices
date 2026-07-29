package com.fintech.wallet.domain.model;

import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * Domain Entity: UserKyc
 * Pure Java - No Spring / JPA annotations.
 */
public class UserKyc {
    private final String id;
    private final String userId;
    private final String idCardNumber;
    private final String fullName;
    private final String dob;
    private final String frontCardUrl;
    private final String backCardUrl;
    private final String selfieUrl;
    private KycStatus status;
    private final Instant createdAt;
    private Instant verifiedAt;

    public UserKyc(String id, String userId, String idCardNumber, String fullName, String dob,
                   String frontCardUrl, String backCardUrl, String selfieUrl,
                   KycStatus status, Instant createdAt, Instant verifiedAt) {
        this.id = id != null ? id : UUID.randomUUID().toString();
        this.userId = userId;
        this.idCardNumber = idCardNumber;
        this.fullName = fullName;
        this.dob = dob;
        this.frontCardUrl = frontCardUrl;
        this.backCardUrl = backCardUrl;
        this.selfieUrl = selfieUrl;
        this.status = status != null ? status : KycStatus.PENDING;
        this.createdAt = createdAt != null ? createdAt : Instant.now();
        this.verifiedAt = verifiedAt;
    }

    public static UserKyc createPending(String userId, String idCardNumber, String fullName, String dob,
                                        String frontCardUrl, String backCardUrl, String selfieUrl) {
        return new UserKyc(
            UUID.randomUUID().toString(),
            userId,
            idCardNumber,
            fullName,
            dob,
            frontCardUrl,
            backCardUrl,
            selfieUrl,
            KycStatus.PENDING,
            Instant.now(),
            null
        );
    }

    public void approve() {
        this.status = KycStatus.VERIFIED;
        this.verifiedAt = Instant.now();
    }

    public void reject() {
        this.status = KycStatus.REJECTED;
        this.verifiedAt = Instant.now();
    }

    public String getId() { return id; }
    public String getUserId() { return userId; }
    public String getIdCardNumber() { return idCardNumber; }
    public String getFullName() { return fullName; }
    public String getDob() { return dob; }
    public String getFrontCardUrl() { return frontCardUrl; }
    public String getBackCardUrl() { return backCardUrl; }
    public String getSelfieUrl() { return selfieUrl; }
    public KycStatus getStatus() { return status; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getVerifiedAt() { return verifiedAt; }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        UserKyc userKyc = (UserKyc) o;
        return Objects.equals(id, userKyc.id);
    }

    @Override
    public int hashCode() {
        return Objects.hash(id);
    }
}
