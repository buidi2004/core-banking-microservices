package com.fintech.notification.notification;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class EventIdempotencyStoreTest {

    private final EventIdempotencyStore store = new EventIdempotencyStore();

    @Test
    void firstOccurrenceIsAccepted() {
        assertThat(store.markProcessed("evt-1")).isTrue();
    }

    @Test
    void duplicateOccurrenceIsRejected() {
        assertThat(store.markProcessed("evt-1")).isTrue();
        assertThat(store.markProcessed("evt-1")).isFalse();
        assertThat(store.markProcessed("evt-1")).isFalse();
    }

    @Test
    void distinctEventsAreAcceptedIndependently() {
        assertThat(store.markProcessed("evt-1")).isTrue();
        assertThat(store.markProcessed("evt-2")).isTrue();
        assertThat(store.markProcessed("evt-3")).isTrue();
    }

    @Test
    void forgetAllowsReprocessing() {
        assertThat(store.markProcessed("evt-1")).isTrue();
        assertThat(store.markProcessed("evt-1")).isFalse();

        store.forget("evt-1");

        assertThat(store.markProcessed("evt-1")).isTrue();
    }

    @Test
    void blankEventIdIsTreatedAsProcessable() {
        assertThat(store.markProcessed(null)).isTrue();
        assertThat(store.markProcessed("")).isTrue();
        assertThat(store.markProcessed("   ")).isTrue();
    }
}
