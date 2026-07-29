package com.fintech.wallet.domain.port.in;

import com.fintech.wallet.domain.model.LegalConsent;

import java.util.Map;

public interface LegalConfigUseCase {
    Map<String, Object> getUserLimits(String userId);
    String getTermsOfService();
    LegalConsent recordConsent(String userId, String termsVersion, String ipAddress, String userAgent);
}
