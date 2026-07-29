package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.model.Money;
import com.fintech.wallet.domain.port.in.DepositMoneyUseCase;
import com.fintech.wallet.domain.port.in.PartnerWebhookUseCase;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.Map;
import java.util.UUID;

@Service
public class PartnerWebhookService implements PartnerWebhookUseCase {

    private static final Logger log = LoggerFactory.getLogger(PartnerWebhookService.class);

    private final DepositMoneyUseCase depositMoneyUseCase;

    public PartnerWebhookService(DepositMoneyUseCase depositMoneyUseCase) {
        this.depositMoneyUseCase = depositMoneyUseCase;
    }

    @Override
    public void processNapasCallback(Map<String, Object> payload) {
        log.info("Received Napas callback: {}", payload);
    }

    @Override
    public void processBankDepositNotify(String walletId, BigDecimal amount, String bankTxRef) {
        log.info("Received external bank deposit notify for walletId={}, amount={}, ref={}", walletId, amount, bankTxRef);
        if (depositMoneyUseCase != null && walletId != null && amount != null) {
            depositMoneyUseCase.deposit("DEP_WEBHOOK_" + UUID.randomUUID().toString().substring(0, 8), walletId, Money.of(amount, "VND"));
        }
    }
}
