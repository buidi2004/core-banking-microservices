package com.fintech.payment.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fintech.payment.domain.entity.CashDeposit;
import com.fintech.payment.domain.entity.OutboxEvent;
import com.fintech.payment.domain.entity.Transaction;
import com.fintech.payment.dto.*;
import com.fintech.payment.exception.MakerCheckerViolationException;
import com.fintech.payment.grpc.WalletGrpcClient;
import com.fintech.payment.grpc.dto.WalletBalanceResult;
import com.fintech.payment.kafka.PaymentKafkaProducer;
import com.fintech.payment.repository.CashDepositRepository;
import com.fintech.payment.repository.OutboxEventRepository;
import com.fintech.payment.repository.TransactionRepository;
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
    private final WalletGrpcClient walletGrpcClient;
    private final TransactionRepository transactionRepository;
    private final OutboxEventRepository outboxEventRepository;
    private final ObjectMapper objectMapper;
    private final com.fintech.payment.repository.CashInTransitRepository cashInTransitRepository;

    @org.springframework.beans.factory.annotation.Value("${identity.service.url:http://identity-service:8081}")
    private String identityServiceUrl;

    private String resolveUserIdByAccount(String account) {
        if (account == null || account.isBlank()) return null;
        String clean = account.trim();
        if (clean.matches("^[0-9a-fA-F\\-]{36}$")) {
            return clean;
        }
        try {
            var client = org.springframework.web.client.RestClient.builder()
                    .baseUrl(identityServiceUrl != null ? identityServiceUrl : "http://identity-service:8081")
                    .build();
            java.util.Map<?, ?> identity = client.get()
                    .uri(uriBuilder -> uriBuilder
                            .path("/api/v1/internal/users/by-phone")
                            .queryParam("phoneNumber", clean)
                            .build())
                    .retrieve()
                    .body(java.util.Map.class);
            if (identity != null && identity.get("id") != null) {
                return identity.get("id").toString();
            }
        } catch (Exception e) {
            log.debug("Không thể phân giải số điện thoại {} qua identity-service: {}", clean, e.getMessage());
        }
        return null;
    }

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
            @RequestHeader(value = "X-Branch-Id", required = false) String trustedBranchId,
            @RequestHeader(value = "Idempotency-Key", required = false) String headerIdemKey) {

        if (headerMakerId == null || headerMakerId.isBlank()) {
            headerMakerId = request.getMakerId();
        }
        if (headerMakerId == null || headerMakerId.isBlank()) {
            headerMakerId = DEFAULT_TELLER_ID;
        }

        if (trustedBranchId == null || trustedBranchId.isBlank()) {
            trustedBranchId = request.getBranchId();
        }
        if (trustedBranchId == null || trustedBranchId.isBlank()) {
            trustedBranchId = "BR_Q1";
        }

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

        // 2. Maker luôn lấy từ trusted Gateway header, không tin request body.
        String makerId = headerMakerId.trim();
        String branchId = trustedBranchId != null && !trustedBranchId.isBlank()
                ? trustedBranchId.trim()
                : request.getBranchId();

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
                .branchId(branchId != null && !branchId.isBlank() ? branchId : "BR_Q1")
                .makerId(makerId.trim())
                .idempotencyKey(idemKey);

        if (requiresApproval) {
            // Vượt hạn mức 50M -> Chuyển sang trạng thái PENDING_APPROVAL
            depositBuilder.status(CashDeposit.STATUS_PENDING_APPROVAL);
            CashDeposit deposit = cashDepositRepository.save(depositBuilder.build());
            return ResponseEntity.ok(ApiResponse.success("Lệnh nạp tiền đã tạo, chờ Kiểm soát viên phê duyệt", CashDepositResponse.from(deposit)));
        } else {
            // Trong hạn mức <= 50M -> Tự động duyệt hoàn tất (COMPLETED)
            depositBuilder.status(CashDeposit.STATUS_COMPLETED)
                    .checkerId("AUTO_RULE")
                    .approvedAt(Instant.now())
                    .completedAt(Instant.now());

            CashDeposit deposit = depositBuilder.build();
            boolean credited = creditWalletBalance(deposit);
            if (!credited && walletGrpcClient != null) {
                log.error("Tự động duyệt nạp tiền thất bại do không thể cộng tiền ví: {}", deposit.getDepositCode());
                depositBuilder.status(CashDeposit.STATUS_FAILED);
                cashDepositRepository.save(depositBuilder.build());
                return ResponseEntity.status(HttpStatus.UNPROCESSABLE_ENTITY)
                        .body(ApiResponse.error("Không thể cộng tiền vào ví người nhận. Vui lòng kiểm tra lại tài khoản ví."));
            }

            deposit = cashDepositRepository.save(deposit);
            paymentKafkaProducer.sendCashDepositCompleted(
                    deposit.getDepositCode(),
                    deposit.getAccountNumber(),
                    deposit.getCustomerName(),
                    deposit.getAmount(),
                    deposit.getBranchId()
            );
            return ResponseEntity.ok(ApiResponse.success("Nạp tiền thành công (Tự động duyệt do số tiền <= 50,000,000 VND)", CashDepositResponse.from(deposit)));
        }
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

        // 6. Cộng tiền vào ví người dùng qua gRPC sang Wallet Service TRƯỚC KHI hoàn tất
        boolean credited = creditWalletBalance(deposit);
        if (!credited && walletGrpcClient != null) {
            log.error("Cộng tiền vào ví thất bại cho lệnh nạp: {}", deposit.getDepositCode());
            return ResponseEntity.status(HttpStatus.UNPROCESSABLE_ENTITY)
                    .body(ApiResponse.error("Không thể cộng tiền vào ví người nhận. Vui lòng kiểm tra lại tài khoản ví hoặc hệ thống lõi ví."));
        }

        // 7. Thực hiện phê duyệt & hoàn tất
        makerCheckerRule.approveDeposit(deposit, checkerId);
        deposit.complete();
        deposit = cashDepositRepository.save(deposit);

        // 8. Gửi sự kiện Kafka hoàn tất sang Ledger Service hạch toán Sổ cái kép
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
    @GetMapping({"/vault/summary", "/vault-summary"})
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

    /**
     * POST /api/v1/cash/vault/transfer
     * Lập lệnh điều chuyển tiền mặt két quỹ (Cash in Transit - CIT).
     * Áp dụng quy chuẩn ngân hàng: Hạn mức > 100.000.000 VND yêu cầu Giám đốc phê duyệt.
     */
    @PostMapping("/vault/transfer")
    public ResponseEntity<ApiResponse<CitOrderResponse>> createVaultTransfer(
            @RequestHeader(value = "X-User-Id", required = false, defaultValue = "teller1") String staffId,
            @RequestHeader(value = "X-User-Role", required = false) String staffRole,
            @Valid @RequestBody CreateCitOrderRequest request) {

        String orderCode = "CIT-" + System.currentTimeMillis();
        boolean autoApprove = request.getAmount().compareTo(new java.math.BigDecimal("100000000")) <= 0
                || (staffRole != null && staffRole.contains("MANAGER"));

        com.fintech.payment.domain.entity.CashInTransitOrder order = com.fintech.payment.domain.entity.CashInTransitOrder.builder()
                .orderCode(orderCode)
                .fromBranchId(request.getFromBranchId().trim())
                .toBranchId(request.getToBranchId().trim())
                .amount(request.getAmount())
                .currency(request.getCurrency() != null ? request.getCurrency() : "VND")
                .transportStaffName(request.getTransportStaffName().trim())
                .sealNumber(request.getSealNumber().trim())
                .note(request.getNote())
                .status(autoApprove ? "COMPLETED" : "PENDING_APPROVAL")
                .createdBy(staffId)
                .approvedBy(autoApprove ? staffId : null)
                .approvedAt(autoApprove ? Instant.now() : null)
                .build();

        order = cashInTransitRepository.save(order);
        log.info("Đã lập lệnh điều chuyển tiền mặt két quỹ: {} status={}", orderCode, order.getStatus());

        return ResponseEntity.ok(ApiResponse.success(
                autoApprove ? "Điều chuyển tiền mặt két quỹ thành công" : "Lệnh điều chuyển két quỹ đã lập, chờ Giám đốc duyệt",
                CitOrderResponse.from(order)));
    }

    @GetMapping("/vault/transfers")
    public ResponseEntity<ApiResponse<List<CitOrderResponse>>> getVaultTransfers(
            @RequestParam(required = false) String status) {
        List<com.fintech.payment.domain.entity.CashInTransitOrder> list = (status != null && !status.isBlank() && !"ALL".equalsIgnoreCase(status))
                ? cashInTransitRepository.findByStatusOrderByCreatedAtDesc(status.trim().toUpperCase())
                : cashInTransitRepository.findAllByOrderByCreatedAtDesc();

        List<CitOrderResponse> responses = list.stream().map(CitOrderResponse::from).toList();
        return ResponseEntity.ok(ApiResponse.success("Danh sách lệnh điều chuyển tiền mặt két quỹ", responses));
    }

    @PostMapping("/vault/transfers/{id}/approve")
    public ResponseEntity<ApiResponse<CitOrderResponse>> approveVaultTransfer(
            @RequestHeader(value = "X-User-Id", required = false, defaultValue = "manager1") String managerId,
            @RequestHeader(value = "X-User-Role", required = false) String managerRole,
            @PathVariable("id") UUID id) {
        if (managerRole == null
                || (!ROLE_MANAGER.equalsIgnoreCase(managerRole.trim())
                && !"MANAGER".equalsIgnoreCase(managerRole.trim()))) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        com.fintech.payment.domain.entity.CashInTransitOrder order = cashInTransitRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy lệnh điều chuyển: " + id));

        order.setStatus("COMPLETED");
        order.setApprovedBy(managerId);
        order.setApprovedAt(Instant.now());
        order = cashInTransitRepository.save(order);

        log.info("Giám đốc {} đã phê duyệt lệnh điều chuyển két quỹ: {}", managerId, order.getOrderCode());
        return ResponseEntity.ok(ApiResponse.success("Phê duyệt lệnh điều chuyển két quỹ thành công", CitOrderResponse.from(order)));
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

    private boolean creditWalletBalance(CashDeposit deposit) {
        if (walletGrpcClient == null) {
            return true;
        }
        if (deposit.getAccountNumber() == null || deposit.getAccountNumber().isBlank()) {
            return false;
        }

        String inputAccount = deposit.getAccountNumber().trim();
        String idemKey = (deposit.getIdempotencyKey() != null && !deposit.getIdempotencyKey().isBlank())
                ? deposit.getIdempotencyKey() + ":credit"
                : "dep_credit:" + deposit.getDepositCode();

        String targetWalletId = inputAccount;
        String targetUserId = null;

        try {
            // Tra cứu thông tin ví: nếu inputAccount là số điện thoại hoặc alias, phân giải sang userId trước
            String resolvedUserId = resolveUserIdByAccount(inputAccount);
            String searchKey = (resolvedUserId != null) ? resolvedUserId : inputAccount;

            var userInfo = walletGrpcClient.getWalletByUserId(searchKey);
            if (userInfo != null && userInfo.isFound() && userInfo.getWalletId() != null) {
                targetWalletId = userInfo.getWalletId();
                targetUserId = userInfo.getUserId();
            } else if (resolvedUserId != null) {
                targetUserId = resolvedUserId;
            }

            WalletBalanceResult creditRes = walletGrpcClient.credit(
                    targetWalletId,
                    deposit.getAmount(),
                    deposit.getDepositCode(),
                    idemKey
            );

            // Nếu không tìm thấy theo walletId, thử tra cứu lại theo searchKey
            if (creditRes != null && !creditRes.isSuccess() && "WALLET_NOT_FOUND".equalsIgnoreCase(creditRes.getErrorCode())) {
                userInfo = walletGrpcClient.getWalletByUserId(searchKey);
                if (userInfo != null && userInfo.isFound() && userInfo.getWalletId() != null) {
                    targetWalletId = userInfo.getWalletId();
                    targetUserId = userInfo.getUserId();
                    creditRes = walletGrpcClient.credit(
                            targetWalletId,
                            deposit.getAmount(),
                            deposit.getDepositCode(),
                            idemKey
                    );
                }
            }

            if (creditRes != null && creditRes.isSuccess()) {
                Long balanceAfter = creditRes.getBalanceAfter();
                log.info("Cộng tiền vào ví thành công: walletId={} userId={} amount={} balanceAfter={}",
                        targetWalletId, targetUserId, deposit.getAmount(), balanceAfter);

                // Ghi nhận Transaction và OutboxEvent để OutboxRelay đẩy sang Notification Service & Mobile
                recordDepositTransactionAndOutbox(deposit, targetWalletId, targetUserId, balanceAfter);
                return true;
            } else {
                String err = creditRes != null ? creditRes.getErrorMessage() : "Unknown gRPC error";
                log.error("Cộng tiền ví thất bại: walletId={} error={}", targetWalletId, err);
                return false;
            }
        } catch (Exception e) {
            log.error("Lỗi khi gọi gRPC credit sang Wallet Service cho walletId={}: {}",
                    targetWalletId, e.getMessage(), e);
            return false;
        }
    }

    private void recordDepositTransactionAndOutbox(CashDeposit deposit, String targetWalletId, String targetUserId, Long balanceAfter) {
        if (transactionRepository == null || outboxEventRepository == null || objectMapper == null) {
            return;
        }
        try {
            String txIdemKey = (deposit.getIdempotencyKey() != null && !deposit.getIdempotencyKey().isBlank())
                    ? deposit.getIdempotencyKey()
                    : "dep_tx_" + deposit.getDepositCode();

            Optional<Transaction> existingTx = transactionRepository.findByIdempotencyKey(txIdemKey);
            if (existingTx.isPresent()) {
                log.info("Transaction cho lệnh nạp tiền đã tồn tại: txId={}", existingTx.get().getId());
                return;
            }

            Transaction tx = Transaction.builder()
                    .transactionCode(deposit.getDepositCode())
                    .targetWalletId(targetWalletId)
                    .receiverId(targetUserId)
                    .amount(deposit.getAmount())
                    .fee(0L)
                    .currency(deposit.getCurrency() != null ? deposit.getCurrency() : "VND")
                    .type("DEPOSIT")
                    .status("SUCCESS")
                    .idempotencyKey(txIdemKey)
                    .note("Nạp tiền mặt tại quầy " + deposit.getBranchId() + " - " + deposit.getCustomerName())
                    .targetBalanceAfter(balanceAfter)
                    .build();
            tx = transactionRepository.save(tx);

            // Bắn OutboxEvent để OutboxRelay phát tán sang RabbitMQ (NotificationService) và Kafka
            com.fintech.wallet.domain.event.TransactionEvent completedEvent = new com.fintech.wallet.domain.event.TransactionEvent();
            completedEvent.setEventId(UUID.randomUUID().toString());
            completedEvent.setTransactionId(tx.getId());
            completedEvent.setType("DEPOSIT");
            completedEvent.setStatus("SUCCESS");
            completedEvent.setTargetWalletId(targetWalletId);
            completedEvent.setTargetUserId(targetUserId);
            completedEvent.setAmount(java.math.BigDecimal.valueOf(deposit.getAmount()));
            completedEvent.setFeeAmount(java.math.BigDecimal.ZERO);
            completedEvent.setCurrency(tx.getCurrency());
            completedEvent.setNote(tx.getNote());
            if (balanceAfter != null) {
                completedEvent.setTargetBalanceAfter(java.math.BigDecimal.valueOf(balanceAfter));
            }
            completedEvent.setOccurredAt(Instant.now());

            OutboxEvent outbox = OutboxEvent.pending(
                    "Transaction",
                    tx.getId(),
                    "TransactionCompletedEvent",
                    objectMapper.writeValueAsString(completedEvent)
            );
            outboxEventRepository.save(outbox);
            log.info("Đã tạo Transaction và OutboxEvent nạp tiền thành công: txId={} outboxId={}", tx.getId(), outbox.getId());
        } catch (Exception e) {
            log.error("Lỗi khi ghi nhận Transaction/OutboxEvent cho nạp tiền tại quầy: {}", e.getMessage(), e);
        }
    }
}
