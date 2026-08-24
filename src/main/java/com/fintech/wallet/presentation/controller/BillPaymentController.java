package com.fintech.wallet.presentation.controller;

import com.fintech.wallet.domain.model.Bill;
import com.fintech.wallet.domain.model.BillType;
import com.fintech.wallet.domain.model.Money;
import com.fintech.wallet.domain.model.Transaction;
import com.fintech.wallet.domain.port.in.BillPaymentUseCase;
import com.fintech.wallet.presentation.request.PayBillRequest;
import com.fintech.wallet.presentation.request.TopupRequest;
import com.fintech.wallet.presentation.response.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
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
@RequestMapping("/api/v1/bills")
@Tag(name = "Bill Payment", description = "Endpoints for paying bills and top-up")
public class BillPaymentController {

    private final BillPaymentUseCase billPaymentUseCase;

    public BillPaymentController(BillPaymentUseCase billPaymentUseCase) {
        this.billPaymentUseCase = billPaymentUseCase;
    }

    @Operation(summary = "Lookup a bill", description = "Fetch bill information from provider using customer code")
    @GetMapping("/lookup")
    public ResponseEntity<ApiResponse<Bill>> lookupBill(
            @RequestParam("type") BillType type,
            @RequestParam("customerCode") String customerCode) {
        
        Bill bill = billPaymentUseCase.queryBill(type, customerCode);
        return ResponseEntity.ok(ApiResponse.success("Truy vấn hóa đơn thành công", bill));
    }

    @Operation(summary = "Pay a bill", description = "Pay a queried bill from user's wallet")
    @PostMapping("/pay")
    public ResponseEntity<ApiResponse<Transaction>> payBill(
            Authentication auth,
            @Valid @RequestBody PayBillRequest request) {
        
        String userId = auth.getName();
        Money amount = new Money(request.getAmount(), request.getCurrency());
        
        Transaction tx = billPaymentUseCase.payBill(
                request.getRequestId(),
                userId,
                request.getWalletId(),
                request.getBillId(),
                amount
        );
        return ResponseEntity.ok(ApiResponse.success("Thanh toán hóa đơn thành công", tx));
    }

    @Operation(summary = "Topup phone", description = "Topup mobile phone balance")
    @PostMapping("/topup")
    public ResponseEntity<ApiResponse<Transaction>> topupPhone(
            Authentication auth,
            @Valid @RequestBody TopupRequest request) {
        
        String userId = auth.getName();
        Money amount = new Money(request.getAmount(), request.getCurrency());
        
        Transaction tx = billPaymentUseCase.topupPhone(
                request.getRequestId(),
                userId,
                request.getWalletId(),
                request.getPhoneNumber(),
                amount
        );
        return ResponseEntity.ok(ApiResponse.success("Nạp tiền điện thoại thành công", tx));
    }
}
