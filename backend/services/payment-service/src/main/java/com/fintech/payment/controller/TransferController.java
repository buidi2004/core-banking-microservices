package com.fintech.payment.controller;

import com.fintech.payment.dto.ApiResponse;
import com.fintech.payment.dto.TransferRequest;
import com.fintech.payment.dto.TransferResponse;
import com.fintech.payment.saga.PaymentSagaOrchestrator;
import com.fintech.payment.saga.SagaContext;
import com.fintech.payment.security.PinTokenValidator;
import jakarta.validation.Valid;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@Slf4j
@RestController
@RequestMapping("/api/v1/payments/transfer")
public class TransferController {

    private final PaymentSagaOrchestrator sagaOrchestrator;
    private final PinTokenValidator pinTokenValidator;

    public TransferController(PaymentSagaOrchestrator sagaOrchestrator, PinTokenValidator pinTokenValidator) {
        this.sagaOrchestrator = sagaOrchestrator;
        this.pinTokenValidator = pinTokenValidator;
    }

    @PostMapping
    public ResponseEntity<ApiResponse<TransferResponse>> p2pTransfer(
            @RequestHeader(value = "X-User-Id", required = false) String headerUserId,
            @RequestHeader(value = "X-Pin-Token", required = false) String headerPinToken,
            @Valid @RequestBody TransferRequest request) {

        String sourceUserId = (request.getSourceUserId() != null && !request.getSourceUserId().isBlank())
                ? request.getSourceUserId().trim()
                : (headerUserId != null && !headerUserId.isBlank() ? headerUserId.trim() : null);

        if (sourceUserId == null || sourceUserId.isBlank()) {
            return ResponseEntity.badRequest().body(ApiResponse.error("MISSING_SOURCE_USER", "sourceUserId hoặc header X-User-Id là bắt buộc"));
        }

        String targetUserId = (request.getTargetUserId() != null && !request.getTargetUserId().isBlank())
                ? request.getTargetUserId().trim()
                : null;

        if (targetUserId == null || targetUserId.isBlank()) {
            return ResponseEntity.badRequest().body(ApiResponse.error("MISSING_TARGET_USER", "targetUserId là bắt buộc. Hãy tra cứu qua GET /api/v1/wallets/recipient-info?phoneNumber={sdt}"));
        }

        String idempotencyKey = (request.getIdempotencyKey() != null && !request.getIdempotencyKey().isBlank())
                ? request.getIdempotencyKey().trim()
                : java.util.UUID.randomUUID().toString();

        String pinToken = (request.getPinToken() != null && !request.getPinToken().isBlank())
                ? request.getPinToken()
                : headerPinToken;

        // Xác thực pinToken nếu được cung cấp
        if (pinToken != null && !pinToken.isBlank()) {
            if (!pinTokenValidator.validatePinToken(pinToken, sourceUserId)) {
                log.warn("Chuyển tiền P2P bị từ chối: pinToken không hợp lệ cho sourceUserId={}", sourceUserId);
                ApiResponse<TransferResponse> err = ApiResponse.error("INVALID_PIN_TOKEN", "Mã xác thực giao dịch (PIN) không hợp lệ hoặc đã hết hạn");
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(err);
            }
        }

        SagaContext ctx = sagaOrchestrator.transferP2p(
                sourceUserId,
                targetUserId,
                request.getAmount(),
                request.getCurrency() != null ? request.getCurrency() : "VND",
                request.getNote(),
                idempotencyKey
        );
        if (!"SUCCESS".equals(ctx.getStatus())) {
            String failureReason = ctx.getFailureReason() != null ? ctx.getFailureReason() : "Giao dịch chuyển tiền không thành công";
            log.warn("Chuyển tiền P2P thất bại cho sourceUserId={}, reason={}", sourceUserId, failureReason);
            String lower = failureReason.toLowerCase();
            boolean isInsufficient = lower.contains("insufficient") || failureReason.contains("<") || lower.contains("không đủ") || lower.contains("số dư");
            String errorCode = isInsufficient ? "INSUFFICIENT_BALANCE" : "TRANSFER_FAILED";
            String errorMessage = isInsufficient 
                    ? "Số dư khả dụng trong ví không đủ để thực hiện giao dịch này" 
                    : failureReason;
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.error(errorCode, errorMessage));
        }
        return ResponseEntity.ok(ApiResponse.success("P2P transfer processed", TransferResponse.from(ctx)));
    }

    @GetMapping("/{transactionId}")
    public ResponseEntity<ApiResponse<TransferResponse>> getTransaction(@PathVariable String transactionId) {
        return ResponseEntity.ok(ApiResponse.error("Transaction query not implemented"));
    }
}
