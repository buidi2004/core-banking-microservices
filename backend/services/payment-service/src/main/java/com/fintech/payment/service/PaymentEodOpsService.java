package com.fintech.payment.service;

import com.fintech.payment.domain.entity.CashDeposit;
import com.fintech.payment.dto.eod.PaymentEodGateResponse;
import com.fintech.payment.outbox.OutboxRelay;
import com.fintech.payment.repository.AmlCaseRepository;
import com.fintech.payment.repository.CashDepositRepository;
import com.fintech.payment.repository.CashInTransitRepository;
import com.fintech.payment.repository.DisputeCaseRepository;
import com.fintech.payment.repository.OutboxEventRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class PaymentEodOpsService {

    private final CashDepositRepository cashDepositRepository;
    private final CashInTransitRepository cashInTransitRepository;
    private final DisputeCaseRepository disputeCaseRepository;
    private final AmlCaseRepository amlCaseRepository;
    private final OutboxEventRepository outboxEventRepository;
    private final OutboxRelay outboxRelay;

    @Transactional(readOnly = true)
    public PaymentEodGateResponse checkEodGate() {
        long pendingDeposits = cashDepositRepository.countByStatus(CashDeposit.STATUS_PENDING_APPROVAL);
        long pendingCit = cashInTransitRepository.countByStatusIn(List.of("PENDING", "PENDING_APPROVAL"));
        long pendingDisputes = disputeCaseRepository.countByStatusIn(List.of("OPEN", "UNDER_REVIEW"));
        long pendingAml = amlCaseRepository.countByStatusIn(List.of("OPEN", "ASSIGNED", "INVESTIGATING"));
        long pendingMakerCheckerTotal = pendingDeposits + pendingCit + pendingDisputes + pendingAml;

        long pendingOutbox = outboxEventRepository.countByStatus("PENDING");
        long failedOutbox = outboxEventRepository.countByStatus("FAILED");

        List<String> reasons = new ArrayList<>();
        if (pendingDeposits > 0) {
            reasons.add(pendingDeposits + " giao dịch nạp tiền tại quầy chờ Kiểm soát viên phê duyệt");
        }
        if (pendingCit > 0) {
            reasons.add(pendingCit + " lệnh điều chuyển két quỹ CIT chờ duyệt");
        }
        if (pendingDisputes > 0) {
            reasons.add(pendingDisputes + " yêu cầu tra soát & hoàn tiền đang mở/đang xem xét");
        }
        if (pendingAml > 0) {
            reasons.add(pendingAml + " hồ sơ AML đang điều tra chưa có kết luận");
        }
        if (pendingOutbox > 0) {
            reasons.add(pendingOutbox + " sự kiện outbox chưa được chuyển sang Kafka/RabbitMQ");
        }
        if (failedOutbox > 0) {
            reasons.add(failedOutbox + " sự kiện outbox bị lỗi (FAILED)");
        }

        boolean canCloseEod = reasons.isEmpty();
        String gateStatus = canCloseEod ? "CLEARED" : "BLOCKED";

        log.info("Payment EOD gate check: status={}, canClose={}, mcTotal={}, outboxPending={}",
                gateStatus, canCloseEod, pendingMakerCheckerTotal, pendingOutbox);

        return PaymentEodGateResponse.builder()
                .canCloseEod(canCloseEod)
                .gateStatus(gateStatus)
                .pendingCashDeposits(pendingDeposits)
                .pendingCitTransfers(pendingCit)
                .pendingDisputes(pendingDisputes)
                .pendingAmlCases(pendingAml)
                .pendingMakerCheckerTotal(pendingMakerCheckerTotal)
                .pendingOutboxCount(pendingOutbox)
                .failedOutboxCount(failedOutbox)
                .blockingReasons(reasons)
                .build();
    }

    public long drainOutbox() {
        log.info("Manually triggering Outbox Relay drain for EOD gate...");
        for (int i = 0; i < 5; i++) {
            outboxRelay.relayPendingEvents();
            long remaining = outboxEventRepository.countByStatus("PENDING");
            if (remaining == 0) {
                break;
            }
        }
        return outboxEventRepository.countByStatus("PENDING");
    }
}
