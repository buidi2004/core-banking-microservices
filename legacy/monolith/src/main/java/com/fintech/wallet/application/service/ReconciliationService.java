package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.model.LedgerAccount;
import com.fintech.wallet.domain.port.in.ReconciliationUseCase;
import com.fintech.wallet.domain.port.out.LedgerPersistencePort;
import com.fintech.wallet.domain.port.out.WalletPersistencePort;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class ReconciliationService implements ReconciliationUseCase {

    private static final Logger log = LoggerFactory.getLogger(ReconciliationService.class);

    private final WalletPersistencePort walletPersistencePort;
    private final LedgerPersistencePort ledgerPersistencePort;

    public ReconciliationService(WalletPersistencePort walletPersistencePort, LedgerPersistencePort ledgerPersistencePort) {
        this.walletPersistencePort = walletPersistencePort;
        this.ledgerPersistencePort = ledgerPersistencePort;
    }

    @Override
    @Scheduled(cron = "0 0 0 * * ?") // 00:00 AM daily
    public Map<String, Object> runDailyReconciliation() {
        log.info("Starting daily reconciliation job at {}", Instant.now());

        BigDecimal totalWalletBalance = walletPersistencePort.sumAllBalances();
        if (totalWalletBalance == null) {
            totalWalletBalance = BigDecimal.ZERO;
        }

        List<LedgerAccount> accounts = ledgerPersistencePort.findAllAccounts();
        BigDecimal totalLedgerLiability = accounts.stream()
                .filter(a -> a.getAccountName().startsWith("CUSTOMER_DEPOSITS_"))
                .map(LedgerAccount::getBalance)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        Map<String, Object> report = new HashMap<>();
        report.put("timestamp", Instant.now().toString());

        if (totalLedgerLiability.compareTo(BigDecimal.ZERO) == 0 && totalWalletBalance.compareTo(BigDecimal.ZERO) == 0) {
            log.info("Reconciliation SUCCESS. Both ledger and wallet balances are ZERO.");
            report.put("status", "MATCHED");
            report.put("totalLedgerLiability", totalLedgerLiability);
            report.put("totalWalletBalance", totalWalletBalance);
            return report;
        }

        report.put("totalLedgerLiability", totalLedgerLiability);
        report.put("totalWalletBalance", totalWalletBalance);

        if (totalWalletBalance.compareTo(totalLedgerLiability) == 0) {
            log.info("Reconciliation SUCCESS. Ledger balance ({}) perfectly matches total wallet balance ({}).", totalLedgerLiability, totalWalletBalance);
            report.put("status", "MATCHED");
        } else {
            BigDecimal diff = totalLedgerLiability.subtract(totalWalletBalance);
            log.error("Reconciliation FAILED! Ledger balance ({}) != Total wallet balance ({}). Diff: {}",
                    totalLedgerLiability, totalWalletBalance, diff);
            report.put("status", "MISMATCH");
            report.put("diff", diff);
            // In a real system, trigger PagerDuty/Slack alert here
        }

        log.info("Daily reconciliation completed: {}", report);
        return report;
    }
}
