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

    // For testing purposes, we can set this flag to force an exception
    private boolean simulateFailure = false;
    private int failureCount = 0;
    
    public void setSimulateFailure(boolean simulateFailure) {
        this.simulateFailure = simulateFailure;
        this.failureCount = 0;
    }

    public int getFailureCount() {
        return failureCount;
    }

    @Override
    // We only use Retry for Task 4. We can keep CircuitBreaker but no fallback so exception propagates.
    @Retry(name = "bankGateway")
    @CircuitBreaker(name = "bankGateway")
    public boolean transferToBank(String bankAccountId, Money amount, String transactionReference) {
        if (simulateFailure) {
            failureCount++;
            log.warn("Mock Bank Gateway: Simulated failure attempt {}", failureCount);
            throw new RuntimeException("Simulated Bank Gateway Timeout/Error");
        }
        
        log.info("Mock Bank Gateway: Transferred {} to bank account {} with txRef {}",
                amount, bankAccountId, transactionReference);
        return true;
    }
}
