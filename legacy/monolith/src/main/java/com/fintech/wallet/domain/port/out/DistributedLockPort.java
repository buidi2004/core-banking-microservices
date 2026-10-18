package com.fintech.wallet.domain.port.out;

import java.util.function.Supplier;

public interface DistributedLockPort {
    <T> T executeWithLock(String lockKey, long timeoutSeconds, Supplier<T> supplier);
}
