package com.fintech.wallet.domain.model;

import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

public class FundingSource {
    private final String id;
    private final String userId;
    private final FundingSourceType type;
    private final String provider;
    private final String maskedNumber;
    private FundingSourceStatus status;
    private final Instant createdAt;
    private Instant updatedAt;

    public FundingSource(String id, String userId, FundingSourceType type, String provider, String maskedNumber, FundingSourceStatus status, Instant createdAt, Instant updatedAt) {
        this.id = id != null ? id : UUID.randomUUID().toString();
        this.userId = userId;
        this.type = type;
        this.provider = provider;
        this.maskedNumber = maskedNumber;
        this.status = status != null ? status : FundingSourceStatus.ACTIVE;
        this.createdAt = createdAt != null ? createdAt : Instant.now();
        this.updatedAt = updatedAt != null ? updatedAt : Instant.now();
    }

    public static FundingSource create(String userId, FundingSourceType type, String provider, String rawNumber) {
        String sanitizedNumber = rawNumber.replaceAll("[^0-9]", "");
        if (sanitizedNumber.length() < 4) {
            throw new IllegalArgumentException("Card/Account number is too short");
        }
        
        String masked;
        if (sanitizedNumber.length() <= 10) {
             // For shorter bank accounts, mask middle
             masked = sanitizedNumber.substring(0, 2) + "****" + sanitizedNumber.substring(sanitizedNumber.length() - 2);
        } else {
             // Standard card mask: first 4, last 4
             masked = sanitizedNumber.substring(0, 4) + " **** **** " + sanitizedNumber.substring(sanitizedNumber.length() - 4);
        }

        return new FundingSource(null, userId, type, provider, masked, FundingSourceStatus.ACTIVE, null, null);
    }

    public void markInactive() {
        this.status = FundingSourceStatus.INACTIVE;
        this.updatedAt = Instant.now();
    }

    public String getId() { return id; }
    public String getUserId() { return userId; }
    public FundingSourceType getType() { return type; }
    public String getProvider() { return provider; }
    public String getMaskedNumber() { return maskedNumber; }
    public FundingSourceStatus getStatus() { return status; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        FundingSource that = (FundingSource) o;
        return Objects.equals(id, that.id);
    }

    @Override
    public int hashCode() {
        return Objects.hash(id);
    }
}
