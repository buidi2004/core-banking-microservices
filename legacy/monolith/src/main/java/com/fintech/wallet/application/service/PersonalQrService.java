package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.port.in.PersonalQrUseCase;
import com.fintech.wallet.domain.port.in.UserProfileUseCase;
import com.fintech.wallet.domain.port.in.VietQrUseCase;
import com.fintech.wallet.domain.port.out.UserPersistencePort;
import org.springframework.stereotype.Service;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;

/**
 * PersonalQrService
 * Generates SenBank internal QR payloads using the user's phone number as the account number.
 * QR Format: senbank://transfer?phone={phone}&name={name}&bank=SENBANK
 * This is compatible with the VietQR scan flow in the mobile app (ScanQRScreen.tsx).
 */
@Service
public class PersonalQrService implements PersonalQrUseCase {

    private final UserPersistencePort userPersistencePort;
    private final UserProfileUseCase userProfileUseCase;
    private final VietQrUseCase vietQrUseCase;

    public PersonalQrService(UserPersistencePort userPersistencePort, UserProfileUseCase userProfileUseCase, VietQrUseCase vietQrUseCase) {
        this.userPersistencePort = userPersistencePort;
        this.userProfileUseCase = userProfileUseCase;
        this.vietQrUseCase = vietQrUseCase;
    }

    @Override
    public String getPersonalQrPayload(String userId) {
        // Look up the user to get their phone number (which is the SenBank account number)
        return userPersistencePort.findUserById(userId)
            .map(user -> {
                String phone = user.getPhoneNumber();
                // Get real name from profile
                String name = userProfileUseCase.getProfile(userId).getFullName();
                if (name == null || name.isBlank()) {
                    name = "SENBANK USER";
                }
                return vietQrUseCase.generateQr("SENBANK", phone, java.math.BigDecimal.ZERO, "Chuyen tien " + name).getQrCodeString();
            })
            .orElseGet(() -> vietQrUseCase.generateQr("SENBANK", "unknown", java.math.BigDecimal.ZERO, "Chuyen tien").getQrCodeString());
    }

    @Override
    public Map<String, Object> scanQr(String qrString) {
        Map<String, Object> result = new HashMap<>();
        if (qrString != null && (qrString.startsWith("senbank://") || qrString.startsWith("SENBANK:"))) {
            result.put("type", "SENBANK_INTERNAL_TRANSFER");
            result.put("bankCode", "SENBANK");
            result.put("bankName", "SenBank (Nội bộ)");
            if (qrString.contains("phone=")) {
                String[] params = qrString.substring(qrString.indexOf("?") + 1).split("&");
                for (String param : params) {
                    String[] kv = param.split("=");
                    if (kv.length == 2) {
                        String key = kv[0];
                        String value = kv[1].replace("+", " ");
                        result.put(key, value);
                        if ("phone".equals(key)) {
                            result.put("accountNumber", value);
                        }
                    }
                }
            } else {
                result.put("accountNumber", qrString.replace("SENBANK:", "").trim());
            }
        } else if (qrString != null && qrString.startsWith("WALLET_QR:")) {
            String[] parts = qrString.split(":");
            result.put("type", "WALLET_TRANSFER");
            result.put("targetUserId", parts.length >= 4 ? parts[3] : "");
        } else if (qrString != null && qrString.startsWith("000201")) {
            if (qrString.contains("0007SENBANK01")) {
                result.put("type", "SENBANK_INTERNAL_TRANSFER");
                result.put("bankCode", "SENBANK");
                result.put("bankName", "SenBank (Nội bộ)");
                
                // Extract account number: "0007SENBANK01" + 2 digit length + account number
                int idx = qrString.indexOf("0007SENBANK01");
                if (idx != -1) {
                    int lenStart = idx + 13;
                    if (lenStart + 2 <= qrString.length()) {
                        try {
                            int accLen = Integer.parseInt(qrString.substring(lenStart, lenStart + 2));
                            if (lenStart + 2 + accLen <= qrString.length()) {
                                result.put("accountNumber", qrString.substring(lenStart + 2, lenStart + 2 + accLen));
                            }
                        } catch (NumberFormatException ignored) {}
                    }
                }
            } else {
                result.put("type", "VIETQR");
                result.put("payload", qrString);
            }
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
