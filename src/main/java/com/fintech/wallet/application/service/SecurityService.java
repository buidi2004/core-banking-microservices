package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.port.in.SecurityUseCase;
import com.fintech.wallet.infrastructure.security.JwtTokenProvider;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class SecurityService implements SecurityUseCase {

    private static final Logger log = LoggerFactory.getLogger(SecurityService.class);

    private final JwtTokenProvider tokenProvider;
    private final Map<String, String> biometricStore = new ConcurrentHashMap<>();
    private final Map<String, Boolean> twoFaStore = new ConcurrentHashMap<>();
    private final List<Map<String, Object>> loginHistory = new ArrayList<>();

    public SecurityService(JwtTokenProvider tokenProvider) {
        this.tokenProvider = tokenProvider;
    }

    @Override
    public void registerBiometric(String userId, String biometricToken) {
        biometricStore.put(userId, biometricToken);
        log.info("Registered biometric token for user={}", userId);
    }

    @Override
    public String verifyBiometric(String userId, String biometricToken) {
        String registered = biometricStore.get(userId);
        if (registered != null && registered.equals(biometricToken)) {
            return tokenProvider.generatePinToken(userId);
        }
        throw new IllegalArgumentException("Invalid biometric token verification");
    }

    @Override
    public List<Map<String, Object>> getLoginHistory(String userId) {
        List<Map<String, Object>> history = new ArrayList<>();
        Map<String, Object> entry = new HashMap<>();
        entry.put("timestamp", Instant.now().minusSeconds(3600).toString());
        entry.put("device", "iOS iPhone 15 Pro");
        entry.put("ip", "113.161.42.10");
        entry.put("status", "SUCCESS");
        history.add(entry);
        return history;
    }

    @Override
    public void enable2FA(String userId) {
        twoFaStore.put(userId, true);
        log.info("Enabled 2FA for user={}", userId);
    }

    @Override
    public void disable2FA(String userId) {
        twoFaStore.put(userId, false);
        log.info("Disabled 2FA for user={}", userId);
    }
}
