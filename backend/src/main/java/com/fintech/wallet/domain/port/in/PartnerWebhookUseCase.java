package com.fintech.wallet.domain.port.in;

import java.math.BigDecimal;
import java.util.Map;

public interface PartnerWebhookUseCase {
    void processNapasCallback(Map<String, Object> payload);
    void processBankDepositNotify(String walletId, BigDecimal amount, String bankTxRef);
}
