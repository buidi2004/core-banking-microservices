package com.fintech.wallet.domain.port.in;

import com.fintech.wallet.domain.model.LegalConsent;
import com.fintech.wallet.domain.model.UserLimitStatus;

import java.util.Map;

public interface LegalConfigUseCase {
    Map<String, Object> getUserLimits(String userId);
    String getTermsOfService();
    LegalConsent recordConsent(String userId, String termsVersion, String ipAddress, String userAgent);

    /**
     * Returns the user's dynamic limit status including spent and remaining amounts.
     * Unlike getUserLimits() which returns static config, this calculates actual usage.
     */
    UserLimitStatus getUserLimitStatus(String userId);
}
