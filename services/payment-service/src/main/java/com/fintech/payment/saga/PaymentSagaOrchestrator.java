package com.fintech.payment.saga;

import com.fintech.payment.domain.entity.OutboxEvent;
import com.fintech.payment.domain.entity.Transaction;
import com.fintech.payment.grpc.WalletGrpcClient;
import com.fintech.payment.grpc.dto.WalletBalanceResult;
import com.fintech.payment.repository.OutboxEventRepository;
import com.fintech.payment.repository.TransactionRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.UUID;

/**
 * Saga Orchestrator điều phối giao dịch P2P Transfer giữa Payment Service và Wallet Service.
 *
 * Luồng (theo docs/architecture/5.md Giai đoạn 4):
 *   1. Resolve ví nguồn/đích qua gRPC GetWalletByUserId
 *   2. Tạo Transaction INITIATED + Outbox PENDING (TransactionInitiatedEvent) - cùng 1 DB TX
 *   3. gRPC Debit ví người gửi -> thành công: DEBITED
 *   4. gRPC Credit ví người nhận ->
 *        - thành công: SUCCESS + Outbox TransactionCompletedEvent (publish TRANSACTION_COMPLETED)
 *        - thất bại/timeout: kích hoạt Auto-Reversal -> gRPC Credit hoàn tiền ví gửi
 *          + REVERSED + Outbox TransactionReversedEvent
 *
 * Auto-Reversal đảm bảo tiền không bị mất khi bước Credit thất bại sau khi Debit đã thành công.
 */
@Service
public class PaymentSagaOrchestrator {

    private static final String IDEMPOTENCY_PREFIX = "saga:p2p:idempotency:";
    private static final long IDEMPOTENCY_TTL_SECONDS = 3600;

    private final WalletGrpcClient walletGrpcClient;
    private final TransactionRepository transactionRepository;
    private final OutboxEventRepository outboxEventRepository;
    private final ObjectMapper objectMapper;
    private final StringRedisTemplate redisTemplate;

    public PaymentSagaOrchestrator(WalletGrpcClient walletGrpcClient,
                                   TransactionRepository transactionRepository,
                                   OutboxEventRepository outboxEventRepository,
                                   ObjectMapper objectMapper,
                                   StringRedisTemplate redisTemplate) {
        this.walletGrpcClient = walletGrpcClient;
        this.transactionRepository = transactionRepository;
        this.outboxEventRepository = outboxEventRepository;
        this.objectMapper = objectMapper;
        this.redisTemplate = redisTemplate;
    }

    /**
     * Entry point chuyển tiền P2P với Saga + Auto-Reversal.
     */
    @Transactional
    public SagaContext transferP2p(String sourceUserId, String targetUserId,
                                   Long amount, String currency, String note, String idempotencyKey) {
        if (sourceUserId == null || targetUserId == null) {
            throw new IllegalArgumentException("sourceUserId và targetUserId là bắt buộc");
        }
        if (amount == null || amount <= 0) {
            throw new IllegalArgumentException("Số tiền phải lớn hơn 0");
        }

        // Guard idempotency bằng Redis (chống xử lý trùng request)
        String lockKey = IDEMPOTENCY_PREFIX + idempotencyKey;
        Boolean acquired = redisTemplate.opsForValue()
                .setIfAbsent(lockKey, "1", java.time.Duration.ofSeconds(IDEMPOTENCY_TTL_SECONDS));
        if (Boolean.FALSE.equals(acquired)) {
            // Đã có saga đang xử lý / đã xử lý với idempotency key này
            return transactionRepository.findByIdempotencyKey(idempotencyKey)
                    .map(this::toContext)
                    .orElseThrow(() -> new IllegalStateException("Yêu cầu đang được xử lý, vui lòng thử lại sau"));
        }

        SagaContext ctx = new SagaContext();
        ctx.setIdempotencyKey(idempotencyKey);
        ctx.setSourceUserId(sourceUserId);
        ctx.setTargetUserId(targetUserId);
        ctx.setAmount(amount);
        ctx.setCurrency(currency != null ? currency : "VND");
        ctx.setNote(note);
        ctx.setStatus("INITIATED");
        ctx.setCurrentStep("RESOLVE_WALLET");

        // Bước 0: Tra cứu ví nguồn & đích từ Wallet Service
        resolveWallets(ctx);

        // Bước 1: Tạo transaction + outbox Initiated (cùng 1 DB transaction)
        Transaction transaction = createTransactionAndOutbox(ctx, "INITIATED", "TransactionInitiatedEvent");
        ctx.setTransactionId(transaction.getId());
        ctx.setTransactionCode(transaction.getTransactionCode());
        ctx.setStatus("INITIATED");

        try {
            // Bước 2: Debit ví người gửi
            ctx.setCurrentStep("PENDING_DEBIT");
            WalletBalanceResult debit = walletGrpcClient.debit(
                    ctx.getSourceWalletId(), amount, ctx.getTransactionId(), idempotencyKey);
            if (!debit.isSuccess()) {
                return handleDebitFailure(ctx, debit.getErrorCode(), debit.getErrorMessage());
            }
            ctx.sourceDebited(String.valueOf(debit.getBalanceAfter()));
            updateTransactionStatus(ctx.getTransactionId(), "DEBITED");

            // Bước 3: Credit ví người nhận
            ctx.setCurrentStep("PENDING_CREDIT");
            WalletBalanceResult credit = walletGrpcClient.credit(
                    ctx.getTargetWalletId(), amount, ctx.getTransactionId(), idempotencyKey + ":credit");
            if (!credit.isSuccess()) {
                // Auto-Reversal: hoàn tiền lại ví người gửi
                return autoReverse(ctx, "Credit thất bại: " + (credit.getErrorMessage() != null ? credit.getErrorMessage() : credit.getErrorCode()));
            }
            ctx.targetCredited(String.valueOf(credit.getBalanceAfter()));

            // Bước 4: Hoàn thành giao dịch
            ctx.succeeded();
            completeTransaction(ctx, credit.getBalanceAfter());
            return ctx;

        } catch (Exception e) {
            // Ngoại lệ (timeout, connection) khi Credit -> Auto-Reversal
            if (!ctx.isReversed() && ("DEBITED".equals(ctx.getStatus()) || "CREDITED".equals(ctx.getStatus()))) {
                return autoReverse(ctx, "Saga ngoại lệ: " + e.getMessage());
            }
            ctx.failed(e.getMessage());
            markTransactionFailed(ctx.getTransactionId(), e.getMessage());
            throw new IllegalStateException("Saga P2P thất bại: " + e.getMessage(), e);
        }
    }

    /* ---------- Private steps ---------- */

    private void resolveWallets(SagaContext ctx) {
        var source = walletGrpcClient.getWalletByUserId(ctx.getSourceUserId());
        if (!source.isFound()) {
            throw new IllegalArgumentException("Không tìm thấy ví của người gửi: " + ctx.getSourceUserId());
        }
        ctx.setSourceWalletId(source.getWalletId());

        var target = walletGrpcClient.getWalletByUserId(ctx.getTargetUserId());
        if (!target.isFound()) {
            throw new IllegalArgumentException("Không tìm thấy ví của người nhận: " + ctx.getTargetUserId());
        }
        ctx.setTargetWalletId(target.getWalletId());
    }

    private Transaction createTransactionAndOutbox(SagaContext ctx, String status, String eventType) {
        String transactionCode = "TXN_" + UUID.randomUUID().toString().substring(0, 12).toUpperCase();
        Transaction tx = Transaction.builder()
                .transactionCode(transactionCode)
                .sourceWalletId(ctx.getSourceWalletId())
                .targetWalletId(ctx.getTargetWalletId())
                .senderId(ctx.getSourceUserId())
                .receiverId(ctx.getTargetUserId())
                .amount(ctx.getAmount())
                .fee(ctx.getFee() != null ? ctx.getFee() : 0L)
                .currency(ctx.getCurrency())
                .type("TRANSFER")
                .status(status)
                .idempotencyKey(ctx.getIdempotencyKey())
                .note(ctx.getNote())
                .build();
        tx = transactionRepository.save(tx);

        OutboxEvent outbox = OutboxEvent.pending(
                "Transaction", tx.getId(), eventType,
                serialize(new com.fintech.wallet.domain.event.TransactionEvent()));
        outboxEventRepository.save(outbox);
        return tx;
    }

    private void updateTransactionStatus(String transactionId, String status) {
        transactionRepository.findById(transactionId).ifPresent(tx -> {
            tx.setStatus(status);
            transactionRepository.save(tx);
        });
    }

    private void completeTransaction(SagaContext ctx, Long targetBalanceAfter) {
        transactionRepository.findById(ctx.getTransactionId()).ifPresent(tx -> {
            tx.setStatus("SUCCESS");
            transactionRepository.save(tx);
        });
        outboxEventRepository.save(OutboxEvent.pending(
                "Transaction", ctx.getTransactionId(), "TransactionCompletedEvent",
                serialize(event(ctx, "SUCCESS", targetBalanceAfter))));
    }

    private SagaContext handleDebitFailure(SagaContext ctx, String errorCode, String errorMessage) {
        ctx.failed(errorMessage != null ? errorMessage : errorCode);
        markTransactionFailed(ctx.getTransactionId(), errorMessage != null ? errorMessage : errorCode);
        outboxEventRepository.save(OutboxEvent.pending(
                "Transaction", ctx.getTransactionId(), "TransactionFailedEvent",
                serialize(event(ctx, "FAILED", null))));
        return ctx;
    }

    /**
     * Auto-Reversal: hoàn tiền số dư đã bị trừ về ví người gửi khi Credit thất bại.
     */
    private SagaContext autoReverse(SagaContext ctx, String reason) {
        if (ctx.isReversed()) {
            return ctx;
        }
        // Gọi gRPC Credit hoàn tiền vào ví người gửi (dùng amount + fee)
        Long refundAmount = ctx.getAmount() + (ctx.getFee() != null ? ctx.getFee() : 0L);
        WalletBalanceResult refund = walletGrpcClient.credit(
                ctx.getSourceWalletId(), refundAmount, ctx.getTransactionId() + ":reversal", ctx.getIdempotencyKey() + ":reversal");

        transactionRepository.findById(ctx.getTransactionId()).ifPresent(tx -> {
            tx.setStatus("REVERSED");
            tx.setFailureReason(reason);
            transactionRepository.save(tx);
        });
        ctx.reversed();

        outboxEventRepository.save(OutboxEvent.pending(
                "Transaction", ctx.getTransactionId(), "TransactionReversedEvent",
                serialize(event(ctx, "REVERSED", null))));

        if (!refund.isSuccess()) {
            ctx.setFailureReason(reason + " | Hoàn tiền thất bại: " + (refund.getErrorMessage() != null ? refund.getErrorMessage() : refund.getErrorCode()));
        }
        return ctx;
    }

    private void markTransactionFailed(String transactionId, String reason) {
        transactionRepository.findById(transactionId).ifPresent(tx -> {
            tx.setStatus("FAILED");
            tx.setFailureReason(reason);
            transactionRepository.save(tx);
        });
    }

    /* ---------- Helpers ---------- */

    private com.fintech.wallet.domain.event.TransactionEvent event(SagaContext ctx, String status, Long balanceAfter) {
        com.fintech.wallet.domain.event.TransactionEvent evt = new com.fintech.wallet.domain.event.TransactionEvent();
        evt.setEventId(UUID.randomUUID().toString());
        evt.setTransactionId(ctx.getTransactionId());
        evt.setType("TRANSFER");
        evt.setStatus(status);
        evt.setSourceWalletId(ctx.getSourceWalletId());
        evt.setTargetWalletId(ctx.getTargetWalletId());
        evt.setSourceUserId(ctx.getSourceUserId());
        evt.setTargetUserId(ctx.getTargetUserId());
        evt.setAmount(java.math.BigDecimal.valueOf(ctx.getAmount()));
        evt.setCurrency(ctx.getCurrency());
        evt.setNote(ctx.getNote());
        evt.setSourceBalanceAfter(balanceAfter != null ? java.math.BigDecimal.valueOf(balanceAfter) : null);
        evt.setOccurredAt(Instant.now());
        return evt;
    }

    private String serialize(Object obj) {
        try {
            return objectMapper.writeValueAsString(obj);
        } catch (Exception e) {
            throw new IllegalStateException("Không thể serialize sự kiện outbox", e);
        }
    }

    private SagaContext toContext(Transaction tx) {
        SagaContext ctx = new SagaContext();
        ctx.setTransactionId(tx.getId());
        ctx.setTransactionCode(tx.getTransactionCode());
        ctx.setSourceWalletId(tx.getSourceWalletId());
        ctx.setTargetWalletId(tx.getTargetWalletId());
        ctx.setSourceUserId(tx.getSenderId());
        ctx.setTargetUserId(tx.getReceiverId());
        ctx.setAmount(tx.getAmount());
        ctx.setCurrency(tx.getCurrency());
        ctx.setStatus(tx.getStatus());
        ctx.setIdempotencyKey(tx.getIdempotencyKey());
        return ctx;
    }
}
