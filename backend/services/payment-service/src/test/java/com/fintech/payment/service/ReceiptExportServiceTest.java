package com.fintech.payment.service;

import com.fintech.payment.domain.entity.Transaction;
import com.fintech.payment.repository.TransactionRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ReceiptExportServiceTest {

    @Mock
    private TransactionRepository transactionRepository;

    private ReceiptExportService receiptExportService;

    private final String txId = UUID.randomUUID().toString();
    private final String walletId = UUID.randomUUID().toString();

    @BeforeEach
    void setUp() {
        receiptExportService = new ReceiptExportService(transactionRepository);
    }

    @Test
    @DisplayName("generateReceiptPdf: Xuất biên lai điện tử ngân hàng chuẩn PDF")
    void generateReceiptPdf_ReturnsValidPdfBytes() {
        Transaction tx = Transaction.builder()
                .id(txId)
                .transactionCode("TX-20261021-001")
                .sourceWalletId(walletId)
                .targetWalletId("wallet-target-002")
                .type("TRANSFER")
                .amount(500000L)
                .fee(0L)
                .currency("VND")
                .status("SUCCESS")
                .note("Chuyển tiền mua quà sinh nhật")
                .createdAt(Instant.now())
                .build();

        when(transactionRepository.findById(txId)).thenReturn(Optional.of(tx));

        byte[] pdfBytes = receiptExportService.generateReceiptPdf(txId);

        assertThat(pdfBytes).isNotEmpty();
        // PDF header magic bytes %PDF-
        assertThat(new String(pdfBytes, 0, 5)).isEqualTo("%PDF-");
    }

    @Test
    @DisplayName("exportTransactionsCsv: Xuất sao kê định dạng CSV chuẩn UTF-8 BOM cho Excel")
    void exportTransactionsCsv_ReturnsCsvBytes() {
        Transaction tx = Transaction.builder()
                .id(txId)
                .transactionCode("TX-001")
                .sourceWalletId(walletId)
                .targetWalletId("wallet-002")
                .type("TRANSFER")
                .amount(200000L)
                .fee(0L)
                .currency("VND")
                .status("SUCCESS")
                .note("Tiền ăn trưa")
                .createdAt(Instant.now())
                .build();

        when(transactionRepository.findWalletHistory(eq(walletId), any(), any(Pageable.class)))
                .thenReturn(new PageImpl<>(List.of(tx)));

        byte[] csvBytes = receiptExportService.exportTransactions(walletId, "csv");

        assertThat(csvBytes).isNotEmpty();
        String content = new String(csvBytes);
        assertThat(content).contains("Mã giao dịch");
        assertThat(content).contains("TX-001");
        assertThat(content).contains("200000");
    }

    @Test
    @DisplayName("exportTransactionsPdf: Xuất sao kê tài khoản định dạng PDF chuẩn Core Banking")
    void exportTransactionsPdf_ReturnsPdfBytes() {
        Transaction tx = Transaction.builder()
                .id(txId)
                .transactionCode("TX-002")
                .sourceWalletId(walletId)
                .targetWalletId("wallet-002")
                .type("TRANSFER")
                .amount(150000L)
                .fee(0L)
                .currency("VND")
                .status("SUCCESS")
                .note("Thanh toán tiền điện")
                .createdAt(Instant.now())
                .build();

        when(transactionRepository.findWalletHistory(eq(walletId), any(), any(Pageable.class)))
                .thenReturn(new PageImpl<>(List.of(tx)));

        byte[] pdfBytes = receiptExportService.exportTransactions(walletId, "pdf");

        assertThat(pdfBytes).isNotEmpty();
        assertThat(new String(pdfBytes, 0, 5)).isEqualTo("%PDF-");
    }
}

