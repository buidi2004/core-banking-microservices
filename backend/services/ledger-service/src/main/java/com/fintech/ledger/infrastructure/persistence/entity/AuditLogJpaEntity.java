package com.fintech.ledger.infrastructure.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "audit_logs")
public class AuditLogJpaEntity {
    @Id
    private UUID id;

    @Column(name = "event_type", nullable = false, length = 50)
    private String eventType;

    @Column(name = "entity_type", nullable = false, length = 50)
    private String entityType;

    @Column(name = "entity_id", nullable = false, length = 36)
    private String entityId;

    @Column
    private String description;

    @Column(name = "performed_by")
    private String performedBy;

    @Column(name = "performed_at", nullable = false)
    private LocalDateTime performedAt;

    @Column(name = "service_name", nullable = false)
    private String serviceName;

    @Column(name = "actor_role")
    private String actorRole;

    @Column(name = "branch_id")
    private String branchId;

    @Column(name = "correlation_id")
    private String correlationId;

    @Column(name = "client_ip")
    private String clientIp;

    @Column(name = "device_id")
    private String deviceId;

    @Column
    private String reason;

    protected AuditLogJpaEntity() {
    }

    public AuditLogJpaEntity(java.util.UUID id, String eventType, String entityType, String entityId,
                             String description, String performedBy, LocalDateTime performedAt,
                             String serviceName, String actorRole, String branchId,
                             String correlationId, String clientIp, String deviceId, String reason) {
        this.id = id;
        this.eventType = eventType;
        this.entityType = entityType;
        this.entityId = entityId;
        this.description = description;
        this.performedBy = performedBy;
        this.performedAt = performedAt;
        this.serviceName = serviceName;
        this.actorRole = actorRole;
        this.branchId = branchId;
        this.correlationId = correlationId;
        this.clientIp = clientIp;
        this.deviceId = deviceId;
        this.reason = reason;
    }

    public UUID getId() { return id; }
    public String getEventType() { return eventType; }
    public String getEntityType() { return entityType; }
    public String getEntityId() { return entityId; }
    public String getDescription() { return description; }
    public String getPerformedBy() { return performedBy; }
    public LocalDateTime getPerformedAt() { return performedAt; }
    public String getServiceName() { return serviceName; }
    public String getActorRole() { return actorRole; }
    public String getBranchId() { return branchId; }
    public String getCorrelationId() { return correlationId; }
    public String getClientIp() { return clientIp; }
    public String getDeviceId() { return deviceId; }
    public String getReason() { return reason; }
}
