package com.fintech.wallet.domain.port.out;

import java.util.function.Supplier;

/**
 * Output Port: TransactionalOperationPort
 * Ensures that a group of operations (e.g. saving 2 wallets + 1 transaction)
 * are executed atomically — either all succeed or all rollback.
 * Infrastructure decides the actual mechanism (Spring @Transactional, JDBC, etc.).
 */
public interface TransactionalOperationPort {
    <T> T executeInTransaction(Supplier<T> action);
}
