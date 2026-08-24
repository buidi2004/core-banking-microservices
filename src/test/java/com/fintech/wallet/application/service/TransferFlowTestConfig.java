package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.port.out.DistributedLockPort;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;

import java.util.function.Supplier;

@TestConfiguration
public class TransferFlowTestConfig {

    @Bean
    public DistributedLockPort distributedLockPort() {
        return new DistributedLockPort() {
            @Override
            public <T> T executeWithLock(String lockKey, long timeoutSeconds, Supplier<T> supplier) {
                return supplier.get();
            }
        };
    }
}
