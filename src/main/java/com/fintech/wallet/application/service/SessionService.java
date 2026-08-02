package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.model.UserSession;
import com.fintech.wallet.domain.port.in.SessionUseCase;
import com.fintech.wallet.domain.port.out.SessionStorePort;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.TimeUnit;

/**
 * Application Service: manages user sessions via a pluggable SessionStorePort.
 * Depends on the domain port — not on Spring Redis classes directly.
 */
@Service
public class SessionService implements SessionUseCase {

    private final SessionStorePort sessionStore;

    public SessionService(SessionStorePort sessionStore) {
        this.sessionStore = sessionStore;
    }

    public UserSession createSession(String userId, String deviceInfo, String ipAddress) {
        String sessionId = UUID.randomUUID().toString();
        Instant now = Instant.now();
        UserSession session = new UserSession(sessionId, userId, deviceInfo, ipAddress, now, now);

        String key = "session:" + userId + ":" + sessionId;
        String val = String.format("%s|%s|%s|%s|%s",
                sessionId, userId,
                deviceInfo  != null ? deviceInfo  : "Unknown Device",
                ipAddress   != null ? ipAddress   : "127.0.0.1",
                now.toString());

        sessionStore.set(key, val, 7, TimeUnit.DAYS);
        return session;
    }

    public List<UserSession> getActiveSessions(String userId) {
        String pattern = "session:" + userId + ":*";
        Set<String> keys = sessionStore.keys(pattern);
        List<UserSession> sessions = new ArrayList<>();

        if (keys != null) {
            for (String key : keys) {
                String val = sessionStore.get(key);
                if (val != null) {
                    String[] parts = val.split("\\|", -1);
                    if (parts.length >= 5) {
                        Instant createdAt = Instant.parse(parts[4]);
                        sessions.add(new UserSession(
                                parts[0], parts[1], parts[2], parts[3],
                                createdAt, createdAt));
                    }
                }
            }
        }
        return sessions;
    }

    public void revokeSession(String userId, String sessionId) {
        sessionStore.delete("session:" + userId + ":" + sessionId);
    }

    public void revokeAllSessions(String userId) {
        Set<String> keys = sessionStore.keys("session:" + userId + ":*");
        if (keys != null && !keys.isEmpty()) {
            sessionStore.deleteAll(keys);
        }
    }
}
