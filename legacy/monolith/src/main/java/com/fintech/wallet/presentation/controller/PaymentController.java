package com.fintech.wallet.presentation.controller;

import com.fintech.wallet.domain.model.Bill;
import com.fintech.wallet.domain.model.BillType;
import com.fintech.wallet.domain.model.Money;
import com.fintech.wallet.domain.model.Transaction;
import com.fintech.wallet.domain.model.VietQrPayload;
import com.fintech.wallet.domain.port.in.BillPaymentUseCase;
import com.fintech.wallet.domain.port.in.VietQrUseCase;
import com.fintech.wallet.presentation.request.GenerateQrRequest;
import com.fintech.wallet.presentation.request.PayBillRequest;
import com.fintech.wallet.presentation.request.TopupRequest;
import com.fintech.wallet.presentation.response.ApiResponse;
import com.fintech.wallet.presentation.response.TransferResponse;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/payments")
public class PaymentController {

    private final VietQrUseCase vietQrUseCase;
    private final BillPaymentUseCase billPaymentUseCase;

    public PaymentController(VietQrUseCase vietQrUseCase, BillPaymentUseCase billPaymentUseCase) {
        this.vietQrUseCase = vietQrUseCase;
        this.billPaymentUseCase = billPaymentUseCase;
    }

    @PostMapping("/vietqr/generate")
    public ResponseEntity<ApiResponse<VietQrPayload>> generateQr(@Valid @RequestBody GenerateQrRequest request) {
        VietQrPayload payload = vietQrUseCase.generateQr(
                request.getBankBin(),
                request.getAccountNumber(),
                request.getAmount(),
                request.getPurpose()
        );
        return ResponseEntity.ok(ApiResponse.success("VietQR generated successfully", payload));
    }

    @PostMapping("/vietqr/decode")
    public ResponseEntity<ApiResponse<VietQrPayload>> decodeQr(@RequestParam String qrString) {
        VietQrPayload payload = vietQrUseCase.decodeQr(qrString);
        return ResponseEntity.ok(ApiResponse.success("VietQR decoded successfully", payload));
    }

    @GetMapping("/bills/query")
    public ResponseEntity<ApiResponse<Bill>> queryBill(@RequestParam BillType billType, @RequestParam String customerCode) {
        Bill bill = billPaymentUseCase.queryBill(billType, customerCode);
        return ResponseEntity.ok(ApiResponse.success("Bill retrieved successfully", bill));
    }

    @PostMapping("/bills/pay")
    public ResponseEntity<ApiResponse<TransferResponse>> payBill(Authentication auth, @Valid @RequestBody PayBillRequest request) {
        String userId = auth.getName();
        Money money = Money.of(request.getAmount(), request.getCurrency());
        Transaction transaction = billPaymentUseCase.payBill(
                request.getRequestId(),
                userId,
                request.getWalletId(),
                request.getBillId(),
                money
        );
        TransferResponse response = TransferResponse.fromDomain(transaction);
        return ResponseEntity.ok(ApiResponse.success("Bill payment successful", response));
    }

    @PostMapping("/topup")
    public ResponseEntity<ApiResponse<TransferResponse>> topupPhone(Authentication auth, @Valid @RequestBody TopupRequest request) {
        String userId = auth.getName();
        Money money = Money.of(request.getAmount(), request.getCurrency());
        Transaction transaction = billPaymentUseCase.topupPhone(
                request.getRequestId(),
                userId,
                request.getWalletId(),
                request.getPhoneNumber(),
                money
        );
        TransferResponse response = TransferResponse.fromDomain(transaction);
        return ResponseEntity.ok(ApiResponse.success("Phone topup successful", response));
    }
}
