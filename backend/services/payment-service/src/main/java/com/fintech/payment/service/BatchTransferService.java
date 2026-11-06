package com.fintech.payment.service;

import com.fintech.payment.dto.*;
import com.fintech.payment.grpc.WalletGrpcClient;
import com.fintech.payment.grpc.dto.WalletInfoResult;
import com.fintech.payment.saga.PaymentSagaOrchestrator;
import com.fintech.payment.saga.SagaContext;
import com.fintech.payment.security.PinTokenValidator;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

import java.util.*;

@Slf4j
@Service
public class BatchTransferService {

    private final PaymentSagaOrchestrator sagaOrchestrator;
    private final WalletGrpcClient walletGrpcClient;
    private final PinTokenValidator pinTokenValidator;
    private final RestClient identityClient;

    public BatchTransferService(
            PaymentSagaOrchestrator sagaOrchestrator,
            WalletGrpcClient walletGrpcClient,
            PinTokenValidator pinTokenValidator,
            @Value("${identity.service.url:http://identity-service:8081}") String identityServiceUrl) {
        this.sagaOrchestrator = sagaOrchestrator;
        this.walletGrpcClient = walletGrpcClient;
        this.pinTokenValidator = pinTokenValidator;
        this.identityClient = RestClient.builder().baseUrl(identityServiceUrl).build();
    }

    public BatchTransferResponse executeBatchTransfer(String callerUserId, BatchTransferRequest request) {
        String batchId = "BATCH_" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
        String batchName = (request.getBatchName() != null && !request.getBatchName().isBlank())
                ? request.getBatchName()
                : "Chi lương / Chuyển tiền theo lô (" + batchId + ")";

        // 1. Xác định ví nguồn
        String sourceUserId = callerUserId;
        WalletInfoResult sourceWallet = null;
        if (request.getSourceWalletId() != null && !request.getSourceWalletId().isBlank()) {
            sourceWallet = walletGrpcClient.getWalletByUserId(request.getSourceWalletId());
        }
        if (sourceWallet == null || !sourceWallet.isFound()) {
            sourceWallet = walletGrpcClient.getWalletByUserId(callerUserId);
        }
        if (sourceWallet == null || !sourceWallet.isFound()) {
            throw new IllegalArgumentException("Không tìm thấy ví nguồn hợp lệ để thực hiện lệnh chi theo lô");
        }
        sourceUserId = sourceWallet.getUserId();

        // 2. Tính tổng tiền và kiểm tra số dư sơ bộ
        long totalRequestedAmount = 0L;
        for (BatchTransferItemRequest item : request.getItems()) {
            totalRequestedAmount += (item.getAmount() != null ? item.getAmount() : 0L);
        }

        if (sourceWallet.getBalance() != null && sourceWallet.getBalance() < totalRequestedAmount) {
            throw new IllegalArgumentException("Số dư ví nguồn không đủ (" + sourceWallet.getBalance() + " VND) để chi theo lô tổng số tiền " + totalRequestedAmount + " VND");
        }

        // 3. Thực thi tuần tự từng lệnh qua Saga Orchestrator
        int successCount = 0;
        int failedCount = 0;
        long successAmount = 0L;
        List<BatchTransferItemResult> results = new ArrayList<>();

        int index = 0;
        for (BatchTransferItemRequest item : request.getItems()) {
            index++;
            String itemAccount = item.getAccountNumber().trim();
            Long amount = item.getAmount();
            String note = (item.getNote() != null && !item.getNote().isBlank())
                    ? item.getNote()
                    : batchName;

            String targetUserId = resolveTargetUserId(itemAccount);
            if (targetUserId == null) {
                failedCount++;
                results.add(BatchTransferItemResult.builder()
                        .accountNumber(itemAccount)
                        .recipientName(item.getRecipientName())
                        .amount(amount)
                        .status("FAILED")
                        .errorMessage("Không tìm thấy tài khoản người nhận: " + itemAccount)
                        .build());
                continue;
            }

            String idemKey = "batch_" + batchId + "_" + index + "_" + UUID.randomUUID().toString().substring(0, 6);
            try {
                SagaContext ctx = sagaOrchestrator.transferP2p(
                        sourceUserId,
                        targetUserId,
                        amount,
                        "VND",
                        note,
                        idemKey
                );

                if ("SUCCESS".equalsIgnoreCase(ctx.getStatus())) {
                    successCount++;
                    successAmount += amount;
                    results.add(BatchTransferItemResult.builder()
                            .accountNumber(itemAccount)
                            .recipientName(item.getRecipientName())
                            .amount(amount)
                            .status("SUCCESS")
                            .transactionId(ctx.getTransactionId())
                            .build());
                } else {
                    failedCount++;
                    results.add(BatchTransferItemResult.builder()
                            .accountNumber(itemAccount)
                            .recipientName(item.getRecipientName())
                            .amount(amount)
                            .status("FAILED")
                            .errorMessage(ctx.getFailureReason() != null ? ctx.getFailureReason() : "Thất bại khi trừ/cộng tiền")
                            .build());
                }
            } catch (Exception e) {
                log.error("Lỗi khi xử lý lệnh chi hộ cho {}: {}", itemAccount, e.getMessage());
                failedCount++;
                results.add(BatchTransferItemResult.builder()
                        .accountNumber(itemAccount)
                        .recipientName(item.getRecipientName())
                        .amount(amount)
                        .status("FAILED")
                        .errorMessage(e.getMessage())
                        .build());
            }
        }

        return BatchTransferResponse.builder()
                .batchId(batchId)
                .batchName(batchName)
                .totalCount(request.getItems().size())
                .successCount(successCount)
                .failedCount(failedCount)
                .totalAmount(totalRequestedAmount)
                .successAmount(successAmount)
                .items(results)
                .build();
    }

    private String resolveTargetUserId(String input) {
        if (input == null || input.isBlank()) return null;
        String clean = input.trim();

        // 1. Thử trực tiếp qua Wallet gRPC (nếu là UUID userId hoặc walletId)
        try {
            var res = walletGrpcClient.getWalletByUserId(clean);
            if (res != null && res.isFound() && res.getUserId() != null) {
                return res.getUserId();
            }
        } catch (Exception ignored) {}

        // 2. Tra cứu qua Identity Service (Số điện thoại hoặc Alias)
        try {
            Map<?, ?> identity = identityClient.get()
                    .uri(uriBuilder -> uriBuilder
                            .path("/api/v1/internal/users/by-phone")
                            .queryParam("phoneNumber", clean)
                            .build())
                    .retrieve()
                    .body(Map.class);

            if (identity != null && identity.get("id") != null) {
                return identity.get("id").toString();
            }
        } catch (Exception ignored) {}

        return null;
    }
}

