package com.fintech.payment.controller;

import com.fintech.payment.domain.entity.Transaction;
import com.fintech.payment.dto.ApiResponse;
import com.fintech.payment.repository.TransactionRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

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

    public TransactionHistoryController(TransactionRepository transactionRepository) {
        this.transactionRepository = transactionRepository;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> list(
            @RequestParam String walletId,
            @RequestParam(required = false) String type,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {

        int safePage = Math.max(page, 0);
        int safeSize = Math.min(Math.max(size, 1), 100);
        String normalizedType = type != null ? type.trim().toUpperCase() : "";

        Page<Transaction> result = transactionRepository.findWalletHistory(
                walletId, normalizedType, PageRequest.of(safePage, safeSize));

        List<Map<String, Object>> content = result.getContent().stream()
                .map(tx -> toView(tx, walletId))
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

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> detail(
            @PathVariable String id,
            @RequestParam(required = false) String walletId) {

        Optional<Transaction> found = transactionRepository.findById(id);
        if (found.isEmpty()) {
            return ResponseEntity.status(404)
                    .body(ApiResponse.error("Không tìm thấy giao dịch: " + id));
        }
        Transaction tx = found.get();
        String perspective = walletId != null && !walletId.isBlank()
                ? walletId
                : tx.getSourceWalletId();
        return ResponseEntity.ok(ApiResponse.success("Transaction retrieved", toView(tx, perspective)));
    }

    private Map<String, Object> toView(Transaction tx, String walletId) {
        boolean isSource = walletId != null && walletId.equals(tx.getSourceWalletId());
        boolean transfer = "TRANSFER".equalsIgnoreCase(tx.getType());

        String displayType;
        if (transfer) {
            displayType = isSource ? "TRANSFER_OUT" : "TRANSFER_IN";
        } else {
            displayType = tx.getType();
        }

        Long balanceAfter = isSource ? tx.getSourceBalanceAfter() : tx.getTargetBalanceAfter();
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
