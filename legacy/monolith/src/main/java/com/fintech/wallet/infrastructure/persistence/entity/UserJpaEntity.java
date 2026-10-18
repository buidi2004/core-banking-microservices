package com.fintech.wallet.infrastructure.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;

@Entity
@Table(name = "users")
public class UserJpaEntity {

    @Id
    private String id;

    @Column(nullable = false, unique = true)
    private String phoneNumber;

    @Column(name = "full_name")
    private String fullName;

    @Column(nullable = false)
    private String passwordHash;

    private String pinHash;

    @Column(nullable = false)
    private String kycStatus;

    @Column(nullable = false, updatable = false)
    private Instant createdAt;

    @Column(nullable = false)
    private Instant updatedAt;

    public UserJpaEntity() {}

    public UserJpaEntity(String id, String phoneNumber, String fullName, String passwordHash, String pinHash, String kycStatus, Instant createdAt, Instant updatedAt) {
        this.id = id;
        this.phoneNumber = phoneNumber;
        this.fullName = fullName;
        this.passwordHash = passwordHash;
        this.pinHash = pinHash;
        this.kycStatus = kycStatus;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getPhoneNumber() { return phoneNumber; }
    public void setPhoneNumber(String phoneNumber) { this.phoneNumber = phoneNumber; }
    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }
    public String getPasswordHash() { return passwordHash; }
    public void setPasswordHash(String passwordHash) { this.passwordHash = passwordHash; }
    public String getPinHash() { return pinHash; }
    public void setPinHash(String pinHash) { this.pinHash = pinHash; }
    public String getKycStatus() { return kycStatus; }
    public void setKycStatus(String kycStatus) { this.kycStatus = kycStatus; }
    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
