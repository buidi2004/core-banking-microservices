package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.port.in.PersonalQrUseCase;
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

    public PersonalQrService(UserPersistencePort userPersistencePort) {
        this.userPersistencePort = userPersistencePort;
    }

    @Override
    public String getPersonalQrPayload(String userId) {
        // Look up the user to get their phone number (which is the SenBank account number)
        return userPersistencePort.findUserById(userId)
            .map(user -> {
                String phone = user.getPhoneNumber();
                // SenBank: phone number IS the account number
                String name = "SENBANK USER";
                String encodedName = URLEncoder.encode(name, StandardCharsets.UTF_8);
                return "senbank://transfer?phone=" + phone + "&name=" + encodedName + "&bank=SENBANK";
            })
            .orElse("senbank://transfer?phone=unknown&name=UNKNOWN&bank=SENBANK");
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
                        result.put(kv[0], kv[1].replace("+", " "));
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
