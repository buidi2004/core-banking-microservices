package com.fintech.wallet.infrastructure.amqp.consumer;

import com.fintech.wallet.application.service.LedgerService;
import com.fintech.wallet.domain.model.AccountType;
import com.fintech.wallet.domain.model.EntryType;
import com.fintech.wallet.domain.model.LedgerAccount;
import com.fintech.wallet.domain.model.LedgerPosting;
import com.fintech.wallet.domain.model.Transaction;
import com.fintech.wallet.domain.model.TransactionEvent;
import com.fintech.wallet.domain.port.out.TransactionPersistencePort;
import com.fintech.wallet.infrastructure.config.RabbitMqConfig;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.TimeUnit;

@Component
public class LedgerConsumer {

    private static final Logger log = LoggerFactory.getLogger(LedgerConsumer.class);

    private final LedgerService ledgerService;
    private final TransactionPersistencePort transactionPersistencePort;
    private final StringRedisTemplate redisTemplate;

    public LedgerConsumer(LedgerService ledgerService, 
                          TransactionPersistencePort transactionPersistencePort,
                          StringRedisTemplate redisTemplate) {
        this.ledgerService = ledgerService;
        this.transactionPersistencePort = transactionPersistencePort;
        this.redisTemplate = redisTemplate;
    }

    @RabbitListener(queues = RabbitMqConfig.QUEUE_LEDGER)
    public void receiveMessage(TransactionEvent event) {
        String idempotencyKey = "processed:event:ledger:" + event.getEventId();
        Boolean isNew = redisTemplate.opsForValue().setIfAbsent(idempotencyKey, "1", 24, TimeUnit.HOURS);

        if (Boolean.FALSE.equals(isNew)) {
            log.info("Duplicate event ignored in LedgerConsumer: {}", event.getEventId());
            return;
        }

        log.info("Processing ledger double-entry posting for transaction: {}", event.getTransactionId());
        try {
            Optional<Transaction> txOpt = transactionPersistencePort.findTransactionById(event.getTransactionId());
            if (txOpt.isEmpty()) {
                log.warn("Transaction {} not found for ledger posting", event.getTransactionId());
                redisTemplate.delete(idempotencyKey); // Delete key to allow retry
                throw new RuntimeException("Transaction not found, forcing retry");
            }
            Transaction tx = txOpt.get();

            // Get or create system cash/liability accounts
            List<LedgerAccount> accounts = ledgerService.getAllAccounts();
            LedgerAccount bankAssetAccount = accounts.stream()
                    .filter(a -> "BANK_SETTLEMENT".equals(a.getAccountName()))
                    .findFirst()
                    .orElseGet(() -> ledgerService.createAccount("BANK_SETTLEMENT", AccountType.ASSET, "VND"));



            List<LedgerPosting> postings = new ArrayList<>();
            String entryId = UUID.randomUUID().toString();

            LedgerAccount sourceCustomerAccount = null;
            LedgerAccount targetCustomerAccount = null;
            if (tx.getSourceWalletId() != null) {
                sourceCustomerAccount = accounts.stream()
                        .filter(a -> ("CUSTOMER_DEPOSITS_" + tx.getSourceWalletId()).equals(a.getAccountName()))
                        .findFirst()
                        .orElseGet(() -> ledgerService.createAccount("CUSTOMER_DEPOSITS_" + tx.getSourceWalletId(), AccountType.LIABILITY, "VND"));
            }
            if (tx.getTargetWalletId() != null) {
                targetCustomerAccount = accounts.stream()
                        .filter(a -> ("CUSTOMER_DEPOSITS_" + tx.getTargetWalletId()).equals(a.getAccountName()))
                        .findFirst()
                        .orElseGet(() -> ledgerService.createAccount("CUSTOMER_DEPOSITS_" + tx.getTargetWalletId(), AccountType.LIABILITY, "VND"));
            }

            switch (tx.getType()) {
                case DEPOSIT:
                    // Nạp tiền: Bank Asset (+) DEBIT, Target Customer Deposit Liability (+) CREDIT
                    postings.add(new LedgerPosting(UUID.randomUUID().toString(), entryId, bankAssetAccount.getId(), EntryType.DEBIT, tx.getAmount().getAmount()));
                    postings.add(new LedgerPosting(UUID.randomUUID().toString(), entryId, targetCustomerAccount.getId(), EntryType.CREDIT, tx.getAmount().getAmount()));
                    break;
                case WITHDRAWAL:
                    // Rút tiền: Source Customer Deposit Liability (-) DEBIT, Bank Asset (-) CREDIT
                    postings.add(new LedgerPosting(UUID.randomUUID().toString(), entryId, sourceCustomerAccount.getId(), EntryType.DEBIT, tx.getAmount().getAmount()));
                    postings.add(new LedgerPosting(UUID.randomUUID().toString(), entryId, bankAssetAccount.getId(), EntryType.CREDIT, tx.getAmount().getAmount()));
                    break;
                case TRANSFER:
                    // Chuyển tiền nội bộ: Source Customer Liability DEBIT, Target Customer Liability CREDIT
                    postings.add(new LedgerPosting(UUID.randomUUID().toString(), entryId, sourceCustomerAccount.getId(), EntryType.DEBIT, tx.getAmount().getAmount()));
                    postings.add(new LedgerPosting(UUID.randomUUID().toString(), entryId, targetCustomerAccount.getId(), EntryType.CREDIT, tx.getAmount().getAmount()));
                    break;
                case REVERSAL:
                    // Hoàn tiền (đảo ngược): Target Customer Liability CREDIT, Source Customer Liability DEBIT (assuming reversal of transfer)
                    // If it's reversal of withdrawal, it should credit source wallet and debit bank asset. 
                    // Let's assume the reversal credits the source wallet and debits the bank asset for withdrawal reversal.
                    // Wait, Reversal tx records sourceWalletId = wallet that is being refunded.
                    postings.add(new LedgerPosting(UUID.randomUUID().toString(), entryId, bankAssetAccount.getId(), EntryType.DEBIT, tx.getAmount().getAmount()));
                    postings.add(new LedgerPosting(UUID.randomUUID().toString(), entryId, sourceCustomerAccount.getId(), EntryType.CREDIT, tx.getAmount().getAmount()));
                    break;
                case BILL_PAYMENT:
                case TOPUP:
                    if (sourceCustomerAccount != null) {
                        postings.add(new LedgerPosting(UUID.randomUUID().toString(), entryId, sourceCustomerAccount.getId(), EntryType.DEBIT, tx.getAmount().getAmount()));
                        postings.add(new LedgerPosting(UUID.randomUUID().toString(), entryId, bankAssetAccount.getId(), EntryType.CREDIT, tx.getAmount().getAmount()));
                    }
                    break;
            }

            if (!postings.isEmpty()) {
                String description = tx.getNote() != null && !tx.getNote().isBlank() ? tx.getNote() : "Automatic ledger posting for " + tx.getType();
                try {
                    ledgerService.recordJournalEntry(tx.getId(), description, event.getEventId(), postings);
                } catch (org.springframework.dao.DataIntegrityViolationException dive) {
                    log.info("Duplicate event ignored at DB level in LedgerConsumer: {}", event.getEventId());
                }
            }

        } catch (Exception e) {
            log.error("Error processing ledger posting for transaction {}", event.getTransactionId(), e);
            redisTemplate.delete(idempotencyKey); // Allow retry
            if (e instanceof RuntimeException) {
                throw (RuntimeException) e;
            }
            throw new RuntimeException(e);
        }
    }
}
