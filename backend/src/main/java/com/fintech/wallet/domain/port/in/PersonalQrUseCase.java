package com.fintech.wallet.domain.port.in;

import java.util.Map;

public interface PersonalQrUseCase {
    String getPersonalQrPayload(String userId);
    Map<String, Object> scanQr(String qrString);
}
