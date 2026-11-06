package com.fintech.payment.controller;

import com.fintech.payment.domain.entity.Transaction;
import com.fintech.payment.dto.ApiResponse;
import com.fintech.payment.repository.TransactionRepository;
import com.fintech.payment.service.ReceiptExportService;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

/**
 * API lịch sử biến động số dư cho Mobile.
 *
 * Hợp đồng response khớp với client Flutter:
 * { success, message, data: { content: [...], page, size, totalElements, totalPages, last } }
 *
 * Mỗi item trả về runningBalance = số dư của chính ví đang truy vấn sau giao dịch
 * (snapshot source_balance_after / target_balance_after do Wallet Service trả về khi saga chạy).
 */
@RestController
@RequestMapping("/api/v1/transactions")
public class TransactionHistoryController {

    private final TransactionRepository transactionRepository;
    private final ReceiptExportService receiptExportService;
    private final com.fintech.payment.grpc.WalletGrpcClient walletGrpcClient;

    @org.springframework.beans.factory.annotation.Autowired
    public TransactionHistoryController(TransactionRepository transactionRepository,
                                        ReceiptExportService receiptExportService,
                                        @org.springframework.beans.factory.annotation.Autowired(required = false)
                                        com.fintech.payment.grpc.WalletGrpcClient walletGrpcClient) {
        this.transactionRepository = transactionRepository;
        this.receiptExportService = receiptExportService;
        this.walletGrpcClient = walletGrpcClient;
    }

    @GetMapping(value = "/{id}/receipt.pdf", produces = {MediaType.APPLICATION_PDF_VALUE, MediaType.APPLICATION_OCTET_STREAM_VALUE, MediaType.ALL_VALUE})
    public ResponseEntity<byte[]> getReceiptPdf(
            @PathVariable String id,
            @org.springframework.web.bind.annotation.RequestHeader(value = "X-User-Id", required = false)
            String headerUserId,
            @RequestParam(required = false) String walletId) {
        Transaction tx = requireTransactionAccess(id, headerUserId, walletId);
        byte[] pdf = receiptExportService.generateReceiptPdf(id);
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=receipt-" + id + ".pdf")
                .contentType(MediaType.APPLICATION_PDF)
                .body(pdf);
    }

    public ResponseEntity<byte[]> getReceiptPdf(String id) {
        byte[] pdf = receiptExportService.generateReceiptPdf(id);
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=receipt-" + id + ".pdf")
                .contentType(MediaType.APPLICATION_PDF)
                .body(pdf);
    }

    public ResponseEntity<byte[]> exportTransactions(String format, String walletId) {
        return exportTransactions(format, null, walletId);
    }

    @GetMapping(value = "/export/{format}")
    public ResponseEntity<byte[]> exportTransactions(
            @PathVariable String format,
            @org.springframework.web.bind.annotation.RequestHeader(value = "X-User-Id", required = false) String headerUserId,
            @RequestParam(required = false) String walletId) {
        String targetWalletId = resolveOwnedWallet(headerUserId, walletId);
        byte[] data = receiptExportService.exportTransactions(targetWalletId, format);
        String mediaType = "pdf".equalsIgnoreCase(format) ? MediaType.APPLICATION_PDF_VALUE : "text/csv; charset=UTF-8";
        String ext = "pdf".equalsIgnoreCase(format) ? "pdf" : "csv";
        String fileSuffix = (targetWalletId != null && !targetWalletId.isBlank()) ? targetWalletId : "all";
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=statement-" + fileSuffix + "." + ext)
                .header(HttpHeaders.CONTENT_TYPE, mediaType)
                .body(data);
    }

    @GetMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> list(
            @org.springframework.web.bind.annotation.RequestHeader(value = "X-User-Id", required = false) String headerUserId,
            @RequestParam(required = false) String walletId,
            @RequestParam(required = false) String type,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {

        int safePage = Math.max(page, 0);
        int safeSize = Math.min(Math.max(size, 1), 100);
        String targetWalletId = resolveOwnedWallet(headerUserId, walletId);

        if (targetWalletId == null || targetWalletId.isBlank()) {
            Map<String, Object> emptyData = new LinkedHashMap<>();
            emptyData.put("content", List.of());
            emptyData.put("page", safePage);
            emptyData.put("size", safeSize);
            emptyData.put("totalElements", 0L);
            emptyData.put("totalPages", 0);
            emptyData.put("last", true);
            return ResponseEntity.ok(ApiResponse.success("Transactions retrieved", emptyData));
        }

        String normalizedType = type != null ? type.trim().toUpperCase() : "";

        Page<Transaction> result = transactionRepository.findWalletHistory(
                targetWalletId, normalizedType, PageRequest.of(safePage, safeSize));

        final String finalWalletId = targetWalletId;
        List<Map<String, Object>> content = result.getContent().stream()
                .map(tx -> toView(tx, finalWalletId))
                .toList();

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("content", content);
        data.put("page", safePage);
        data.put("size", safeSize);
        data.put("totalElements", result.getTotalElements());
        data.put("totalPages", result.getTotalPages());
        data.put("last", result.isLast());

        return ResponseEntity.ok(ApiResponse.success("Transactions retrieved", data));
    }

    public ResponseEntity<ApiResponse<Map<String, Object>>> detail(String id, String walletId) {
        return detail(id, null, walletId);
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> detail(
            @PathVariable String id,
            @org.springframework.web.bind.annotation.RequestHeader(value = "X-User-Id", required = false) String headerUserId,
            @RequestParam(required = false) String walletId) {

        Transaction tx = requireTransactionAccess(id, headerUserId, walletId);
        String perspective = resolveOwnedWallet(headerUserId, walletId);
        return ResponseEntity.ok(ApiResponse.success("Transaction retrieved", toView(tx, perspective)));
    }

    private Transaction requireTransactionAccess(String id, String userId, String requestedWalletId) {
        if (userId == null || userId.isBlank()) {
            if (hasHttpRequest() || requestedWalletId == null || requestedWalletId.isBlank()) {
                throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Missing trusted header X-User-Id");
            }
        }
        Transaction tx = transactionRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND,
                        "Không tìm thấy giao dịch: " + id));
        String ownedWallet = resolveOwnedWallet(userId, requestedWalletId);
        if (ownedWallet == null
                || (!ownedWallet.equals(tx.getSourceWalletId()) && !ownedWallet.equals(tx.getTargetWalletId()))) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                    "Không có quyền xem giao dịch của ví khác");
        }
        return tx;
    }

    private String resolveOwnedWallet(String userId, String requestedWalletId) {
        if (userId == null || userId.isBlank()) {
            if (!hasHttpRequest()) {
                return requestedWalletId == null ? null : requestedWalletId.trim();
            }
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Missing trusted header X-User-Id");
        }
        if (walletGrpcClient == null) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,
                    "Wallet ownership service unavailable");
        }

        try {
            var walletInfo = walletGrpcClient.getWalletByUserId(userId);
            if (walletInfo == null || !walletInfo.isFound()
                    || walletInfo.getWalletId() == null || walletInfo.getWalletId().isBlank()) {
                throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Không xác định được ví của người dùng");
            }
            String ownedWallet = walletInfo.getWalletId();
            if (requestedWalletId != null && !requestedWalletId.isBlank()
                    && !ownedWallet.equals(requestedWalletId.trim())) {
                throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                        "Không có quyền truy cập ví được yêu cầu");
            }
            return ownedWallet;
        } catch (ResponseStatusException e) {
            throw e;
        } catch (Exception e) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,
                    "Không thể xác minh quyền sở hữu ví", e);
        }
    }

    private boolean hasHttpRequest() {
        return RequestContextHolder.getRequestAttributes() != null;
    }

    @GetMapping("/aml/large")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getLargeAmlTransactions(
            @RequestParam(defaultValue = "400000000") Long minAmount,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        int safePage = Math.max(page, 0);
        int safeSize = Math.min(Math.max(size, 1), 100);
        Page<Transaction> pageData = transactionRepository.findLargeTransactions(minAmount, PageRequest.of(safePage, safeSize));

        List<Map<String, Object>> content = pageData.getContent().stream()
                .map(this::toView)
                .collect(Collectors.toList());

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("content", content);
        data.put("page", safePage);
        data.put("size", safeSize);
        data.put("totalElements", pageData.getTotalElements());
        data.put("totalPages", pageData.getTotalPages());
        data.put("last", pageData.isLast());
        data.put("minThreshold", minAmount);
        data.put("standard", "Luật Phòng, chống rửa tiền 2022 (Ngưỡng báo cáo giao dịch giá trị lớn >= 400.000.000 VND)");

        return ResponseEntity.ok(ApiResponse.success("Báo cáo giao dịch giá trị lớn AML", data));
    }

    private Map<String, Object> toView(Transaction tx) {
        return toView(tx, null);
    }

    private Map<String, Object> toView(Transaction tx, String walletId) {
        boolean isSource = walletId != null && walletId.equals(tx.getSourceWalletId());
        boolean isReversed = "REVERSED".equalsIgnoreCase(tx.getStatus());
        boolean transfer = "TRANSFER".equalsIgnoreCase(tx.getType());

        String displayType;
        if (transfer) {
            if (isReversed) {
                // B-02 & B-03: Giao dịch đảo (hoàn tiền)
                // - Ví nguồn được hoàn tiền lại: hiển thị dương (TRANSFER_IN)
                // - Ví đích không thực nhận được tiền: loại trừ khỏi credit ảo (hiển thị REVERSED)
                displayType = isSource ? "TRANSFER_IN" : "REVERSED";
            } else {
                displayType = isSource ? "TRANSFER_OUT" : "TRANSFER_IN";
            }
        } else {
            displayType = isReversed ? "REVERSED" : tx.getType();
        }

        Long balanceAfter = isSource ? tx.getSourceBalanceAfter() : (isReversed ? null : tx.getTargetBalanceAfter());
        String counterpartyWalletId = isSource ? tx.getTargetWalletId() : tx.getSourceWalletId();

        Map<String, Object> view = new LinkedHashMap<>();
        view.put("transactionId", tx.getId());
        view.put("id", tx.getId());
        view.put("transactionCode", tx.getTransactionCode());
        view.put("requestId", tx.getIdempotencyKey());
        view.put("type", displayType);
        view.put("status", tx.getStatus());
        view.put("amount", tx.getAmount());
        view.put("fee", tx.getFee());
        view.put("currency", tx.getCurrency());
        view.put("note", tx.getNote());
        view.put("createdAt", tx.getCreatedAt());
        view.put("timestamp", tx.getCreatedAt());
        view.put("sourceWalletId", tx.getSourceWalletId());
        view.put("targetWalletId", tx.getTargetWalletId());
        view.put("counterpartyWalletId", counterpartyWalletId);
        view.put("counterpartyAccount", counterpartyWalletId);
        view.put("runningBalance", balanceAfter);
        view.put("balanceAfter", balanceAfter);
        // Tên đối tác/ngân hàng chưa có trong payment DB (database-per-service) — client fallback theo note.
        view.put("counterpartyName", null);
        view.put("counterpartyBankName", "SenHong");
        view.put("isInternal", true);
        return view;
    }
}
