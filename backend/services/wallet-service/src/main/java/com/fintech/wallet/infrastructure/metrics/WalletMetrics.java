package com.fintech.wallet.infrastructure.metrics;

import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import org.springframework.stereotype.Component;

@Component
public class WalletMetrics {

    private final Counter transactionSuccessCounter;
    private final Counter transactionFailureCounter;

    public WalletMetrics(MeterRegistry registry) {
        this.transactionSuccessCounter = Counter.builder("wallet.transactions.success")
                .description("Total successful wallet transactions")
                .register(registry);

        this.transactionFailureCounter = Counter.builder("wallet.transactions.failure")
                .description("Total failed wallet transactions")
                .register(registry);
    }

    public void incrementSuccess() {
        transactionSuccessCounter.increment();
    }

    public void incrementFailure() {
        transactionFailureCounter.increment();
    }
}
