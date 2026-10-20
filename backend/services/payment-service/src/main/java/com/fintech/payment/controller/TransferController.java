package com.fintech.payment.controller;

import com.fintech.payment.dto.ApiResponse;
import com.fintech.payment.dto.TransferRequest;
import com.fintech.payment.dto.TransferResponse;
import com.fintech.payment.saga.PaymentSagaOrchestrator;
import com.fintech.payment.saga.SagaContext;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/payments/transfer")
public class TransferController {

    private final PaymentSagaOrchestrator sagaOrchestrator;

    public TransferController(PaymentSagaOrchestrator sagaOrchestrator) {
        this.sagaOrchestrator = sagaOrchestrator;
    }

    @PostMapping
    public ResponseEntity<ApiResponse<TransferResponse>> p2pTransfer(@Valid @RequestBody TransferRequest request) {
        SagaContext ctx = sagaOrchestrator.transferP2p(
                request.getSourceUserId(),
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
