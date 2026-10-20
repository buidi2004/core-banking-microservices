package com.fintech.payment.controller;

import com.fintech.payment.domain.entity.MoneyRequest;
import com.fintech.payment.dto.ApiResponse;
import com.fintech.payment.dto.MoneyRequestRequest;
import com.fintech.payment.dto.MoneyRequestResponse;
import com.fintech.payment.repository.MoneyRequestRepository;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/v1/payments/money-requests")
public class MoneyRequestController {

    private final MoneyRequestRepository moneyRequestRepository;

    public MoneyRequestController(MoneyRequestRepository moneyRequestRepository) {
        this.moneyRequestRepository = moneyRequestRepository;
    }

    @PostMapping
    @Transactional
    public ResponseEntity<ApiResponse<MoneyRequestResponse>> create(@Valid @RequestBody MoneyRequestRequest request) {
        if (request.getRequesterId().equals(request.getTargetUserId())) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Không thể tự gửi yêu cầu tiền cho chính mình"));
        }

        Instant expiresAt = Instant.now();
        if (request.getExpiresInHours() != null && request.getExpiresInHours() > 0) {
            expiresAt = expiresAt.plusSeconds(request.getExpiresInHours() * 3600L);
        } else {
            expiresAt = expiresAt.plusSeconds(24 * 3600L); // mặc định hết hạn sau 24h
        }

        MoneyRequest mr = MoneyRequest.builder()
                .requesterId(request.getRequesterId())
                .targetUserId(request.getTargetUserId())
                .amount(request.getAmount())
                .status("PENDING")
                .note(request.getNote())
                .expiresAt(expiresAt)
                .build();
        mr = moneyRequestRepository.save(mr);

        return ResponseEntity.ok(ApiResponse.success("Yêu cầu tiền đã tạo", toResponse(mr)));
    }

    @PostMapping("/{id}/accept")
    @Transactional
    public ResponseEntity<ApiResponse<MoneyRequestResponse>> accept(@PathVariable String id,
                                                                    @RequestParam String payerUserId) {
        MoneyRequest mr = moneyRequestRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Yêu cầu tiền không tìm thấy: " + id));
        if (!mr.getTargetUserId().equals(payerUserId)) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Chỉ người nhận mới có thể chấp nhận"));
        }
        mr.accept();
        mr = moneyRequestRepository.save(mr);
        return ResponseEntity.ok(ApiResponse.success("Đã chấp nhận yêu cầu tiền", toResponse(mr)));
    }

    @PostMapping("/{id}/reject")
    @Transactional
    public ResponseEntity<ApiResponse<MoneyRequestResponse>> reject(@PathVariable String id,
                                                                    @RequestParam String payerUserId) {
        MoneyRequest mr = moneyRequestRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Yêu cầu tiền không tìm thấy: " + id));
        if (!mr.getTargetUserId().equals(payerUserId)) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Chỉ người nhận mới có thể từ chối"));
        }
        mr.reject();
        mr = moneyRequestRepository.save(mr);
        return ResponseEntity.ok(ApiResponse.success("Đã từ chối yêu cầu tiền", toResponse(mr)));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<MoneyRequestResponse>> getDetail(@PathVariable String id) {
        MoneyRequest mr = moneyRequestRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Yêu cầu tiền không tìm thấy: " + id));
        return ResponseEntity.ok(ApiResponse.success("Chi tiết yêu cầu tiền", toResponse(mr)));
    }

    @PostMapping("/{id}/cancel")
    @Transactional
    public ResponseEntity<ApiResponse<MoneyRequestResponse>> cancel(
            @PathVariable String id,
            @RequestHeader(value = "X-User-Id", defaultValue = "test-user") String userId) {
        MoneyRequest mr = moneyRequestRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Yêu cầu tiền không tìm thấy: " + id));
        if (!mr.getRequesterId().equals(userId)) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Chỉ người tạo mới có thể hủy yêu cầu tiền"));
        }
        if (!"PENDING".equalsIgnoreCase(mr.getStatus())) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Chỉ có thể hủy yêu cầu đang ở trạng thái PENDING"));
        }
        mr.setStatus("CANCELLED");
        mr = moneyRequestRepository.save(mr);
        return ResponseEntity.ok(ApiResponse.success("Đã hủy yêu cầu tiền", toResponse(mr)));
    }

    @GetMapping("/received")
    public ResponseEntity<ApiResponse<List<MoneyRequestResponse>>> getReceived(
            @RequestHeader(value = "X-User-Id", defaultValue = "test-user") String userId) {
        List<MoneyRequestResponse> list = moneyRequestRepository.findByTargetUserId(userId).stream()
                .map(this::toResponse).collect(Collectors.toList());
        return ResponseEntity.ok(ApiResponse.success("Danh sách yêu cầu tiền nhận được", list));
    }

    @GetMapping("/sent")
    public ResponseEntity<ApiResponse<List<MoneyRequestResponse>>> getSent(
            @RequestHeader(value = "X-User-Id", defaultValue = "test-user") String userId) {
        List<MoneyRequestResponse> list = moneyRequestRepository.findByRequesterId(userId).stream()
                .map(this::toResponse).collect(Collectors.toList());
        return ResponseEntity.ok(ApiResponse.success("Danh sách yêu cầu tiền đã gửi đi", list));
    }

    @GetMapping("/user/{userId}")
    public ResponseEntity<ApiResponse<List<MoneyRequestResponse>>> list(@PathVariable String userId) {
        List<MoneyRequestResponse> list = moneyRequestRepository.findByTargetUserId(userId).stream()
                .map(this::toResponse).collect(Collectors.toList());
        return ResponseEntity.ok(ApiResponse.success("Danh sách yêu cầu tiền", list));
    }

    private MoneyRequestResponse toResponse(MoneyRequest mr) {
        return MoneyRequestResponse.builder()
                .id(mr.getId())
                .requesterId(mr.getRequesterId())
                .targetUserId(mr.getTargetUserId())
                .amount(mr.getAmount())
                .status(mr.getStatus())
                .note(mr.getNote())
                .build();
    }
}
