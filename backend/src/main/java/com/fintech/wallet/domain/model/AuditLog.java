package com.fintech.wallet.domain.model;

import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * Domain Entity: AuditLog (Immutable)
 * Pure Java - No Spring / JPA annotations.
 */
public class AuditLog {
    private final String id;
    private final String callerId;
    private final String ipAddress;
    private final String action;
    private final String payloadHash;
    private final Instant createdAt;

    public AuditLog(String id, String callerId, String ipAddress, String action, String payloadHash, Instant createdAt) {
        this.id = id != null ? id : UUID.randomUUID().toString();
        this.callerId = callerId;
        this.ipAddress = ipAddress;
        this.action = action;
        this.payloadHash = payloadHash;
        this.createdAt = createdAt != null ? createdAt : Instant.now();
    }

    public static AuditLog record(String callerId, String ipAddress, String action, String payloadHash) {
        return new AuditLog(
            UUID.randomUUID().toString(),
            callerId,
            ipAddress,
            action,
            payloadHash,
            Instant.now()
        );
    }

    public String getId() { return id; }
    public String getCallerId() { return callerId; }
    public String getIpAddress() { return ipAddress; }
    public String getAction() { return action; }
    public String getPayloadHash() { return payloadHash; }
    public Instant getCreatedAt() { return createdAt; }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        AuditLog auditLog = (AuditLog) o;
        return Objects.equals(id, auditLog.id);
    }

    @Override
    public int hashCode() {
        return Objects.hash(id);
    }
}
