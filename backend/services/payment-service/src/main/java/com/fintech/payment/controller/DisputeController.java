package com.fintech.payment.controller;

import com.fintech.payment.domain.entity.DisputeCase;
import com.fintech.payment.domain.entity.DisputeEvent;
import com.fintech.payment.domain.entity.Transaction;
import com.fintech.payment.dto.ApiResponse;
import com.fintech.payment.dto.dispute.AssignDisputeRequest;
import com.fintech.payment.dto.dispute.CreateDisputeRequest;
import com.fintech.payment.dto.dispute.ManualReversalRequest;
import com.fintech.payment.dto.dispute.ResolveDisputeRequest;
import com.fintech.payment.service.DisputeRefundService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/payments")
@RequiredArgsConstructor
public class DisputeController {

    private final DisputeRefundService disputeRefundService;

    @PostMapping("/disputes")
    public ResponseEntity<ApiResponse<DisputeCase>> createDispute(
            @RequestHeader(value = "X-User-Id", required = false) String actorId,
            @RequestHeader(value = "X-User-Role", required = false) String role,
            @Valid @RequestBody CreateDisputeRequest request) {
        requireUser(actorId);
        DisputeCase dispute = disputeRefundService.createDispute(request, actorId, actorId);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Yêu cầu tra soát đã được tiếp nhận thành công", dispute));
    }

    @GetMapping("/disputes")
    public ResponseEntity<ApiResponse<Page<DisputeCase>>> listDisputes(
            @RequestHeader(value = "X-User-Id", required = false) String actorId,
            @RequestHeader(value = "X-User-Role", required = false) String role,
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        requireUser(actorId);

        PageRequest pageRequest = PageRequest.of(Math.max(0, page), Math.min(Math.max(1, size), 100), Sort.by(Sort.Direction.DESC, "createdAt"));

        Page<DisputeCase> result;
        if (isStaffOrManager(role)) {
            result = disputeRefundService.listDisputes(status, pageRequest);
        } else {
            result = disputeRefundService.listCustomerDisputes(actorId, pageRequest);
        }

        return ResponseEntity.ok(ApiResponse.success("Danh sách yêu cầu tra soát", result));
    }

    @GetMapping("/disputes/{id}")
    public ResponseEntity<ApiResponse<DisputeCase>> getDispute(
            @PathVariable UUID id,
            @RequestHeader(value = "X-User-Id", required = false) String actorId,
            @RequestHeader(value = "X-User-Role", required = false) String role) {
        requireUser(actorId);
        DisputeCase dispute = disputeRefundService.getDispute(id);

        if (!isStaffOrManager(role) && !actorId.equals(dispute.getCustomerId()) && !actorId.equals(dispute.getCreatedBy())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Bạn không có quyền truy cập yêu cầu tra soát này");
        }

        return ResponseEntity.ok(ApiResponse.success("Chi tiết yêu cầu tra soát", dispute));
    }

    @GetMapping("/disputes/{id}/events")
    public ResponseEntity<ApiResponse<List<DisputeEvent>>> getDisputeEvents(
            @PathVariable UUID id,
            @RequestHeader(value = "X-User-Id", required = false) String actorId,
            @RequestHeader(value = "X-User-Role", required = false) String role) {
        requireUser(actorId);
        DisputeCase dispute = disputeRefundService.getDispute(id);

        if (!isStaffOrManager(role) && !actorId.equals(dispute.getCustomerId()) && !actorId.equals(dispute.getCreatedBy())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Bạn không có quyền truy cập lịch sử tra soát này");
        }

        return ResponseEntity.ok(ApiResponse.success("Lịch sử xử lý tra soát", disputeRefundService.getDisputeEvents(id)));
    }

    @PostMapping("/disputes/{id}/assign")
    public ResponseEntity<ApiResponse<DisputeCase>> assignDispute(
            @PathVariable UUID id,
            @RequestHeader(value = "X-User-Id", required = false) String actorId,
            @RequestHeader(value = "X-User-Role", required = false) String role,
            @Valid @RequestBody AssignDisputeRequest request) {
        requireStaffOrManager(role);
        requireUser(actorId);
        DisputeCase dispute = disputeRefundService.assignDispute(id, request.assigneeId(), actorId, request.note());
        return ResponseEntity.ok(ApiResponse.success("Phân công tra soát thành công", dispute));
    }

    @PostMapping("/disputes/{id}/resolve")
    public ResponseEntity<ApiResponse<DisputeCase>> resolveDispute(
            @PathVariable UUID id,
            @RequestHeader(value = "X-User-Id", required = false) String actorId,
            @RequestHeader(value = "X-User-Role", required = false) String role,
            @Valid @RequestBody ResolveDisputeRequest request) {
        requireManager(role);
        requireUser(actorId);
        DisputeCase dispute = disputeRefundService.resolveDispute(id, request, actorId);
        return ResponseEntity.ok(ApiResponse.success("Kết luận xử lý tra soát thành công", dispute));
    }

    @PostMapping("/transactions/{transactionId}/reversal")
    public ResponseEntity<ApiResponse<Transaction>> manualReversal(
            @PathVariable String transactionId,
            @RequestHeader(value = "X-User-Id", required = false) String actorId,
            @RequestHeader(value = "X-User-Role", required = false) String role,
            @Valid @RequestBody ManualReversalRequest request) {
        requireManager(role);
        requireUser(actorId);
        Transaction tx = disputeRefundService.executeDirectReversal(transactionId, request.reason(), actorId);
        return ResponseEntity.ok(ApiResponse.success("Đảo bút toán giao dịch thành công", tx));
    }

    private void requireUser(String id) {
        if (id == null || id.isBlank()) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Missing trusted user");
        }
    }

    private void requireManager(String role) {
        if (role == null || (!"ROLE_MANAGER".equalsIgnoreCase(role.trim())
                && !"MANAGER".equalsIgnoreCase(role.trim())
                && !"ROLE_ADMIN".equalsIgnoreCase(role.trim())
                && !"ADMIN".equalsIgnoreCase(role.trim()))) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Chỉ Quản lý (ROLE_MANAGER/ADMIN) mới có quyền phê duyệt hoàn tiền / đảo bút toán.");
        }
    }

    private void requireStaffOrManager(String role) {
        if (!isStaffOrManager(role)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Chỉ Cán bộ nghiệp vụ (TELLER/MANAGER) mới có quyền thực hiện thao tác này.");
        }
    }

    private boolean isStaffOrManager(String role) {
        if (role == null) return false;
        String r = role.trim().toUpperCase();
        return r.contains("MANAGER") || r.contains("TELLER") || r.contains("ADMIN") || r.contains("STAFF");
    }
}

