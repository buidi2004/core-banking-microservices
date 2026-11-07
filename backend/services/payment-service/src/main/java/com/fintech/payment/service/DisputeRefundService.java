package com.fintech.payment.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fintech.common.audit.AuditEvent;
import com.fintech.payment.audit.AuditEventPublisher;
import com.fintech.payment.domain.entity.DisputeCase;
import com.fintech.payment.domain.entity.DisputeEvent;
import com.fintech.payment.domain.entity.OutboxEvent;
import com.fintech.payment.domain.entity.Transaction;
import com.fintech.payment.dto.dispute.CreateDisputeRequest;
import com.fintech.payment.dto.dispute.ResolveDisputeRequest;
import com.fintech.payment.grpc.WalletGrpcClient;
import com.fintech.payment.grpc.dto.WalletBalanceResult;
import com.fintech.payment.repository.DisputeCaseRepository;
import com.fintech.payment.repository.DisputeEventRepository;
import com.fintech.payment.repository.OutboxEventRepository;
import com.fintech.payment.repository.TransactionRepository;
import com.fintech.wallet.domain.event.TransactionEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class DisputeRefundService {

    private final DisputeCaseRepository disputeCaseRepository;
    private final DisputeEventRepository disputeEventRepository;
    private final TransactionRepository transactionRepository;
    private final OutboxEventRepository outboxEventRepository;
    private final WalletGrpcClient walletGrpcClient;
    private final AuditEventPublisher auditEventPublisher;
    private final ObjectMapper objectMapper;

    @Transactional
    public DisputeCase createDispute(CreateDisputeRequest request, String actorId, String customerId) {
        if (actorId == null || actorId.isBlank()) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Missing actor ID");
        }

        Transaction tx = transactionRepository.findById(request.transactionId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy giao dịch: " + request.transactionId()));

        if ("REVERSED".equalsIgnoreCase(tx.getStatus())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Giao dịch đã được hoàn tiền/đảo bút toán trước đó.");
        }

        boolean hasActiveDispute = disputeCaseRepository.existsByTransactionIdAndStatusNotIn(
                tx.getId(), List.of(DisputeCase.STATUS_REJECTED, DisputeCase.STATUS_REVERSED));
        if (hasActiveDispute) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Giao dịch này đang có một phiếu tra soát đang được xử lý.");
        }

        Long totalTxAmount = tx.getAmount() + (tx.getFee() != null ? tx.getFee() : 0L);
        Long refundAmount = (request.requestedAmount() != null && request.requestedAmount() > 0)
                ? Math.min(request.requestedAmount(), totalTxAmount)
                : totalTxAmount;

        String effectiveCustomerId = customerId != null && !customerId.isBlank()
                ? customerId
                : (tx.getSenderId() != null ? tx.getSenderId() : actorId);

        Instant now = Instant.now();
        DisputeCase disputeCase = DisputeCase.builder()
                .id(UUID.randomUUID())
                .transactionId(tx.getId())
                .customerId(effectiveCustomerId)
                .disputeType(request.disputeType() != null && !request.disputeType().isBlank() ? request.disputeType().trim().toUpperCase() : "GENERAL")
                .reason(request.reason().trim())
                .status(DisputeCase.STATUS_OPEN)
                .refundAmount(refundAmount)
                .createdBy(actorId)
                .createdAt(now)
                .updatedAt(now)
                .version(0L)
                .build();

        disputeCase = disputeCaseRepository.save(disputeCase);

        recordEvent(disputeCase.getId(), actorId, "OPENED", request.reason().trim());

        publishAudit("DISPUTE_CREATED", disputeCase.getId().toString(), tx.getId(), actorId,
                "Tạo phiếu tra soát cho GD #" + tx.getId() + ": " + request.reason());

        log.info("Dispute created: id={}, transactionId={}, refundAmount={}, actorId={}",
                disputeCase.getId(), tx.getId(), refundAmount, actorId);

        return disputeCase;
    }

    @Transactional
    public DisputeCase assignDispute(UUID disputeId, String assigneeId, String actorId, String note) {
        DisputeCase dispute = getDispute(disputeId);
        requireActive(dispute);

        dispute.setAssignedTo(assigneeId.trim());
        dispute.setStatus(DisputeCase.STATUS_UNDER_REVIEW);
        dispute.setUpdatedAt(Instant.now());
        DisputeCase saved = disputeCaseRepository.save(dispute);

        recordEvent(saved.getId(), actorId, "ASSIGNED",
                "Phân công cho " + assigneeId + (note != null && !note.isBlank() ? " | " + note.trim() : ""));

        publishAudit("DISPUTE_ASSIGNED", saved.getId().toString(), saved.getTransactionId(), actorId,
                "Phân công xử lý tra soát cho " + assigneeId);

        return saved;
    }

    @Transactional
    public DisputeCase resolveDispute(UUID disputeId, ResolveDisputeRequest request, String actorId) {
        DisputeCase dispute = getDispute(disputeId);
        requireActive(dispute);

        String action = request.action().trim().toUpperCase();
        if ("REFUND".equals(action) || "APPROVE".equals(action)) {
            return approveAndExecuteRefund(dispute, request.resolutionNote().trim(), actorId);
        } else if ("REJECT".equals(action)) {
            return rejectDispute(dispute, request.resolutionNote().trim(), actorId);
        } else {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Hành động không hợp lệ: " + request.action() + " (chỉ chấp nhận REFUND hoặc REJECT)");
        }
    }

    @Transactional
    public DisputeCase approveAndExecuteRefund(DisputeCase dispute, String resolutionNote, String actorId) {
        final String txId = dispute.getTransactionId();
        Transaction tx = transactionRepository.findById(txId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy giao dịch: " + txId));

        if ("REVERSED".equalsIgnoreCase(tx.getStatus())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Giao dịch đã được đảo bút toán / hoàn tiền.");
        }

        Long refundAmount = dispute.getRefundAmount() != null && dispute.getRefundAmount() > 0
                ? dispute.getRefundAmount()
                : (tx.getAmount() + (tx.getFee() != null ? tx.getFee() : 0L));

        executeWalletRefund(tx, refundAmount, "Dispute #" + dispute.getId() + ": " + resolutionNote);

        Instant now = Instant.now();
        dispute.setStatus(DisputeCase.STATUS_REVERSED);
        dispute.setResolutionNote(resolutionNote);
        dispute.setResolvedBy(actorId);
        dispute.setResolvedAt(now);
        dispute.setUpdatedAt(now);
        DisputeCase saved = disputeCaseRepository.save(dispute);

        recordEvent(saved.getId(), actorId, "REVERSED", "Duyệt hoàn tiền " + refundAmount + " VND: " + resolutionNote);

        publishAudit("DISPUTE_REFUND_APPROVED", saved.getId().toString(), tx.getId(), actorId,
                "Hoàn tiền thành công " + refundAmount + " VND: " + resolutionNote);

        log.info("Dispute refunded and reversed: id={}, transactionId={}, amount={}, actor={}",
                saved.getId(), tx.getId(), refundAmount, actorId);

        return saved;
    }

    @Transactional
    public DisputeCase rejectDispute(DisputeCase dispute, String resolutionNote, String actorId) {
        Instant now = Instant.now();
        dispute.setStatus(DisputeCase.STATUS_REJECTED);
        dispute.setResolutionNote(resolutionNote);
        dispute.setResolvedBy(actorId);
        dispute.setResolvedAt(now);
        dispute.setUpdatedAt(now);
        DisputeCase saved = disputeCaseRepository.save(dispute);

        recordEvent(saved.getId(), actorId, "REJECTED", "Từ chối tra soát: " + resolutionNote);

        publishAudit("DISPUTE_REJECTED", saved.getId().toString(), saved.getTransactionId(), actorId,
                "Từ chối tra soát: " + resolutionNote);

        log.info("Dispute rejected: id={}, transactionId={}, actor={}", saved.getId(), saved.getTransactionId(), actorId);

        return saved;
    }

    @Transactional
    public Transaction executeDirectReversal(String transactionId, String reason, String actorId) {
        if (actorId == null || actorId.isBlank()) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Missing actor ID");
        }

        Transaction tx = transactionRepository.findById(transactionId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy giao dịch: " + transactionId));

        if ("REVERSED".equalsIgnoreCase(tx.getStatus())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Giao dịch đã được đảo bút toán / hoàn tiền.");
        }

        Long refundAmount = tx.getAmount() + (tx.getFee() != null ? tx.getFee() : 0L);

        executeWalletRefund(tx, refundAmount, "Manual reversal by " + actorId + ": " + reason);

        // Đồng bộ các dispute đang mở cho transaction này nếu có
        disputeCaseRepository.findFirstByTransactionIdAndStatusNotIn(
                tx.getId(), List.of(DisputeCase.STATUS_REJECTED, DisputeCase.STATUS_REVERSED)
        ).ifPresent(dispute -> {
            Instant now = Instant.now();
            dispute.setStatus(DisputeCase.STATUS_REVERSED);
            dispute.setResolutionNote("Auto-resolved via Direct Reversal: " + reason);
            dispute.setResolvedBy(actorId);
            dispute.setResolvedAt(now);
            dispute.setUpdatedAt(now);
            disputeCaseRepository.save(dispute);
            recordEvent(dispute.getId(), actorId, "REVERSED", "Tự động đóng do Quản lý thực hiện Đảo bút toán trực tiếp");
        });

        publishAudit("TRANSACTION_MANUAL_REVERSAL", tx.getId(), tx.getId(), actorId,
                "Đảo bút toán thủ công thành công: " + reason);

        return tx;
    }

    private void executeWalletRefund(Transaction tx, Long refundAmount, String reason) {
        String refundWalletId = tx.getSourceWalletId();
        if (refundWalletId == null || refundWalletId.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Giao dịch không có ví nguồn hợp lệ để hoàn tiền.");
        }

        String reversalTxId = tx.getId() + ":manual-rev";
        String reversalIdempotencyKey = "REV-" + tx.getId() + "-" + UUID.randomUUID().toString().substring(0, 8);

        WalletBalanceResult creditResult = walletGrpcClient.credit(
                refundWalletId, refundAmount, reversalTxId, reversalIdempotencyKey);

        if (!creditResult.isSuccess()) {
            log.error("Failed to credit refund to source wallet {}: {}", refundWalletId, creditResult.getErrorMessage());
            throw new ResponseStatusException(HttpStatus.BAD_GATEWAY,
                    "Không thể hoàn tiền sang ví nguồn: " + (creditResult.getErrorMessage() != null ? creditResult.getErrorMessage() : creditResult.getErrorCode()));
        }

        // Cập nhật trạng thái transaction
        tx.setStatus("REVERSED");
        tx.setFailureReason(reason);
        if (creditResult.getBalanceAfter() != null) {
            tx.setSourceBalanceAfter(creditResult.getBalanceAfter());
        }
        transactionRepository.save(tx);

        // Tạo sự kiện Outbox để thông báo cho Ledger và Notification
        TransactionEvent event = new TransactionEvent();
        event.setEventId(UUID.randomUUID().toString());
        event.setTransactionId(tx.getId());
        event.setType(tx.getType() != null ? tx.getType() : "TRANSFER");
        event.setStatus("REVERSED");
        event.setSourceWalletId(tx.getSourceWalletId());
        event.setTargetWalletId(tx.getTargetWalletId());
        event.setSourceUserId(tx.getSenderId());
        event.setTargetUserId(tx.getReceiverId());
        event.setAmount(BigDecimal.valueOf(tx.getAmount()));
        event.setFeeAmount(tx.getFee() != null ? BigDecimal.valueOf(tx.getFee()) : BigDecimal.ZERO);
        event.setCurrency(tx.getCurrency() != null ? tx.getCurrency() : "VND");
        event.setSourceBalanceAfter(creditResult.getBalanceAfter() != null ? BigDecimal.valueOf(creditResult.getBalanceAfter()) : null);
        event.setNote(reason);
        event.setOccurredAt(Instant.now());

        try {
            outboxEventRepository.save(OutboxEvent.pending(
                    "Transaction",
                    tx.getId(),
                    "TransactionReversedEvent",
                    objectMapper.writeValueAsString(event)));
        } catch (Exception e) {
            log.error("Failed to serialize outbox event for reversed tx {}: {}", tx.getId(), e.getMessage());
            throw new IllegalStateException("Lỗi ghi nhận sự kiện Outbox hoàn tiền", e);
        }
    }

    @Transactional(readOnly = true)
    public Page<DisputeCase> listDisputes(String status, Pageable pageable) {
        if (status != null && !status.isBlank()) {
            return disputeCaseRepository.findByStatusOrderByCreatedAtDesc(status.trim().toUpperCase(), pageable);
        }
        return disputeCaseRepository.findAllByOrderByCreatedAtDesc(pageable);
    }

    @Transactional(readOnly = true)
    public Page<DisputeCase> listCustomerDisputes(String customerId, Pageable pageable) {
        return disputeCaseRepository.findByCustomerIdOrderByCreatedAtDesc(customerId, pageable);
    }

    @Transactional(readOnly = true)
    public DisputeCase getDispute(UUID id) {
        return disputeCaseRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy yêu cầu tra soát: " + id));
    }

    @Transactional(readOnly = true)
    public List<DisputeEvent> getDisputeEvents(UUID id) {
        getDispute(id);
        return disputeEventRepository.findByDisputeIdOrderByCreatedAtAsc(id);
    }

    private void requireActive(DisputeCase item) {
        if (DisputeCase.STATUS_REVERSED.equals(item.getStatus()) || DisputeCase.STATUS_REJECTED.equals(item.getStatus())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Yêu cầu tra soát này đã được kết luận đóng (" + item.getStatus() + ").");
        }
    }

    private void recordEvent(UUID disputeId, String actorId, String action, String note) {
        disputeEventRepository.save(DisputeEvent.builder()
                .id(UUID.randomUUID())
                .disputeId(disputeId)
                .actorId(actorId)
                .action(action)
                .note(note)
                .createdAt(Instant.now())
                .build());
    }

    private void publishAudit(String action, String resourceId, String transactionId, String actorId, String details) {
        if (auditEventPublisher != null) {
            try {
                auditEventPublisher.publish(new AuditEvent(
                        UUID.randomUUID(),
                        Instant.now(),
                        "payment-service",
                        action,
                        "DISPUTE",
                        resourceId,
                        actorId,
                        null,
                        null,
                        null,
                        transactionId,
                        null,
                        null,
                        null,
                        details
                ));
            } catch (Exception e) {
                log.warn("Failed to publish audit event {}: {}", action, e.getMessage());
            }
        }
    }
}
