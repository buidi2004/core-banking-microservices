package com.fintech.common.audit;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;

/**
 * Immutable audit envelope shared by all services.
 */
public record AuditEvent(
        UUID eventId,
        Instant occurredAt,
        String service,
        String action,
        String resourceType,
        String resourceId,
        String actorId,
        String actorRole,
        String branchId,
        String correlationId,
        String clientIp,
        String deviceId,
        Map<String, Object> before,
        Map<String, Object> after,
        String reason
) {
    public static final String TOPIC = "banking.audit.events.v1";

    public AuditEvent {
        if (eventId == null) {
            throw new IllegalArgumentException("eventId is required");
        }
        if (occurredAt == null) {
            throw new IllegalArgumentException("occurredAt is required");
        }
        if (service == null || service.isBlank()) {
            throw new IllegalArgumentException("service is required");
        }
        if (action == null || action.isBlank()) {
            throw new IllegalArgumentException("action is required");
        }
        if (resourceType == null || resourceType.isBlank()) {
            throw new IllegalArgumentException("resourceType is required");
        }
        before = before == null ? Map.of() : Map.copyOf(before);
        after = after == null ? Map.of() : Map.copyOf(after);
    }
}
