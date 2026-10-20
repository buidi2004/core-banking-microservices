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

        String sourceUserId = (headerUserId != null && !headerUserId.isBlank())
                ? headerUserId
                : request.getSourceUserId();

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
                request.getTargetUserId(),
                request.getAmount(),
                request.getCurrency(),
                request.getNote(),
                request.getIdempotencyKey()
        );
        return ResponseEntity.ok(ApiResponse.success("P2P transfer processed", TransferResponse.from(ctx)));
    }

    @GetMapping("/{transactionId}")
    public ResponseEntity<ApiResponse<TransferResponse>> getTransaction(@PathVariable String transactionId) {
        return ResponseEntity.ok(ApiResponse.error("Transaction query not implemented"));
    }
}
