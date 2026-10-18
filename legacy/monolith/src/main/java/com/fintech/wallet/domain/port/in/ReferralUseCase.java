package com.fintech.wallet.domain.port.in;

import com.fintech.wallet.domain.model.ReferralInfo;

import java.util.List;
import java.util.Map;

public interface ReferralUseCase {
    ReferralInfo getReferralInfo(String userId);
    void applyReferralCode(String userId, String referralCode);
    List<Map<String, Object>> getReferralHistory(String userId);
}
