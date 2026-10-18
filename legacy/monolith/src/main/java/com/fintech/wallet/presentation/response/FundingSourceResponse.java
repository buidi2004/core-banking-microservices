package com.fintech.wallet.presentation.response;

import com.fintech.wallet.domain.model.FundingSource;
import com.fintech.wallet.domain.model.FundingSourceStatus;
import com.fintech.wallet.domain.model.FundingSourceType;

import java.time.Instant;

public class FundingSourceResponse {
    private String id;
    private FundingSourceType type;
    private String provider;
    private String maskedNumber;
    private FundingSourceStatus status;
    private Instant createdAt;

    public FundingSourceResponse() {}

    public FundingSourceResponse(String id, FundingSourceType type, String provider, String maskedNumber, FundingSourceStatus status, Instant createdAt) {
        this.id = id;
        this.type = type;
        this.provider = provider;
        this.maskedNumber = maskedNumber;
        this.status = status;
        this.createdAt = createdAt;
    }

    public static FundingSourceResponse fromDomain(FundingSource domain) {
        return new FundingSourceResponse(
            domain.getId(),
            domain.getType(),
            domain.getProvider(),
            domain.getMaskedNumber(),
            domain.getStatus(),
            domain.getCreatedAt()
        );
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public FundingSourceType getType() { return type; }
    public void setType(FundingSourceType type) { this.type = type; }

    public String getProvider() { return provider; }
    public void setProvider(String provider) { this.provider = provider; }

    public String getMaskedNumber() { return maskedNumber; }
    public void setMaskedNumber(String maskedNumber) { this.maskedNumber = maskedNumber; }

    public FundingSourceStatus getStatus() { return status; }
    public void setStatus(FundingSourceStatus status) { this.status = status; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
