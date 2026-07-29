package com.fintech.wallet.infrastructure.persistence.adapter;

import com.fintech.wallet.domain.port.out.TransactionalOperationPort;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.function.Supplier;

/**
 * Infrastructure Adapter: SpringTransactionalAdapter
 * Implements TransactionalOperationPort using Spring's @Transactional.
 * Wraps any group of persistence operations in a single DB transaction.
 */
@Component
public class SpringTransactionalAdapter implements TransactionalOperationPort {

    @Override
    @Transactional
    public <T> T executeInTransaction(Supplier<T> action) {
        return action.get();
    }
}
