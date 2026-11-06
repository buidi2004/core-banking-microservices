package com.fintech.ledger.infrastructure.kafka;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fintech.common.audit.AuditEvent;
import com.fintech.ledger.infrastructure.persistence.repository.SpringAuditLogRepository;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class AuditKafkaConsumerTest {
    @Test
    void ignoresDuplicateAuditEvents() throws Exception {
        SpringAuditLogRepository repository = mock(SpringAuditLogRepository.class);
        ObjectMapper objectMapper = new ObjectMapper().findAndRegisterModules();
        AuditKafkaConsumer consumer = new AuditKafkaConsumer(objectMapper, repository);
        UUID eventId = UUID.randomUUID();
        AuditEvent event = new AuditEvent(
                eventId, Instant.parse("2026-11-05T08:00:00Z"), "payment-service",
                "TRANSFER_CREATED", "TRANSFER", "tx-1", "user-1", "ROLE_MANAGER",
                "BR_Q1", "corr-1", "127.0.0.1", "device-1",
                Map.of(), Map.of(), "review");

        when(repository.existsById(eventId)).thenReturn(true);

        consumer.onAuditEvent(objectMapper.writeValueAsString(event));

        verify(repository, never()).save(any());
    }
}
