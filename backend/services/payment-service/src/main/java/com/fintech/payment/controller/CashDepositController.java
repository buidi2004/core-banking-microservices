package com.fintech.payment.controller;

import com.fintech.payment.domain.entity.CashDeposit;
import com.fintech.payment.dto.*;
import com.fintech.payment.exception.MakerCheckerViolationException;
import com.fintech.payment.kafka.PaymentKafkaProducer;
import com.fintech.payment.repository.CashDepositRepository;
import com.fintech.payment.rule.MakerCheckerRule;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Controller quản lý quy trình nạp tiền mặt tại quầy (Cash Deposit)
 * Tuân thủ quy chuẩn Maker-Checker (Four-Eyes Principle / Nguyên tắc 4 mắt)
 * và phân quyền Core Banking (ROLE_TELLER lập lệnh, ROLE_MANAGER phê duyệt).
 */
@RestController
@RequestMapping("/api/v1/cash")
@RequiredArgsConstructor
@Slf4j
public class CashDepositController {

    public static final String ROLE_MANAGER = "ROLE_MANAGER";
    public static final String DEFAULT_TELLER_ID = "t0000001-0000-0000-0000-000000000001";
    public static final long DEFAULT_OPENING_VAULT_BALANCE = 50_000_000L;
    public static final long DEFAULT_MAX_VAULT_LIMIT = 500_000_000L;

    private final CashDepositRepository cashDepositRepository;
    private final MakerCheckerRule makerCheckerRule;
    private final PaymentKafkaProducer paymentKafkaProducer;

    /**
     * POST /api/v1/cash/deposits
     * Lập lệnh nạp tiền mặt tại quầy bởi Giao dịch viên (Maker).
     * - Hạn mức <= 50,000,000 VND: Tự động phê duyệt (COMPLETED).
     * - Hạn mức > 50,000,000 VND: Chờ Kiểm soát viên phê duyệt (PENDING_APPROVAL).
     * - Bảo vệ Idempotency chống nạp đúp giao dịch.
     */
    @PostMapping("/deposits")
    @Transactional
    public ResponseEntity<ApiResponse<CashDepositResponse>> createDeposit(
            @Valid @RequestBody CashDepositRequest request,
            @RequestHeader(value = "X-User-Id", required = false) String headerMakerId,
            @RequestHeader(value = "Idempotency-Key", required = false) String headerIdemKey) {

        // 1. Kiểm tra khóa Idempotency chống trùng lặp giao dịch
        String idemKey = request.getIdempotencyKey();
        if (idemKey == null || idemKey.isBlank()) {
            idemKey = headerIdemKey;
        }
        if (idemKey == null || idemKey.isBlank()) {
            idemKey = "idem_dep_" + UUID.randomUUID();
        }

        Optional<CashDeposit> existing = cashDepositRepository.findByIdempotencyKey(idemKey);
        if (existing.isPresent()) {
            log.info("Idempotent deposit request detected: key={}", idemKey);
            return ResponseEntity.ok(ApiResponse.success(
                    "Giao dịch đã được xử lý trước đó (Idempotent)",
                    CashDepositResponse.from(existing.get())
            ));
        }

        // 2. Xác định Maker ID (ưu tiên request body -> header -> teller mặc định)
        String makerId = request.getMakerId();
        if (makerId == null || makerId.isBlank()) {
            makerId = headerMakerId;
        }
        if (makerId == null || makerId.isBlank()) {
            makerId = DEFAULT_TELLER_ID;
        }

        // 3. Sinh mã giao dịch nạp tiền tại quầy duy nhất
        String depositCode = "DEP-" + System.currentTimeMillis() + "-" + (int)(Math.random() * 900 + 100);

        // 4. Kiểm tra hạn mức tự duyệt (Four-Eyes Principle / Maker-Checker Rule)
        boolean requiresApproval = makerCheckerRule.requiresCheckerApproval(request.getAmount());

        CashDeposit.CashDepositBuilder depositBuilder = CashDeposit.builder()
                .id(UUID.randomUUID().toString())
                .depositCode(depositCode)
                .accountNumber(request.getAccountNumber().trim())
                .customerName(request.getCustomerName().trim())
                .amount(request.getAmount())
                .currency(request.getCurrency() != null ? request.getCurrency() : "VND")
                .branchId(request.getBranchId() != null ? request.getBranchId() : "BR_Q1")
                .makerId(makerId.trim())
                .idempotencyKey(idemKey);

        if (requiresApproval) {
            // Vượt hạn mức 50M -> Chuyển sang trạng thái PENDING_APPROVAL
            depositBuilder.status(CashDeposit.STATUS_PENDING_APPROVAL);
        } else {
            // Trong hạn mức <= 50M -> Tự động duyệt hoàn tất (COMPLETED)
            depositBuilder.status(CashDeposit.STATUS_COMPLETED)
                    .checkerId("AUTO_RULE")
                    .approvedAt(Instant.now())
                    .completedAt(Instant.now());
        }

        CashDeposit deposit = cashDepositRepository.save(depositBuilder.build());

        // Nếu hoàn tất, bắn sự kiện Kafka để Ledger Service và Notification Service cập nhật
        if (CashDeposit.STATUS_COMPLETED.equals(deposit.getStatus())) {
            paymentKafkaProducer.sendCashDepositCompleted(
                    deposit.getDepositCode(),
                    deposit.getAccountNumber(),
                    deposit.getCustomerName(),
                    deposit.getAmount(),
                    deposit.getBranchId()
            );
        }

        String message = requiresApproval
                ? "Lệnh nạp tiền đã tạo, chờ Kiểm soát viên phê duyệt"
                : "Nạp tiền thành công (Tự động duyệt do số tiền <= 50,000,000 VND)";

        return ResponseEntity.ok(ApiResponse.success(message, CashDepositResponse.from(deposit)));
    }

    /**
     * POST /api/v1/cash/deposits/{id}/approve
     * Phê duyệt lệnh nạp tiền tại quầy bởi Kiểm soát viên.
     * RÀNG BUỘC CỐT LÕI:
     *  1. Chỉ ROLE_MANAGER mới có quyền phê duyệt.
     *  2. CHẶN ĐỨNG vi phạm Maker-Checker: maker_id != checker_id.
     */
    @PostMapping("/deposits/{id}/approve")
    @Transactional
    public ResponseEntity<ApiResponse<CashDepositResponse>> approveDeposit(
            @PathVariable String id,
            @RequestHeader(value = "X-User-Id", required = false) String headerCheckerId,
            @RequestHeader(value = "X-User-Role", required = false) String headerRole,
            @RequestBody(required = false) CashDepositApproveRequest request,
            @RequestParam(value = "checkerId", required = false) String paramCheckerId,
            @RequestParam(value = "role", required = false) String paramRole) {

        // 1. Kiểm tra phân quyền: CHỈ ROLE_MANAGER MỚI ĐƯỢC DUYỆT
        String role = resolveRole(headerRole, request != null ? request.getRole() : null, paramRole);
        if (role == null || !ROLE_MANAGER.equalsIgnoreCase(role.trim())) {
            log.warn("Access denied: user role '{}' is not ROLE_MANAGER on approve deposit {}", role, id);
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(ApiResponse.error("Từ chối truy cập: Chỉ ROLE_MANAGER mới có quyền phê duyệt lệnh nạp tiền!"));
        }

        // 2. Xác định Checker ID
        String checkerId = resolveCheckerId(headerCheckerId, request != null ? request.getCheckerId() : null, paramCheckerId);
        if (checkerId == null || checkerId.isBlank()) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Checker ID không được để trống khi phê duyệt"));
        }

        // 3. Tìm kiếm giao dịch nạp tiền (hỗ trợ cả UUID lẫn deposit_code)
        CashDeposit deposit = cashDepositRepository.findById(id)
                .or(() -> cashDepositRepository.findByDepositCode(id))
                .orElseThrow(() -> new IllegalArgumentException("Lệnh nạp tiền không tìm thấy: " + id));

        // 4. CHẶN MAKER == CHECKER (Four-Eyes Principle / Maker-Checker Rule)
        if (deposit.getMakerId() != null && deposit.getMakerId().trim().equalsIgnoreCase(checkerId.trim())) {
            log.error("Security violation: Maker {} tried to approve own deposit {}", checkerId, id);
            throw new MakerCheckerViolationException(deposit.getMakerId(), checkerId);
        }

        // 5. Kiểm tra trạng thái giao dịch
        if (!CashDeposit.STATUS_PENDING_APPROVAL.equals(deposit.getStatus())) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Chỉ có thể phê duyệt giao dịch ở trạng thái PENDING_APPROVAL. Hiện tại: " + deposit.getStatus()));
        }

        // 6. Thực hiện phê duyệt & hoàn tất
        makerCheckerRule.approveDeposit(deposit, checkerId);
        deposit.complete();
        deposit = cashDepositRepository.save(deposit);

        // 7. Gửi sự kiện Kafka hoàn tất sang Ledger Service hạch toán Sổ cái kép
        paymentKafkaProducer.sendCashDepositCompleted(
                deposit.getDepositCode(),
                deposit.getAccountNumber(),
                deposit.getCustomerName(),
                deposit.getAmount(),
                deposit.getBranchId()
        );

        log.info("Deposit approved and completed: code={} checker={}", deposit.getDepositCode(), checkerId);
        return ResponseEntity.ok(ApiResponse.success("Phê duyệt lệnh nạp tiền thành công", CashDepositResponse.from(deposit)));
    }

    /**
     * POST /api/v1/cash/deposits/{id}/reject
     * Từ chối lệnh nạp tiền tại quầy bởi Kiểm soát viên.
     * RÀNG BUỘC CỐT LÕI:
     *  1. Chỉ ROLE_MANAGER mới có quyền từ chối (nếu role được truyền).
     *  2. CHẶN ĐỨNG maker_id == checker_id.
     */
    @PostMapping("/deposits/{id}/reject")
    @Transactional
    public ResponseEntity<ApiResponse<CashDepositResponse>> rejectDeposit(
            @PathVariable String id,
            @RequestHeader(value = "X-User-Id", required = false) String headerCheckerId,
            @RequestHeader(value = "X-User-Role", required = false) String headerRole,
            @RequestBody(required = false) CashDepositRejectRequest request,
            @RequestParam(value = "checkerId", required = false) String paramCheckerId,
            @RequestParam(value = "role", required = false) String paramRole,
            @RequestParam(value = "reason", required = false) String paramReason) {

        // 1. Phân quyền nếu có thông tin role
        String role = resolveRole(headerRole, request != null ? request.getRole() : null, paramRole);
        if (role != null && !ROLE_MANAGER.equalsIgnoreCase(role.trim())) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(ApiResponse.error("Từ chối truy cập: Chỉ ROLE_MANAGER mới có quyền từ chối lệnh nạp tiền!"));
        }

        // 2. Xác định Checker ID
        String checkerId = resolveCheckerId(headerCheckerId, request != null ? request.getCheckerId() : null, paramCheckerId);
        if (checkerId == null || checkerId.isBlank()) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Checker ID không được để trống khi từ chối"));
        }

        // 3. Tìm kiếm giao dịch
        CashDeposit deposit = cashDepositRepository.findById(id)
                .or(() -> cashDepositRepository.findByDepositCode(id))
                .orElseThrow(() -> new IllegalArgumentException("Lệnh nạp tiền không tìm thấy: " + id));

        // 4. CHẶN MAKER == CHECKER
        if (deposit.getMakerId() != null && deposit.getMakerId().trim().equalsIgnoreCase(checkerId.trim())) {
            throw new MakerCheckerViolationException(deposit.getMakerId(), checkerId);
        }

        // 5. Kiểm tra trạng thái
        if (!CashDeposit.STATUS_PENDING_APPROVAL.equals(deposit.getStatus())) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Chỉ có thể từ chối giao dịch ở trạng thái PENDING_APPROVAL. Hiện tại: " + deposit.getStatus()));
        }

        String reason = (request != null && request.getReason() != null && !request.getReason().isBlank())
                ? request.getReason()
                : (paramReason != null && !paramReason.isBlank() ? paramReason : "Từ chối bởi Kiểm soát viên");

        makerCheckerRule.rejectDeposit(deposit, checkerId, reason);
        deposit = cashDepositRepository.save(deposit);

        log.info("Deposit rejected: code={} checker={} reason={}", deposit.getDepositCode(), checkerId, reason);
        return ResponseEntity.ok(ApiResponse.success("Từ chối lệnh nạp tiền thành công", CashDepositResponse.from(deposit)));
    }

    /**
     * GET /api/v1/cash/deposits
     * Truy vấn danh sách giao dịch nạp tiền tại quầy, hỗ trợ lọc theo status, makerId, branchId.
     */
    @GetMapping("/deposits")
    public ResponseEntity<ApiResponse<List<CashDepositResponse>>> listDeposits(
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String makerId,
            @RequestParam(required = false) String branchId) {

        List<CashDeposit> list;
        if (status != null && !status.isBlank()) {
            list = cashDepositRepository.findByStatusOrderByCreatedAtDesc(status.trim());
        } else if (makerId != null && !makerId.isBlank()) {
            list = cashDepositRepository.findByMakerIdOrderByCreatedAtDesc(makerId.trim());
        } else if (branchId != null && !branchId.isBlank()) {
            list = cashDepositRepository.findByBranchIdOrderByCreatedAtDesc(branchId.trim());
        } else {
            list = cashDepositRepository.findAllByOrderByCreatedAtDesc();
        }

        List<CashDepositResponse> responses = list.stream()
                .map(CashDepositResponse::from)
                .toList();

        return ResponseEntity.ok(ApiResponse.success("Danh sách giao dịch nạp tiền tại quầy", responses));
    }

    /**
     * GET /api/v1/cash/vault/summary
     * Báo cáo thống kê quỹ tiền mặt trong ngày tại quầy giao dịch (Vault Summary).
     */
    @GetMapping("/vault/summary")
    public ResponseEntity<ApiResponse<VaultSummaryResponse>> getVaultSummary(
            @RequestParam(required = false, defaultValue = "BR_Q1") String branchId) {

        long openingBalance = DEFAULT_OPENING_VAULT_BALANCE;
        long maxLimit = DEFAULT_MAX_VAULT_LIMIT;

        long totalCashIn = cashDepositRepository.sumCompletedAmount();
        long successCount = cashDepositRepository.countByStatus(CashDeposit.STATUS_COMPLETED);
        long pendingCount = cashDepositRepository.countByStatus(CashDeposit.STATUS_PENDING_APPROVAL);

        VaultSummaryResponse summary = VaultSummaryResponse.builder()
                .openingBalance(openingBalance)
                .totalCashIn(totalCashIn)
                .currentBalance(openingBalance + totalCashIn)
                .maxLimit(maxLimit)
                .successCount(successCount)
                .pendingCount(pendingCount)
                .build();

        return ResponseEntity.ok(ApiResponse.success("Tổng kết quỹ tiền mặt quầy", summary));
    }

    private String resolveRole(String headerRole, String bodyRole, String paramRole) {
        if (headerRole != null && !headerRole.isBlank()) return headerRole.trim();
        if (bodyRole != null && !bodyRole.isBlank()) return bodyRole.trim();
        if (paramRole != null && !paramRole.isBlank()) return paramRole.trim();
        return null;
    }

    private String resolveCheckerId(String headerCheckerId, String bodyCheckerId, String paramCheckerId) {
        if (headerCheckerId != null && !headerCheckerId.isBlank()) return headerCheckerId.trim();
        if (bodyCheckerId != null && !bodyCheckerId.isBlank()) return bodyCheckerId.trim();
        if (paramCheckerId != null && !paramCheckerId.isBlank()) return paramCheckerId.trim();
        return null;
    }
}
