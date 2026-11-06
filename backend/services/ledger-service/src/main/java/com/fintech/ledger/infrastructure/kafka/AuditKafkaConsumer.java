package com.fintech.ledger.infrastructure.kafka;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fintech.common.audit.AuditEvent;
import com.fintech.ledger.infrastructure.persistence.entity.AuditLogJpaEntity;
import com.fintech.ledger.infrastructure.persistence.repository.SpringAuditLogRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.ZoneOffset;

@Slf4j
@Component
@RequiredArgsConstructor
public class AuditKafkaConsumer {
    private final ObjectMapper objectMapper;
    private final SpringAuditLogRepository repository;

    @Transactional
    @KafkaListener(topics = KafkaTopicConfig.TOPIC_AUDIT_EVENTS,
            groupId = "ledger-audit-storage-group")
    public void onAuditEvent(@Payload String payload) {
        final AuditEvent event;
        try {
            event = objectMapper.readValue(payload, AuditEvent.class);
        } catch (JsonProcessingException exception) {
            throw new IllegalArgumentException("Invalid audit event payload", exception);
        }

        if (repository.existsById(event.eventId())) {
            log.debug("Ignoring duplicate audit event {}", event.eventId());
            return;
        }

        repository.save(new AuditLogJpaEntity(
                event.eventId(),
                event.action(),
                event.resourceType(),
                event.resourceId() == null ? "" : event.resourceId(),
                event.service() + ": " + event.action(),
                event.actorId(),
                LocalDateTime.ofInstant(event.occurredAt(), ZoneOffset.UTC),
                event.service(),
                event.actorRole(),
                event.branchId(),
                event.correlationId(),
                event.clientIp(),
                event.deviceId(),
                event.reason()));
    }
}
