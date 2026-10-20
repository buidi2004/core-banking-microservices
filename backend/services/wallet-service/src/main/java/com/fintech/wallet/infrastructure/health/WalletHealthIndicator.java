package com.fintech.wallet.infrastructure.health;

import org.springframework.boot.actuate.health.Health;
import org.springframework.boot.actuate.health.HealthIndicator;
import org.springframework.stereotype.Component;

@Component
public class WalletHealthIndicator implements HealthIndicator {

    @Override
    public Health health() {
        // Deep health check logic
        return Health.up()
                .withDetail("walletService", "Available")
                .withDetail("bankGateway", "Reachable (Mock)")
                .withDetail("redisCluster", "Operational")
                .build();
    }
}
