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

    public TransactionQueryController(TransactionQueryUseCase transactionQueryUseCase) {
        this.transactionQueryUseCase = transactionQueryUseCase;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<TransferResponse>>> getHistory(
            @RequestParam String walletId,
            @RequestParam(required = false) TransactionType type,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        List<Transaction> transactions = transactionQueryUseCase.getTransactionHistory(walletId, type, page, size);
        List<TransferResponse> response = transactions.stream()
                .map(TransferResponse::fromDomain)
                .collect(Collectors.toList());
        return ResponseEntity.ok(ApiResponse.success("Transaction history retrieved", response));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<TransferResponse>> getById(@PathVariable String id) {
        Transaction transaction = transactionQueryUseCase.getTransactionById(id);
        TransferResponse response = TransferResponse.fromDomain(transaction);
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
}

