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
            @RequestParam(value = "type", required = false) String type,
            @RequestParam(value = "billType", required = false) String billType,
            @RequestParam(value = "customerCode", required = false) String customerCode,
            @RequestParam(value = "code", required = false) String code) {
        String effectiveType = type != null && !type.isBlank() ? type : billType;
        String effectiveCode = customerCode != null && !customerCode.isBlank() ? customerCode : code;
        if (effectiveType == null || effectiveCode == null) {
            return ResponseEntity.badRequest().body(ApiResponse.error("MISSING_PARAM", "Cần truyền type (hoặc billType) và customerCode (hoặc code)"));
        }
        BillLookupResponse res = billService.lookupBill(effectiveType, effectiveCode);
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

    /**
     * Quản lý ủy thác trích nợ tự động hóa đơn (Auto-Debit Bill Subscriptions)
     */
    @PostMapping("/subscriptions")
    public ResponseEntity<ApiResponse<BillSubscriptionResponse>> createSubscription(
            @RequestHeader(value = "X-User-Id", defaultValue = "user-me") String userId,
            @Valid @RequestBody CreateBillSubscriptionRequest request) {
        BillSubscriptionResponse res = billService.createSubscription(userId, request);
        return ResponseEntity.ok(ApiResponse.success("Đăng ký trích nợ tự động hóa đơn thành công", res));
    }

    @GetMapping("/subscriptions")
    public ResponseEntity<ApiResponse<java.util.List<BillSubscriptionResponse>>> getMySubscriptions(
            @RequestHeader(value = "X-User-Id", defaultValue = "user-me") String userId) {
        java.util.List<BillSubscriptionResponse> list = billService.getUserSubscriptions(userId);
        return ResponseEntity.ok(ApiResponse.success("Danh sách ủy thác trích nợ tự động", list));
    }

    @DeleteMapping("/subscriptions/{id}")
    public ResponseEntity<ApiResponse<BillSubscriptionResponse>> cancelSubscription(
            @RequestHeader(value = "X-User-Id", defaultValue = "user-me") String userId,
            @PathVariable("id") java.util.UUID id) {
        BillSubscriptionResponse res = billService.cancelSubscription(id, userId);
        return ResponseEntity.ok(ApiResponse.success("Hủy ủy thác trích nợ tự động thành công", res));
    }

    @PostMapping("/subscriptions/execute-due")
    public ResponseEntity<ApiResponse<java.util.Map<String, Object>>> executeDue() {
        java.util.Map<String, Object> summary = billService.executeDueSubscriptions();
        return ResponseEntity.ok(ApiResponse.success("Quét và trích nợ tự động hóa đơn đến hạn", summary));
    }
}

