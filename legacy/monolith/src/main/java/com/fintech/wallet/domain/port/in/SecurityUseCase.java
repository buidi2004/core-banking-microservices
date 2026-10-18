package com.fintech.wallet.domain.port.in;

import java.util.List;
import java.util.Map;

public interface SecurityUseCase {
    void registerBiometric(String userId, String biometricToken);
    String verifyBiometric(String userId, String biometricToken);
    List<Map<String, Object>> getLoginHistory(String userId);
    void enable2FA(String userId);
    void disable2FA(String userId);
}
