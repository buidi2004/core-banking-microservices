package com.fintech.wallet.infrastructure.persistence.entity;

import com.fintech.wallet.domain.model.FundingSource;
import com.fintech.wallet.domain.model.FundingSourceStatus;
import com.fintech.wallet.domain.model.FundingSourceType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.Instant;

@Entity
@Table(name = "funding_sources")
public class FundingSourceEntity {
    
    @Id
    @Column(name = "id", updatable = false, nullable = false)
    private String id;
    
    @Column(name = "user_id", nullable = false)
    private String userId;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "type", nullable = false)
    private FundingSourceType type;
    
    @Column(name = "provider", nullable = false)
    private String provider;
    
    @Column(name = "masked_number", nullable = false)
    private String maskedNumber;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    private FundingSourceStatus status;
    
    @Column(name = "created_at", nullable = false)
    private Instant createdAt;
    
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;
    
    public FundingSourceEntity() {}

    public FundingSourceEntity(String id, String userId, FundingSourceType type, String provider, String maskedNumber, FundingSourceStatus status, Instant createdAt, Instant updatedAt) {
        this.id = id;
        this.userId = userId;
        this.type = type;
        this.provider = provider;
        this.maskedNumber = maskedNumber;
        this.status = status;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }

    public static FundingSourceEntity fromDomain(FundingSource domain) {
        return new FundingSourceEntity(
            domain.getId(),
            domain.getUserId(),
            domain.getType(),
            domain.getProvider(),
            domain.getMaskedNumber(),
            domain.getStatus(),
            domain.getCreatedAt(),
            domain.getUpdatedAt()
        );
    }

    public FundingSource toDomain() {
        return new FundingSource(
            id,
            userId,
            type,
            provider,
            maskedNumber,
            status,
            createdAt,
            updatedAt
        );
    }
}
