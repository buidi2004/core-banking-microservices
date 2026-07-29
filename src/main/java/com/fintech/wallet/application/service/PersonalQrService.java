package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.port.in.PersonalQrUseCase;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;

@Service
public class PersonalQrService implements PersonalQrUseCase {

    @Override
    public String getPersonalQrPayload(String userId) {
        return "WALLET_QR:v1:user:" + userId;
    }

    @Override
    public Map<String, Object> scanQr(String qrString) {
        Map<String, Object> result = new HashMap<>();
        if (qrString != null && qrString.startsWith("WALLET_QR:")) {
            String[] parts = qrString.split(":");
            result.put("type", "WALLET_TRANSFER");
            result.put("targetUserId", parts.length >= 4 ? parts[3] : "");
        } else if (qrString != null && qrString.startsWith("000201")) {
            result.put("type", "VIETQR");
            result.put("payload", qrString);
        } else if (qrString != null && qrString.startsWith("MERCHANT:")) {
            result.put("type", "MERCHANT_PAYMENT");
            result.put("merchantOrderId", qrString.replace("MERCHANT:", ""));
        } else {
            result.put("type", "UNKNOWN");
            result.put("raw", qrString);
        }
        return result;
    }
}
