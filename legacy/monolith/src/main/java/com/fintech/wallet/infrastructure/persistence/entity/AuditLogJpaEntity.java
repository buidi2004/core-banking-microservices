package com.fintech.wallet.infrastructure.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;

@Entity
@Table(name = "audit_logs")
public class AuditLogJpaEntity {

    @Id
    private String id;

    private String callerId;
    private String ipAddress;

    @Column(nullable = false)
    private String action;

    private String payloadHash;
    
    @Column(name = "idempotency_key", unique = true)
    private String idempotencyKey;

    @Column(nullable = false, updatable = false)
    private Instant createdAt;

    public AuditLogJpaEntity() {}

    public AuditLogJpaEntity(String id, String callerId, String ipAddress, String action, String payloadHash, String idempotencyKey, Instant createdAt) {
        this.id = id;
        this.callerId = callerId;
        this.ipAddress = ipAddress;
        this.action = action;
        this.payloadHash = payloadHash;
        this.idempotencyKey = idempotencyKey;
        this.createdAt = createdAt;
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getCallerId() { return callerId; }
    public void setCallerId(String callerId) { this.callerId = callerId; }
    public String getIpAddress() { return ipAddress; }
    public void setIpAddress(String ipAddress) { this.ipAddress = ipAddress; }
    public String getAction() { return action; }
    public void setAction(String action) { this.action = action; }
    public String getPayloadHash() { return payloadHash; }
    public void setPayloadHash(String payloadHash) { this.payloadHash = payloadHash; }
    public String getIdempotencyKey() { return idempotencyKey; }
    public void setIdempotencyKey(String idempotencyKey) { this.idempotencyKey = idempotencyKey; }
    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
