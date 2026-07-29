package com.fintech.wallet.infrastructure.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;

@Entity
@Table(name = "user_kycs")
public class UserKycJpaEntity {

    @Id
    private String id;

    @Column(nullable = false, unique = true)
    private String userId;

    private String idCardNumber;
    private String fullName;
    private String dob;
    private String frontCardUrl;
    private String backCardUrl;
    private String selfieUrl;

    @Column(nullable = false)
    private String status;

    @Column(nullable = false, updatable = false)
    private Instant createdAt;

    private Instant verifiedAt;

    public UserKycJpaEntity() {}

    public UserKycJpaEntity(String id, String userId, String idCardNumber, String fullName, String dob, String frontCardUrl, String backCardUrl, String selfieUrl, String status, Instant createdAt, Instant verifiedAt) {
        this.id = id;
        this.userId = userId;
        this.idCardNumber = idCardNumber;
        this.fullName = fullName;
        this.dob = dob;
        this.frontCardUrl = frontCardUrl;
        this.backCardUrl = backCardUrl;
        this.selfieUrl = selfieUrl;
        this.status = status;
        this.createdAt = createdAt;
        this.verifiedAt = verifiedAt;
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }
    public String getIdCardNumber() { return idCardNumber; }
    public void setIdCardNumber(String idCardNumber) { this.idCardNumber = idCardNumber; }
    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }
    public String getDob() { return dob; }
    public void setDob(String dob) { this.dob = dob; }
    public String getFrontCardUrl() { return frontCardUrl; }
    public void setFrontCardUrl(String frontCardUrl) { this.frontCardUrl = frontCardUrl; }
    public String getBackCardUrl() { return backCardUrl; }
    public void setBackCardUrl(String backCardUrl) { this.backCardUrl = backCardUrl; }
    public String getSelfieUrl() { return selfieUrl; }
    public void setSelfieUrl(String selfieUrl) { this.selfieUrl = selfieUrl; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
    public Instant getVerifiedAt() { return verifiedAt; }
    public void setVerifiedAt(Instant verifiedAt) { this.verifiedAt = verifiedAt; }
}
