package com.fintech.payment.controller;

import com.fintech.payment.dto.*;
import com.fintech.payment.service.BillService;
import jakarta.validation.Valid;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@Slf4j
@RestController
@RequestMapping("/api/v1/bills")
public class BillController {

    private final BillService billService;

    public BillController(BillService billService) {
        this.billService = billService;
    }

    @GetMapping("/lookup")
    public ResponseEntity<ApiResponse<BillLookupResponse>> lookup(
            @RequestParam("type") String type,
            @RequestParam("customerCode") String customerCode) {
        BillLookupResponse res = billService.lookupBill(type, customerCode);
        return ResponseEntity.ok(ApiResponse.success("Thông tin hóa đơn cần thanh toán", res));
    }

    @PostMapping("/pay")
    public ResponseEntity<ApiResponse<BillPaymentResponse>> pay(
            @RequestHeader(value = "X-User-Id", defaultValue = "test-user") String userId,
            @Valid @RequestBody BillPaymentRequest request) {
        BillPaymentResponse res = billService.payBill(userId, request);
        return ResponseEntity.ok(ApiResponse.success("Thanh toán hóa đơn thành công", res));
    }

    @PostMapping("/topup")
    public ResponseEntity<ApiResponse<PhoneTopupResponse>> topup(
            @RequestHeader(value = "X-User-Id", defaultValue = "test-user") String userId,
            @Valid @RequestBody PhoneTopupRequest request) {
        PhoneTopupResponse res = billService.topupPhone(userId, request);
        return ResponseEntity.ok(ApiResponse.success("Nạp tiền điện thoại thành công", res));
    }
}

