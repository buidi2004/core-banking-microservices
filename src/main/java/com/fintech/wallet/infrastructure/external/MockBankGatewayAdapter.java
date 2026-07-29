package com.fintech.wallet.infrastructure.external;

import com.fintech.wallet.domain.model.Money;
import com.fintech.wallet.domain.port.out.BankGatewayPort;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;
import io.github.resilience4j.retry.annotation.Retry;

@Component
public class MockBankGatewayAdapter implements BankGatewayPort {

    private static final Logger log = LoggerFactory.getLogger(MockBankGatewayAdapter.class);

    @Override
    @CircuitBreaker(name = "bankGateway", fallbackMethod = "transferToBankFallback")
    @Retry(name = "bankGateway")
    public boolean transferToBank(String bankAccountId, Money amount, String transactionReference) {
        log.info("Mock Bank Gateway: Transferred {} to bank account {} with txRef {}",
                amount, bankAccountId, transactionReference);
        return true;
    }

    public boolean transferToBankFallback(String bankAccountId, Money amount, String transactionReference, Throwable t) {
        log.error("Circuit Breaker Triggered: Bank Gateway transfer failed for bankAccountId={} txRef={}: {}",
                bankAccountId, transactionReference, t.getMessage());
        return false;
    }
}
