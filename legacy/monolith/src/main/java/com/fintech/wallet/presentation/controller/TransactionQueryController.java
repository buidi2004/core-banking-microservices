package com.fintech.wallet.presentation.controller;

import com.fintech.wallet.domain.model.Transaction;
import com.fintech.wallet.domain.model.TransactionType;
import com.fintech.wallet.domain.port.in.TransactionQueryUseCase;
import com.fintech.wallet.presentation.response.ApiResponse;
import com.fintech.wallet.presentation.response.TransferResponse;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/v1/transactions")
public class TransactionQueryController {

    private final TransactionQueryUseCase transactionQueryUseCase;
    private final com.fintech.wallet.application.service.UserService userService;
    private final com.fintech.wallet.domain.port.in.GetWalletUseCase getWalletUseCase;
    private final com.fintech.wallet.domain.port.in.UserProfileUseCase userProfileUseCase;

    public TransactionQueryController(TransactionQueryUseCase transactionQueryUseCase,
                                      com.fintech.wallet.application.service.UserService userService,
                                      com.fintech.wallet.domain.port.in.GetWalletUseCase getWalletUseCase,
                                      com.fintech.wallet.domain.port.in.UserProfileUseCase userProfileUseCase) {
        this.transactionQueryUseCase = transactionQueryUseCase;
        this.userService = userService;
        this.getWalletUseCase = getWalletUseCase;
        this.userProfileUseCase = userProfileUseCase;
    }

    private TransferResponse enrichResponse(Transaction transaction, String queryWalletId) {
        TransferResponse response = TransferResponse.fromDomain(transaction);
        if ("TRANSFER".equals(response.getType()) && queryWalletId != null) {
            if (queryWalletId.equals(transaction.getSourceWalletId())) {
                response.setType("TRANSFER_OUT");
            } else if (queryWalletId.equals(transaction.getTargetWalletId())) {
                response.setType("TRANSFER_IN");
            }
        }
        boolean isInternal = transaction.getBankCode() == null || "SENHONG".equalsIgnoreCase(transaction.getBankCode());
        response.setIsInternal(isInternal);
        
        try {
            com.fintech.wallet.domain.model.User sourceUser = null;
            if (transaction.getSourceWalletId() != null) {
                com.fintech.wallet.domain.model.Wallet sourceWallet = getWalletUseCase.getWalletById(transaction.getSourceWalletId());
                sourceUser = userService.getUserById(sourceWallet.getOwnerId());
                response.setSenderName(getFullName(sourceUser));
                response.setSenderAccount(sourceUser.getPhoneNumber());
            } else {
                response.setSenderName("Hệ thống / Ngân hàng");
            }
            
            if (isInternal && transaction.getTargetWalletId() != null) {
                com.fintech.wallet.domain.model.Wallet targetWallet = getWalletUseCase.getWalletById(transaction.getTargetWalletId());
                com.fintech.wallet.domain.model.User targetUser = userService.getUserById(targetWallet.getOwnerId());
                response.setRecipientName(getFullName(targetUser));
                response.setRecipientAccount(targetUser.getPhoneNumber());
                
                if (queryWalletId != null && queryWalletId.equals(transaction.getSourceWalletId())) {
                    response.setCounterpartyName(getFullName(targetUser));
                    response.setCounterpartyAccount(targetUser.getPhoneNumber());
                    response.setCounterpartyBankName("SenHong");
                } else if (queryWalletId != null && queryWalletId.equals(transaction.getTargetWalletId())) {
                    response.setCounterpartyName(sourceUser != null ? getFullName(sourceUser) : "Hệ thống / Ngân hàng");
                    response.setCounterpartyAccount(sourceUser != null ? sourceUser.getPhoneNumber() : "");
                    response.setCounterpartyBankName("SenHong");
                    
                    if (transaction.getReceiverBalanceAfter() != null) {
                        response.setBalance(transaction.getReceiverBalanceAfter().getAmount());
                        response.setRunningBalance(transaction.getReceiverBalanceAfter().getAmount());
                    } else {
                        response.setBalance(null);
                        response.setRunningBalance(null);
                    }
                }
            } else {
                response.setRecipientName("Ngân hàng liên kết");
                // For external, account number might be stored in a different way, but we don't have it natively in Transaction model yet, so leave blank or fallback
                if (queryWalletId != null && queryWalletId.equals(transaction.getSourceWalletId())) {
                    response.setCounterpartyName("Ngân hàng liên kết");
                    response.setCounterpartyBankName(transaction.getBankCode());
                } else if (queryWalletId != null && queryWalletId.equals(transaction.getTargetWalletId())) {
                    response.setCounterpartyName(sourceUser != null ? getFullName(sourceUser) : "Hệ thống / Ngân hàng");
                    response.setCounterpartyAccount(sourceUser != null ? sourceUser.getPhoneNumber() : "");
                    response.setCounterpartyBankName(transaction.getBankCode());
                    
                    if (transaction.getReceiverBalanceAfter() != null) {
                        response.setBalance(transaction.getReceiverBalanceAfter().getAmount());
                        response.setRunningBalance(transaction.getReceiverBalanceAfter().getAmount());
                    } else {
                        response.setBalance(null);
                        response.setRunningBalance(null);
                    }
                }
            }
        } catch (Exception e) {
            // Ignore if user/wallet not found to avoid failing the whole query
        }
        
        return response;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<TransferResponse>>> getHistory(
            @RequestParam String walletId,
            @RequestParam(required = false) TransactionType type,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        List<Transaction> transactions = transactionQueryUseCase.getTransactionHistory(walletId, type, page, size);
        List<TransferResponse> response = transactions.stream()
                .map(tx -> enrichResponse(tx, walletId))
                .collect(Collectors.toList());
        return ResponseEntity.ok(ApiResponse.success("Transaction history retrieved", response));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<TransferResponse>> getById(@PathVariable String id) {
        Transaction transaction = transactionQueryUseCase.getTransactionById(id);
        TransferResponse response = enrichResponse(transaction, null);
        return ResponseEntity.ok(ApiResponse.success("Transaction retrieved", response));
    }

    @GetMapping("/export/csv")
    public ResponseEntity<byte[]> exportStatementCsv(
            @RequestParam String walletId,
            @RequestParam(required = false) Instant fromDate,
            @RequestParam(required = false) Instant toDate) {
        byte[] csvData = transactionQueryUseCase.exportStatementCsv(walletId, fromDate, toDate);
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=statement_" + walletId + ".csv")
                .contentType(MediaType.parseMediaType("text/csv"))
                .body(csvData);
    }

    @GetMapping("/export/pdf")
    public ResponseEntity<byte[]> exportStatementPdf(
            @RequestParam String walletId,
            @RequestParam(required = false) Instant fromDate,
            @RequestParam(required = false) Instant toDate) {
        byte[] pdfData = transactionQueryUseCase.exportStatementPdf(walletId, fromDate, toDate);
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=statement_" + walletId + ".pdf")
                .contentType(MediaType.APPLICATION_PDF)
                .body(pdfData);
    }

    @GetMapping("/export/excel")
    public ResponseEntity<byte[]> exportStatementExcel(
            @RequestParam String walletId,
            @RequestParam(required = false) Instant fromDate,
            @RequestParam(required = false) Instant toDate) {
        byte[] excelData = transactionQueryUseCase.exportStatementExcel(walletId, fromDate, toDate);
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=statement_" + walletId + ".xlsx")
                .contentType(MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"))
                .body(excelData);
    }

    private String getFullName(com.fintech.wallet.domain.model.User user) {
        if (user == null) return "Unknown";
        if (user.getFullName() != null && !user.getFullName().isBlank()) {
            return user.getFullName();
        }
        com.fintech.wallet.domain.model.UserKyc kyc = userService.getKycStatus(user.getId());
        if (kyc != null && kyc.getFullName() != null) {
            return kyc.getFullName();
        }
        com.fintech.wallet.domain.model.UserProfile profile = userProfileUseCase.getProfile(user.getId());
        if (profile != null && profile.getFullName() != null && !profile.getFullName().startsWith("User ")) {
            return profile.getFullName();
        }
        return user.getPhoneNumber();
    }
}

