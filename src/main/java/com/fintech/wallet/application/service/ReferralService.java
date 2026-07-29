package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.model.ReferralInfo;
import com.fintech.wallet.domain.port.in.ReferralUseCase;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class ReferralService implements ReferralUseCase {

    @Override
    public ReferralInfo getReferralInfo(String userId) {
        String code = "REF" + userId.substring(0, Math.min(6, userId.length())).toUpperCase();
        return new ReferralInfo(userId, code, new BigDecimal("150000"), 3);
    }

    @Override
    public void applyReferralCode(String userId, String referralCode) {
        // Apply referral code logic
    }

    @Override
    public List<Map<String, Object>> getReferralHistory(String userId) {
        List<Map<String, Object>> history = new ArrayList<>();
        Map<String, Object> h1 = new HashMap<>();
        h1.put("friendName", "Nguyen Van B");
        h1.put("reward", new BigDecimal("50000"));
        h1.put("date", Instant.now().minusSeconds(86400).toString());
        history.add(h1);
        return history;
    }
}
