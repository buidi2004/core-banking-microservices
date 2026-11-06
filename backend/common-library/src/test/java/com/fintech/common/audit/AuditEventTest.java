package com.fintech.common.audit;

import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class AuditEventTest {
    @Test
    void normalizesOptionalSnapshots() {
        AuditEvent event = new AuditEvent(
                UUID.randomUUID(), Instant.now(), "payment-service", "TRANSFER_CREATED",
                "TRANSFER", "tx-1", "user-1", "ROLE_MANAGER", "BR_Q1",
                "corr-1", "127.0.0.1", "device-1", null, null, "review");

        assertEquals(Map.of(), event.before());
        assertEquals(Map.of(), event.after());
    }

    @Test
    void requiresActionAndService() {
        assertThrows(IllegalArgumentException.class, () -> new AuditEvent(
                UUID.randomUUID(), Instant.now(), "", "ACTION",
                "RESOURCE", "id", null, null, null, null, null, null, null, null, null));
        assertThrows(IllegalArgumentException.class, () -> new AuditEvent(
                UUID.randomUUID(), Instant.now(), "service", "",
                "RESOURCE", "id", null, null, null, null, null, null, null, null, null));
    }
}
