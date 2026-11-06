package com.fintech.payment.service;

import com.fintech.common.audit.AuditEvent;
import com.fintech.payment.audit.AuditEventPublisher;
import com.fintech.payment.domain.entity.AmlCase;
import com.fintech.payment.domain.entity.AmlCaseEvent;
import com.fintech.payment.grpc.WalletGrpcClient;
import com.fintech.payment.grpc.dto.WalletInfoResult;
import com.fintech.payment.repository.AmlCaseEventRepository;
import com.fintech.payment.repository.AmlCaseRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class AmlCaseService {
    private final AmlCaseRepository caseRepository;
    private final AmlCaseEventRepository eventRepository;
    private final WalletGrpcClient walletGrpcClient;
    private final AuditEventPublisher auditEventPublisher;

    @Transactional
    public AmlCase create(String transactionId, String customerId, String reason, int slaHours, String actorId) {
        transactionId = requireText(transactionId, "transactionId");
        reason = requireText(reason, "reason");
        actorId = requireText(actorId, "actorId");
        if (caseRepository.existsByTransactionIdAndStatusNot(transactionId, AmlCase.CLOSED)) {
            throw new IllegalStateException("An active AML case already exists for transaction " + transactionId);
        }
        Instant now = Instant.now();
        AmlCase item = AmlCase.builder()
                .id(UUID.randomUUID())
                .transactionId(transactionId)
                .customerId(customerId)
                .status(AmlCase.OPEN)
                .reason(reason)
                .createdBy(actorId)
                .slaDueAt(now.plus(Math.max(1, slaHours), ChronoUnit.HOURS))
                .createdAt(now)
                .updatedAt(now)
                .version(0L)
                .build();
        item = caseRepository.save(item);
        record(item, actorId, "OPENED", reason);
        return item;
    }

    @Transactional
    public AmlCase assign(UUID id, String assignee, String reason, String actorId) {
        AmlCase item = get(id);
        requireNotClosed(item);
        assignee = requireText(assignee, "assigneeId");
        reason = requireText(reason, "reason");
        actorId = requireText(actorId, "actorId");
        item.setAssignedTo(assignee);
        return transition(item, AmlCase.ASSIGNED, reason, actorId);
    }

    @Transactional
    public AmlCase transition(UUID id, String status, String reason, String actorId) {
        AmlCase item = get(id);
        requireNotClosed(item);
        status = requireText(status, "status").toUpperCase();
        reason = requireText(reason, "reason");
        actorId = requireText(actorId, "actorId");
        if (!List.of(AmlCase.INVESTIGATING, AmlCase.FROZEN, AmlCase.RELEASED, AmlCase.CLOSED)
                .contains(status)) {
            throw new IllegalArgumentException("Unsupported AML status: " + status);
        }
        if (!allowedTransitions().getOrDefault(item.getStatus(), List.of()).contains(status)) {
            throw new IllegalStateException("Invalid AML transition: " + item.getStatus() + " -> " + status);
        }
        return transition(item, status, reason, actorId);
    }

    @Transactional(readOnly = true)
    public List<AmlCase> list(String status) {
        return status == null || status.isBlank()
                ? caseRepository.findAllByOrderByUpdatedAtDesc()
                : caseRepository.findByStatusOrderByUpdatedAtDesc(status.trim().toUpperCase());
    }

    @Transactional(readOnly = true)
    public List<AmlCaseEvent> events(UUID id) {
        get(id);
        return eventRepository.findByCaseIdOrderByCreatedAtAsc(id);
    }

    private AmlCase transition(AmlCase item, String status, String reason, String actorId) {
        Instant now = Instant.now();
        item.setStatus(status);
        item.setUpdatedAt(now);
        if (AmlCase.CLOSED.equals(status)) {
            item.setClosedAt(now);
        }
        item = caseRepository.save(item);
        record(item, actorId, status, reason);
        return item;
    }

    private void record(AmlCase item, String actorId, String action, String reason) {
        eventRepository.save(AmlCaseEvent.builder()
                .id(UUID.randomUUID())
                .caseId(item.getId())
                .actorId(actorId)
                .action(action)
                .reason(reason)
                .createdAt(Instant.now())
                .build());
        
        // Publish audit event to Kafka for centralized audit log
        if (auditEventPublisher != null) {
            try {
                auditEventPublisher.publish(new AuditEvent(
                        UUID.randomUUID(), Instant.now(), "payment-service",
                        "AML_CASE_" + action, "AML_CASE", item.getId().toString(),
                        actorId, null, null, null,
                        item.getTransactionId(), null, null, null, reason));
                log.info("Published audit event for AML case {} action={}", item.getId(), action);
            } catch (Exception e) {
                log.warn("Failed to publish audit event for AML case {}: {}", item.getId(), e.getMessage());
            }
        }
    }

    /**
     * Chuyển trạng thái với side effects (freeze/release wallet)
     */
    @Transactional
    public AmlCase transitionWithSideEffects(UUID id, String status, String reason, String actorId) {
        AmlCase item = transition(id, status, reason, actorId);
        
        switch (status) {
            case AmlCase.FROZEN:
                freezeWallet(item);
                break;
            case AmlCase.RELEASED:
                releaseWallet(item);
                break;
            default:
                break;
        }
        
        return item;
    }

    private void freezeWallet(AmlCase amlCase) {
        try {
            WalletInfoResult walletInfo = walletGrpcClient.getWalletByUserId(amlCase.getCustomerId());
            if (walletInfo.isFound() && walletInfo.getWalletId() != null) {
                log.info("Wallet freeze requested for AML case {}: customerId={}, walletId={}",
                        amlCase.getId(), amlCase.getCustomerId(), walletInfo.getWalletId());
            } else {
                log.warn("Wallet not found for customerId={} in AML case {}", amlCase.getCustomerId(), amlCase.getId());
            }
        } catch (Exception e) {
            log.error("Error freezing wallet for AML case {}: {}", amlCase.getId(), e.getMessage(), e);
        }
    }

    private void releaseWallet(AmlCase amlCase) {
        try {
            WalletInfoResult walletInfo = walletGrpcClient.getWalletByUserId(amlCase.getCustomerId());
            if (walletInfo.isFound() && walletInfo.getWalletId() != null) {
                log.info("Wallet release requested for AML case {}: customerId={}, walletId={}",
                        amlCase.getId(), amlCase.getCustomerId(), walletInfo.getWalletId());
            } else {
                log.warn("Wallet not found for customerId={} in AML case {}", amlCase.getCustomerId(), amlCase.getId());
            }
        } catch (Exception e) {
            log.error("Error releasing wallet for AML case {}: {}", amlCase.getId(), e.getMessage(), e);
        }
    }

    /**
     * Tìm các case quá hạn SLA
     */
    @Transactional(readOnly = true)
    public List<AmlCase> findOverdueCases() {
        return caseRepository.findAllOverdueBefore(Instant.now(), AmlCase.CLOSED);
    }

    private AmlCase get(UUID id) {
        return caseRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("AML case not found: " + id));
    }

    private void requireNotClosed(AmlCase item) {
        if (AmlCase.CLOSED.equals(item.getStatus())) {
            throw new IllegalStateException("AML case is already closed");
        }
    }

    private String requireText(String value, String field) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(field + " is required");
        }
        return value.trim();
    }

    private Map<String, List<String>> allowedTransitions() {
        return Map.of(
                AmlCase.OPEN, List.of(AmlCase.ASSIGNED, AmlCase.INVESTIGATING, AmlCase.FROZEN),
                AmlCase.ASSIGNED, List.of(AmlCase.INVESTIGATING, AmlCase.FROZEN),
                AmlCase.INVESTIGATING, List.of(AmlCase.FROZEN, AmlCase.RELEASED, AmlCase.CLOSED),
                AmlCase.FROZEN, List.of(AmlCase.RELEASED, AmlCase.CLOSED),
                AmlCase.RELEASED, List.of(AmlCase.CLOSED),
                AmlCase.CLOSED, List.of()
        );
    }
}
