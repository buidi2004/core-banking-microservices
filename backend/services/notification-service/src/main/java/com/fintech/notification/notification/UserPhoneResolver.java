package com.fintech.notification.notification;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Tra cứu số điện thoại của người dùng từ identity-service (API nội bộ)
 * để hiển thị thông báo dạng "TK 0901234567" thay vì wallet UUID.
 *
 * Có cache trong bộ nhớ (10 phút) + negative cache 60s để không gọi lại
 * identity mỗi lần có biến động số dư.
 */
@Component
public class UserPhoneResolver {

    private static final Logger log = LoggerFactory.getLogger(UserPhoneResolver.class);
    private static final long TTL_MS = 10 * 60 * 1000L;
    private static final long NEGATIVE_TTL_MS = 60 * 1000L;

    private final RestClient restClient;
    private final Map<String, CacheEntry> cache = new ConcurrentHashMap<>();

    public UserPhoneResolver(@Value("${identity.service.url:http://localhost:8081}") String identityServiceUrl) {
        this.restClient = RestClient.builder().baseUrl(identityServiceUrl).build();
    }

    public String resolve(String userId) {
        if (userId == null || userId.isBlank()) {
            return null;
        }
        long now = System.currentTimeMillis();
        CacheEntry cached = cache.get(userId);
        if (cached != null && cached.expiresAt() > now) {
            return cached.phone();
        }
        try {
            @SuppressWarnings("unchecked")
            Map<String, Object> body = restClient.get()
                    .uri("/api/v1/internal/users/{id}", userId)
                    .retrieve()
                    .body(Map.class);
            String phone = body != null && body.get("phoneNumber") != null
                    ? String.valueOf(body.get("phoneNumber"))
                    : null;
            cache.put(userId, new CacheEntry(phone, now + TTL_MS));
            return phone;
        } catch (Exception e) {
            log.debug("Không lấy được số điện thoại cho userId={}: {}", userId, e.getMessage());
            cache.put(userId, new CacheEntry(null, now + NEGATIVE_TTL_MS));
            return null;
        }
    }

    private record CacheEntry(String phone, long expiresAt) {
    }
}
