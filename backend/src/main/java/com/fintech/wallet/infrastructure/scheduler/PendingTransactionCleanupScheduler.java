package com.fintech.wallet.infrastructure.scheduler;

import com.fintech.wallet.domain.model.Transaction;
import com.fintech.wallet.domain.model.TransactionStatus;
import com.fintech.wallet.domain.port.out.TransactionPersistencePort;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;

@Component
public class PendingTransactionCleanupScheduler {

    private static final Logger log = LoggerFactory.getLogger(PendingTransactionCleanupScheduler.class);
    private final TransactionPersistencePort transactionPersistencePort;

    public PendingTransactionCleanupScheduler(TransactionPersistencePort transactionPersistencePort) {
        this.transactionPersistencePort = transactionPersistencePort;
    }

    @Scheduled(fixedDelay = 60000) // Run every 60 seconds
    public void cleanupPendingTransactions() {
        Instant threshold = Instant.now().minus(15, ChronoUnit.MINUTES);
        List<Transaction> expiredTransactions = transactionPersistencePort.findExpiredPendingTransactions(threshold);

        if (!expiredTransactions.isEmpty()) {
            log.info("Found {} pending transactions older than 15 minutes. Marking as EXPIRED.", expiredTransactions.size());
            for (Transaction tx : expiredTransactions) {
                tx.markFailed(); // Using FAILED because EXPIRED is not in TransactionStatus enum.
                transactionPersistencePort.saveTransaction(tx);
            }
        }
    }
}
