package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.model.UserSession;
import com.fintech.wallet.domain.port.out.SessionStorePort;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;

import static org.junit.jupiter.api.Assertions.*;

class SessionServiceTest {

    /**
     * Simple in-memory implementation of SessionStorePort.
     * Avoids any dependency on Spring Redis / Mockito for concrete classes.
     */
    private static class InMemorySessionStore implements SessionStorePort {
        private final Map<String, String> store = new HashMap<>();

        @Override
        public void set(String key, String value, long timeout, TimeUnit unit) {
            store.put(key, value);
        }

        @Override
        public String get(String key) {
            return store.get(key);
        }

        @Override
        public void delete(String key) {
            store.remove(key);
        }

        @Override
        public void deleteAll(Set<String> keys) {
            keys.forEach(store::remove);
        }

        @Override
        public Set<String> keys(String pattern) {
            // Convert Redis glob pattern "session:userId:*" to prefix match
            String prefix = pattern.endsWith("*")
                    ? pattern.substring(0, pattern.length() - 1)
                    : pattern;
            return store.keySet().stream()
                    .filter(k -> k.startsWith(prefix))
                    .collect(Collectors.toSet());
        }
    }

    private SessionService sessionService;

    @BeforeEach
    void setUp() {
        sessionService = new SessionService(new InMemorySessionStore());
    }

    @Test
    void createSession_shouldReturnSessionWithCorrectFields() {
        UserSession session = sessionService.createSession("u1", "iOS App", "192.168.1.1");

        assertNotNull(session);
        assertNotNull(session.getSessionId());
        assertEquals("u1", session.getUserId());
        assertEquals("iOS App", session.getDeviceInfo());
        assertEquals("192.168.1.1", session.getIpAddress());
    }

    @Test
    void getActiveSessions_shouldReturnCreatedSessions() {
        sessionService.createSession("u1", "iOS App", "10.0.0.1");
        sessionService.createSession("u1", "Android App", "10.0.0.2");

        List<UserSession> sessions = sessionService.getActiveSessions("u1");

        assertEquals(2, sessions.size());
    }

    @Test
    void getActiveSessions_differentUser_shouldReturnEmpty() {
        sessionService.createSession("u1", "iOS App", "10.0.0.1");

        List<UserSession> sessions = sessionService.getActiveSessions("u2");

        assertTrue(sessions.isEmpty());
    }

    @Test
    void revokeSession_shouldRemoveOnlyThatSession() {
        UserSession s1 = sessionService.createSession("u1", "Device A", "1.1.1.1");
        sessionService.createSession("u1", "Device B", "2.2.2.2");

        sessionService.revokeSession("u1", s1.getSessionId());

        List<UserSession> remaining = sessionService.getActiveSessions("u1");
        assertEquals(1, remaining.size());
        assertFalse(remaining.stream()
                .anyMatch(s -> s.getSessionId().equals(s1.getSessionId())));
    }

    @Test
    void revokeAllSessions_shouldRemoveAllSessionsForUser() {
        sessionService.createSession("u1", "Device A", "1.1.1.1");
        sessionService.createSession("u1", "Device B", "2.2.2.2");

        sessionService.revokeAllSessions("u1");

        assertTrue(sessionService.getActiveSessions("u1").isEmpty());
    }

    @Test
    void revokeAllSessions_shouldNotAffectOtherUsers() {
        sessionService.createSession("u1", "Device A", "1.1.1.1");
        sessionService.createSession("u2", "Device X", "9.9.9.9");

        sessionService.revokeAllSessions("u1");

        assertTrue(sessionService.getActiveSessions("u1").isEmpty());
        assertEquals(1, sessionService.getActiveSessions("u2").size());
    }
}
