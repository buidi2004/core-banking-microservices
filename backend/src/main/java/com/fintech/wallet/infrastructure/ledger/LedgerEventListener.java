package com.fintech.wallet.infrastructure.ledger;

import com.fintech.wallet.application.service.LedgerService;
import com.fintech.wallet.domain.event.TransactionCompletedEvent;
import com.fintech.wallet.domain.model.AccountType;
import com.fintech.wallet.domain.model.EntryType;
import com.fintech.wallet.domain.model.LedgerAccount;
import com.fintech.wallet.domain.model.LedgerPosting;
import com.fintech.wallet.domain.model.Transaction;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Component
public class LedgerEventListener {

    private static final Logger log = LoggerFactory.getLogger(LedgerEventListener.class);

    private final LedgerService ledgerService;

    public LedgerEventListener(LedgerService ledgerService) {
        this.ledgerService = ledgerService;
    }

    @Async("notificationExecutor")
    @EventListener
    public void handleTransactionCompleted(TransactionCompletedEvent event) {
        Transaction tx = event.getTransaction();
        log.info("LedgerEventListener: Processing double-entry ledger posting for transaction txId={} type={}", tx.getId(), tx.getType());

        try {
            // Get or create system cash/liability accounts
            List<LedgerAccount> accounts = ledgerService.getAllAccounts();
            LedgerAccount bankAssetAccount = accounts.stream()
                    .filter(a -> "BANK_SETTLEMENT".equals(a.getAccountName()))
                    .findFirst()
                    .orElseGet(() -> ledgerService.createAccount("BANK_SETTLEMENT", AccountType.ASSET, "VND"));

            LedgerAccount customerLiabilityAccount = accounts.stream()
                    .filter(a -> "CUSTOMER_DEPOSITS".equals(a.getAccountName()))
                    .findFirst()
                    .orElseGet(() -> ledgerService.createAccount("CUSTOMER_DEPOSITS", AccountType.LIABILITY, "VND"));

            List<LedgerPosting> postings = new ArrayList<>();
            String entryId = UUID.randomUUID().toString();

            switch (tx.getType()) {
                case DEPOSIT:
                    // Nạp tiền: Bank Asset (+) DEBIT, Customer Deposit Liability (+) CREDIT
                    postings.add(new LedgerPosting(UUID.randomUUID().toString(), entryId, bankAssetAccount.getId(), EntryType.DEBIT, tx.getAmount().getAmount()));
                    postings.add(new LedgerPosting(UUID.randomUUID().toString(), entryId, customerLiabilityAccount.getId(), EntryType.CREDIT, tx.getAmount().getAmount()));
                    break;
                case WITHDRAWAL:
                    // Rút tiền: Customer Deposit Liability (-) DEBIT, Bank Asset (-) CREDIT
                    postings.add(new LedgerPosting(UUID.randomUUID().toString(), entryId, customerLiabilityAccount.getId(), EntryType.DEBIT, tx.getAmount().getAmount()));
                    postings.add(new LedgerPosting(UUID.randomUUID().toString(), entryId, bankAssetAccount.getId(), EntryType.CREDIT, tx.getAmount().getAmount()));
                    break;
                case TRANSFER:
                    // Chuyển tiền nội bộ: Customer Liability DEBIT, Customer Liability CREDIT
                    postings.add(new LedgerPosting(UUID.randomUUID().toString(), entryId, customerLiabilityAccount.getId(), EntryType.DEBIT, tx.getAmount().getAmount()));
                    postings.add(new LedgerPosting(UUID.randomUUID().toString(), entryId, customerLiabilityAccount.getId(), EntryType.CREDIT, tx.getAmount().getAmount()));
                    break;
            }

            if (!postings.isEmpty()) {
                ledgerService.recordJournalEntry(tx.getId(), "Automatic ledger posting for " + tx.getType(), postings);
            }
        } catch (Exception e) {
            log.error("Failed to post double-entry ledger entry for txId={}", tx.getId(), e);
        }
    }
}
