package com.fintech.notification.notification;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Tra cứu số điện thoại của người dùng từ identity-service và userId từ wallet-service (API nội bộ)
 * để hiển thị thông báo dạng "TK 0901234567" thay vì wallet UUID và đảm bảo gửi đúng FCM push tokens.
 *
 * Có cache trong bộ nhớ (10 phút) + negative cache 60s để không làm nghẽn các service nội bộ.
 */
@Component
public class UserPhoneResolver {

    private static final Logger log = LoggerFactory.getLogger(UserPhoneResolver.class);
    private static final long TTL_MS = 10 * 60 * 1000L;
    private static final long NEGATIVE_TTL_MS = 60 * 1000L;

    private final RestClient restClient;
    private final RestClient walletClient;
    private final Map<String, CacheEntry> cache = new ConcurrentHashMap<>();
    private final Map<String, CacheEntry> walletUserCache = new ConcurrentHashMap<>();

    public UserPhoneResolver(@Value("${identity.service.url:http://localhost:8081}") String identityServiceUrl) {
        this(identityServiceUrl, "http://localhost:8082");
    }

    @Autowired
    public UserPhoneResolver(
            @Value("${identity.service.url:http://localhost:8081}") String identityServiceUrl,
            @Value("${wallet.service.url:http://localhost:8082}") String walletServiceUrl) {
        org.springframework.http.client.SimpleClientHttpRequestFactory factory =
                new org.springframework.http.client.SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(1000);
        factory.setReadTimeout(1500);

        this.restClient = RestClient.builder()
                .baseUrl(identityServiceUrl)
                .requestFactory(factory)
                .build();

        this.walletClient = RestClient.builder()
                .baseUrl(walletServiceUrl)
                .requestFactory(factory)
                .build();
    }

    public String resolve(String userId) {
        if (userId == null || userId.isBlank()) {
            return null;
        }
        long now = System.currentTimeMillis();
        CacheEntry cached = cache.get(userId);
        if (cached != null && cached.expiresAt() > now) {
            return cached.value();
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

    /**
     * Tra cứu userId (ownerId) từ walletId thông qua wallet-service.
     */
    public String resolveUserIdByWalletId(String walletId) {
        if (walletId == null || walletId.isBlank()) {
            return null;
        }
        long now = System.currentTimeMillis();
        CacheEntry cached = walletUserCache.get(walletId);
        if (cached != null && cached.expiresAt() > now) {
            return cached.value();
        }
        try {
            @SuppressWarnings("unchecked")
            Map<String, Object> body = walletClient.get()
                    .uri("/api/v1/wallets/{walletId}", walletId)
                    .retrieve()
                    .body(Map.class);
            if (body != null && body.get("data") instanceof Map<?, ?> dataMap) {
                Object owner = dataMap.get("ownerId") != null ? dataMap.get("ownerId") : dataMap.get("userId");
                String userId = owner != null ? String.valueOf(owner) : null;
                if (userId != null && !userId.isBlank()) {
                    walletUserCache.put(walletId, new CacheEntry(userId, now + TTL_MS));
                    return userId;
                }
            }
            walletUserCache.put(walletId, new CacheEntry(null, now + NEGATIVE_TTL_MS));
            return null;
        } catch (Exception e) {
            log.debug("Không lấy được ownerId cho walletId={}: {}", walletId, e.getMessage());
            walletUserCache.put(walletId, new CacheEntry(null, now + NEGATIVE_TTL_MS));
            return null;
        }
    }

    /**
     * Tra cứu số điện thoại của chủ ví từ walletId.
     */
    public String resolvePhoneByWalletId(String walletId) {
        if (walletId == null || walletId.isBlank()) {
            return null;
        }
        String userId = resolveUserIdByWalletId(walletId);
        if (userId != null && !userId.isBlank()) {
            return resolve(userId);
        }
        return null;
    }

    private record CacheEntry(String value, long expiresAt) {
    }
}
