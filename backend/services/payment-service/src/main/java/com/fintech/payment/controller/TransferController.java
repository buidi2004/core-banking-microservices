package com.fintech.payment.controller;

import com.fintech.payment.dto.*;
import com.fintech.payment.saga.PaymentSagaOrchestrator;
import com.fintech.payment.saga.SagaContext;
import com.fintech.payment.security.PinTokenValidator;
import com.fintech.payment.repository.TransactionRepository;
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
    private final TransactionRepository transactionRepository;
    private final com.fintech.payment.service.BatchTransferService batchTransferService;

    public TransferController(PaymentSagaOrchestrator sagaOrchestrator,
                              PinTokenValidator pinTokenValidator,
                              TransactionRepository transactionRepository,
                              com.fintech.payment.service.BatchTransferService batchTransferService) {
        this.sagaOrchestrator = sagaOrchestrator;
        this.pinTokenValidator = pinTokenValidator;
        this.transactionRepository = transactionRepository;
        this.batchTransferService = batchTransferService;
    }

    @PostMapping
    public ResponseEntity<ApiResponse<TransferResponse>> p2pTransfer(
            @RequestHeader(value = "X-User-Id", required = false) String headerUserId,
            @RequestHeader(value = "X-User-Role", required = false) String headerRole,
            @RequestHeader(value = "X-User-Roles", required = false) String headerRoles,
            @RequestHeader(value = "X-Pin-Token", required = false) String headerPinToken,
            @RequestHeader(value = "X-Biometric-Token", required = false) String headerBiometricToken,
            @Valid @RequestBody TransferRequest request) {

        if (headerUserId == null || headerUserId.isBlank()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        boolean isStaff = (headerRole != null && (headerRole.contains("TELLER") || headerRole.contains("MANAGER") || headerRole.contains("ADMIN")))
                || (headerRoles != null && (headerRoles.contains("TELLER") || headerRoles.contains("MANAGER") || headerRoles.contains("ADMIN")));

        String sourceUserId;
        if (isStaff && request.getSourceUserId() != null && !request.getSourceUserId().isBlank()) {
            sourceUserId = request.getSourceUserId().trim();
        } else if (headerUserId != null && !headerUserId.isBlank() && !isStaff) {
            sourceUserId = headerUserId.trim();
        } else if (request.getSourceUserId() != null && !request.getSourceUserId().isBlank()) {
            sourceUserId = request.getSourceUserId().trim();
        } else if (request.getSourceWalletId() != null && !request.getSourceWalletId().isBlank()) {
            sourceUserId = request.getSourceWalletId().trim();
        } else {
            sourceUserId = headerUserId.trim();
        }

        if (sourceUserId == null || sourceUserId.isBlank()) {
            return ResponseEntity.badRequest().body(ApiResponse.error("MISSING_SOURCE_USER", "sourceUserId hoặc header X-User-Id là bắt buộc"));
        }

        String targetUserId = (request.getTargetUserId() != null && !request.getTargetUserId().isBlank())
                ? request.getTargetUserId().trim()
                : (request.getTargetWalletId() != null && !request.getTargetWalletId().isBlank() ? request.getTargetWalletId().trim() : null);

        if (targetUserId == null || targetUserId.isBlank()) {
            return ResponseEntity.badRequest().body(ApiResponse.error("MISSING_TARGET_USER", "targetUserId là bắt buộc. Hãy tra cứu qua GET /api/v1/wallets/recipient-info?phoneNumber={sdt}"));
        }

        if (sourceUserId.equalsIgnoreCase(targetUserId)) {
            return ResponseEntity.badRequest().body(ApiResponse.error("SELF_TRANSFER_NOT_ALLOWED", "Không thể tự chuyển tiền cho chính mình"));
        }

        String idempotencyKey = (request.getIdempotencyKey() != null && !request.getIdempotencyKey().isBlank())
                ? request.getIdempotencyKey().trim()
                : java.util.UUID.randomUUID().toString();

        String pinToken = (request.getPinToken() != null && !request.getPinToken().isBlank())
                ? request.getPinToken()
                : headerPinToken;

        // Quyết định 2345/QĐ-NHNN: Giao dịch chuyển tiền cá nhân từ 10.000.000 VND trở lên
        // bắt buộc phải có xác thực sinh trắc học khuôn mặt
        if (!isStaff && request.getAmount() != null && request.getAmount() >= 10_000_000L) {
            String bioToken = (request.getBiometricToken() != null && !request.getBiometricToken().isBlank())
                    ? request.getBiometricToken()
                    : headerBiometricToken;
            boolean hasBiometric = (bioToken != null && !bioToken.isBlank() && pinTokenValidator.validatePinToken(bioToken, sourceUserId))
                    || (pinToken != null && pinTokenValidator.validatePinToken(pinToken, sourceUserId) && pinTokenValidator.isBiometricToken(pinToken));

            if (!hasBiometric) {
                log.warn("QĐ 2345/QĐ-NHNN: Chuyển tiền {} VND vượt ngưỡng 10.000.000 VND chưa có sinh trắc học cho sourceUserId={}",
                        request.getAmount(), sourceUserId);
                ApiResponse<TransferResponse> err = ApiResponse.error(
                        "BIOMETRIC_AUTH_REQUIRED",
                        "Giao dịch từ 10.000.000 VND trở lên bắt buộc phải xác thực sinh trắc học khuôn mặt theo Quyết định 2345/QĐ-NHNN của Ngân hàng Nhà nước"
                );
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(err);
            }
        }

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
    public ResponseEntity<ApiResponse<TransferResponse>> getTransaction(
            @PathVariable String transactionId,
            @RequestHeader(value = "X-User-Id", required = false) String userId) {
        if (userId == null || userId.isBlank()) {
            throw new org.springframework.web.server.ResponseStatusException(
                    HttpStatus.UNAUTHORIZED, "Missing trusted header X-User-Id");
        }
        return transactionRepository.findById(transactionId)
                .or(() -> transactionRepository.findByTransactionCode(transactionId))
                .filter(tx -> userId.equals(tx.getSenderId()) || userId.equals(tx.getReceiverId()))
                .map(tx -> ResponseEntity.ok(ApiResponse.success("Transaction retrieved", TransferResponse.builder()
                        .transactionId(tx.getId())
                        .transactionCode(tx.getTransactionCode())
                        .sourceWalletId(tx.getSourceWalletId())
                        .targetWalletId(tx.getTargetWalletId())
                        .status(tx.getStatus())
                        .amount(tx.getAmount())
                        .currency(tx.getCurrency())
                        .build())))
                .orElseGet(() -> ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(ApiResponse.error("TRANSACTION_NOT_FOUND", "Không tìm thấy giao dịch: " + transactionId)));
    }

    /**
     * Chuyển tiền theo lô / Chi hộ lương cán bộ nhân viên chi nhánh & doanh nghiệp (Batch Payroll Transfer)
     */
    @PostMapping({"/batch", "/batch-transfer"})
    public ResponseEntity<ApiResponse<BatchTransferResponse>> batchTransfer(
            @RequestHeader(value = "X-User-Id", required = false) String headerUserId,
            @Valid @RequestBody BatchTransferRequest request) {
        if (headerUserId == null || headerUserId.isBlank()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        BatchTransferResponse response = batchTransferService.executeBatchTransfer(headerUserId, request);
        return ResponseEntity.ok(ApiResponse.success("Thực thi lệnh chi theo lô thành công", response));
    }
}
