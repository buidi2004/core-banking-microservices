package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.model.UserSession;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.TimeUnit;

@Service
public class SessionService {

    private final StringRedisTemplate redisTemplate;

    public SessionService(StringRedisTemplate redisTemplate) {
        this.redisTemplate = redisTemplate;
    }

    public UserSession createSession(String userId, String deviceInfo, String ipAddress) {
        String sessionId = UUID.randomUUID().toString();
        Instant now = Instant.now();
        UserSession session = new UserSession(sessionId, userId, deviceInfo, ipAddress, now, now);

        String key = "session:" + userId + ":" + sessionId;
        String val = String.format("%s|%s|%s|%s|%s",
                sessionId, userId,
                deviceInfo != null ? deviceInfo : "Unknown Device",
                ipAddress != null ? ipAddress : "127.0.0.1",
                now.toString());

        redisTemplate.opsForValue().set(key, val, 7, TimeUnit.DAYS);
        return session;
    }

    public List<UserSession> getActiveSessions(String userId) {
        String pattern = "session:" + userId + ":*";
        Set<String> keys = redisTemplate.keys(pattern);
        List<UserSession> sessions = new ArrayList<>();

        if (keys != null) {
            for (String key : keys) {
                String val = redisTemplate.opsForValue().get(key);
                if (val != null) {
                    String[] parts = val.split("\\|", -1);
                    if (parts.length >= 5) {
                        Instant createdAt = Instant.parse(parts[4]);
                        sessions.add(new UserSession(parts[0], parts[1], parts[2], parts[3], createdAt, createdAt));
                    }
                }
            }
        }
        return sessions;
    }

    public void revokeSession(String userId, String sessionId) {
        String key = "session:" + userId + ":" + sessionId;
        redisTemplate.delete(key);
    }

    public void revokeAllSessions(String userId) {
        String pattern = "session:" + userId + ":*";
        Set<String> keys = redisTemplate.keys(pattern);
        if (keys != null && !keys.isEmpty()) {
            redisTemplate.delete(keys);
        }
    }
}
