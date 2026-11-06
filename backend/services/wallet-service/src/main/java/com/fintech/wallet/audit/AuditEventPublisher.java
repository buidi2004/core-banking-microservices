package com.fintech.wallet.audit;

import com.fintech.common.audit.AuditEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@RequiredArgsConstructor
public class AuditEventPublisher {
    private final KafkaTemplate<String, Object> kafkaTemplate;

    public void publish(AuditEvent event) {
        kafkaTemplate.send(AuditEvent.TOPIC, event.resourceId(), event)
                .whenComplete((result, error) -> {
                    if (error != null) {
                        log.error("Failed to publish audit event {}", event.eventId(), error);
                    }
                });
    }
}
