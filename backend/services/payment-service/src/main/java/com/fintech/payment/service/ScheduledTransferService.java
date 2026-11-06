package com.fintech.payment.service;

import com.fintech.payment.domain.entity.ScheduledTransfer;
import com.fintech.payment.dto.CreateScheduledTransferRequest;
import com.fintech.payment.dto.ScheduledTransferResponse;
import com.fintech.payment.repository.ScheduledTransferRepository;
import com.fintech.payment.saga.PaymentSagaOrchestrator;
import com.fintech.payment.saga.SagaContext;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class ScheduledTransferService {

    private final ScheduledTransferRepository scheduledTransferRepository;
    private final PaymentSagaOrchestrator sagaOrchestrator;

    @Transactional
    public ScheduledTransferResponse createSchedule(String sourceUserId, CreateScheduledTransferRequest request) {
        if (request.getAmount() == null || request.getAmount() <= 0) {
            throw new IllegalArgumentException("Số tiền chuyển phải lớn hơn 0");
        }
        if (request.getTargetUserId() == null || request.getTargetUserId().isBlank()) {
            throw new IllegalArgumentException("Người nhận không được để trống");
        }

        Instant nextExec = request.getExecuteAt();
        if (nextExec == null || nextExec.isBefore(Instant.now())) {
            nextExec = Instant.now();
        }

        String freq = request.getFrequency() != null ? request.getFrequency().trim().toUpperCase() : "ONCE";

        ScheduledTransfer entity = ScheduledTransfer.builder()
                .id(UUID.randomUUID().toString())
                .sourceUserId(sourceUserId)
                .targetUserId(request.getTargetUserId())
                .targetPhoneNumber(request.getTargetPhoneNumber())
                .targetCustomerName(request.getTargetCustomerName())
                .amount(request.getAmount())
                .currency(request.getCurrency() != null ? request.getCurrency() : "VND")
                .note(request.getNote() != null ? request.getNote() : "Chuyển tiền theo lịch tự động")
                .frequency(freq)
                .dayOfMonth(request.getDayOfMonth())
                .nextExecutionAt(nextExec)
                .status("ACTIVE")
                .build();

        ScheduledTransfer saved = scheduledTransferRepository.save(entity);
        log.info("Created scheduled transfer {} for user {}, next run at {}", saved.getId(), sourceUserId, nextExec);
        return toResponse(saved);
    }

    public List<ScheduledTransferResponse> getUserSchedules(String sourceUserId) {
        return scheduledTransferRepository.findBySourceUserIdOrderByCreatedAtDesc(sourceUserId).stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    @Transactional
    public ScheduledTransferResponse cancelSchedule(String id, String sourceUserId) {
        ScheduledTransfer transfer = scheduledTransferRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy lệnh đặt lịch: " + id));

        if (!transfer.getSourceUserId().equals(sourceUserId)) {
            throw new IllegalArgumentException("Bạn không có quyền hủy lệnh đặt lịch này");
        }

        transfer.setStatus("CANCELLED");
        scheduledTransferRepository.save(transfer);
        log.info("Cancelled scheduled transfer {}", id);
        return toResponse(transfer);
    }

    /**
     * Quét và thực thi các lệnh chuyển tiền đã đến hạn (chạy tự động mỗi phút hoặc kích hoạt thủ công).
     */
    @Scheduled(fixedRate = 60000)
    public Map<String, Object> executeDueSchedules() {
        Instant now = Instant.now();
        List<ScheduledTransfer> dueTransfers = scheduledTransferRepository.findDueTransfers(now);
        int totalDue = dueTransfers.size();
        int successCount = 0;
        int failedCount = 0;

        for (ScheduledTransfer sched : dueTransfers) {
            String idemKey = "sched:" + sched.getId() + ":" + sched.getNextExecutionAt().toEpochMilli();
            try {
                SagaContext ctx = sagaOrchestrator.transferP2p(
                        sched.getSourceUserId(),
                        sched.getTargetUserId(),
                        sched.getAmount(),
                        sched.getCurrency(),
                        sched.getNote(),
                        idemKey
                );

                sched.setLastExecutedAt(Instant.now());
                if ("SUCCESS".equalsIgnoreCase(ctx.getStatus())) {
                    sched.setLastTransactionId(ctx.getTransactionId());
                    sched.setFailureReason(null);
                    successCount++;

                    // Tính chu kỳ tiếp theo
                    if ("ONCE".equalsIgnoreCase(sched.getFrequency())) {
                        sched.setStatus("COMPLETED");
                    } else if ("DAILY".equalsIgnoreCase(sched.getFrequency())) {
                        sched.setNextExecutionAt(sched.getNextExecutionAt().plus(1, ChronoUnit.DAYS));
                    } else if ("WEEKLY".equalsIgnoreCase(sched.getFrequency())) {
                        sched.setNextExecutionAt(sched.getNextExecutionAt().plus(7, ChronoUnit.DAYS));
                    } else if ("MONTHLY".equalsIgnoreCase(sched.getFrequency())) {
                        sched.setNextExecutionAt(sched.getNextExecutionAt().plus(30, ChronoUnit.DAYS));
                    }
                } else {
                    failedCount++;
                    sched.setFailureReason(ctx.getFailureReason() != null ? ctx.getFailureReason() : "Saga thất bại: " + ctx.getStatus());
                    if ("ONCE".equalsIgnoreCase(sched.getFrequency())) {
                        sched.setStatus("FAILED");
                    }
                }
            } catch (Exception e) {
                log.error("Execution failed for scheduled transfer {}", sched.getId(), e);
                failedCount++;
                sched.setFailureReason("Lỗi hệ thống: " + e.getMessage());
                sched.setLastExecutedAt(Instant.now());
                if ("ONCE".equalsIgnoreCase(sched.getFrequency())) {
                    sched.setStatus("FAILED");
                }
            }
            scheduledTransferRepository.save(sched);
        }

        Map<String, Object> summary = new LinkedHashMap<>();
        summary.put("executedAt", now.toString());
        summary.put("totalDue", totalDue);
        summary.put("successCount", successCount);
        summary.put("failedCount", failedCount);
        return summary;
    }

    private ScheduledTransferResponse toResponse(ScheduledTransfer s) {
        return ScheduledTransferResponse.builder()
                .id(s.getId())
                .sourceUserId(s.getSourceUserId())
                .targetUserId(s.getTargetUserId())
                .targetPhoneNumber(s.getTargetPhoneNumber())
                .targetCustomerName(s.getTargetCustomerName())
                .amount(s.getAmount())
                .currency(s.getCurrency())
                .note(s.getNote())
                .frequency(s.getFrequency())
                .dayOfMonth(s.getDayOfMonth())
                .nextExecutionAt(s.getNextExecutionAt())
                .status(s.getStatus())
                .lastExecutedAt(s.getLastExecutedAt())
                .lastTransactionId(s.getLastTransactionId())
                .failureReason(s.getFailureReason())
                .createdAt(s.getCreatedAt())
                .build();
    }
}

