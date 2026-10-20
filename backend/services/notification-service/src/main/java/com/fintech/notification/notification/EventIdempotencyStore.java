package com.fintech.notification.notification;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class EventIdempotencyStore {

    private static final Logger log = LoggerFactory.getLogger(EventIdempotencyStore.class);
    private static final Duration TTL = Duration.ofHours(24);

    private final Map<String, Instant> processed = new ConcurrentHashMap<>();

    public boolean markProcessed(String eventId) {
        cleanupIfNeeded();
        if (eventId == null || eventId.isBlank()) {
            return true;
        }
        Instant now = Instant.now();
        Instant previous = processed.putIfAbsent(eventId, now);
        if (previous != null) {
            log.info("Duplicate event ignored: {}", eventId);
            return false;
        }
        return true;
    }

    public void forget(String eventId) {
        if (eventId != null) {
            processed.remove(eventId);
        }
    }

    private void cleanupIfNeeded() {
        if (processed.size() < 10_000) {
            return;
        }
        Instant threshold = Instant.now().minus(TTL);
        processed.entrySet().removeIf(e -> e.getValue().isBefore(threshold));
    }
}
