package com.fintech.payment.scheduler;

import com.fintech.payment.domain.entity.AmlCase;
import com.fintech.payment.service.AmlCaseService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.List;

@Slf4j
@Component
@RequiredArgsConstructor
public class AmlOverdueScheduler {

    private final AmlCaseService caseService;

    @Scheduled(fixedRate = 3600000)
    public void checkOverdueCases() {
        try {
            List<AmlCase> overdueCases = caseService.findOverdueCases();
            for (AmlCase amlCase : overdueCases) {
                log.warn("AML case {} overdue: transactionId={}, customerId={}, status={}, slaDueAt={}",
                        amlCase.getId(), amlCase.getTransactionId(), amlCase.getCustomerId(),
                        amlCase.getStatus(), amlCase.getSlaDueAt());
            }
            log.info("Overdue AML check completed: {} overdue cases found", overdueCases.size());
        } catch (RuntimeException exception) {
            log.error("Error checking overdue AML cases", exception);
        }
    }
}
