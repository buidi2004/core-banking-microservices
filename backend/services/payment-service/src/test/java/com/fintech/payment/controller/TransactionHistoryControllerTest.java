package com.fintech.payment.controller;

import com.fintech.payment.domain.entity.Transaction;
import com.fintech.payment.dto.ApiResponse;
import com.fintech.payment.repository.TransactionRepository;
import com.fintech.payment.service.ReceiptExportService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.ResponseEntity;

import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class TransactionHistoryControllerTest {

    @Mock
    private TransactionRepository transactionRepository;

    @Mock
    private ReceiptExportService receiptExportService;

    @InjectMocks
    private TransactionHistoryController controller;

    private Transaction normalTransfer;
    private Transaction reversedTransfer;

    @BeforeEach
    void setUp() {
        normalTransfer = Transaction.builder()
                .id("tx-normal-1")
                .transactionCode("TXC-1001")
                .sourceWalletId("wallet-source")
                .targetWalletId("wallet-target")
                .type("TRANSFER")
                .status("SUCCESS")
                .amount(500_000L)
                .fee(0L)
                .sourceBalanceAfter(4_500_000L)
                .targetBalanceAfter(500_000L)
                .build();

        reversedTransfer = Transaction.builder()
                .id("tx-reversed-2")
                .transactionCode("TXC-1002")
                .sourceWalletId("wallet-source")
                .targetWalletId("wallet-target")
                .type("TRANSFER")
                .status("REVERSED")
                .amount(200_000L)
                .fee(0L)
                .sourceBalanceAfter(5_000_000L) // Hoàn tiền lại ví nguồn
                .targetBalanceAfter(0L)          // Ví đích không nhận tiền
                .build();
    }

    @Test
    @DisplayName("B-02: Ví nguồn thấy giao dịch REVERSED dưới dạng TRANSFER_IN (hoàn tiền dương)")
    void reversedTransaction_FromSourcePerspective_ShouldBeTransferIn() {
        when(transactionRepository.findById("tx-reversed-2")).thenReturn(Optional.of(reversedTransfer));

        ResponseEntity<ApiResponse<Map<String, Object>>> response =
                controller.detail("tx-reversed-2", "wallet-source");

        assertThat(response.getStatusCode().is2xxSuccessful()).isTrue();
        Map<String, Object> data = response.getBody().getData();
        assertThat(data.get("type")).isEqualTo("TRANSFER_IN");
        assertThat(data.get("status")).isEqualTo("REVERSED");
        assertThat(data.get("runningBalance")).isEqualTo(5_000_000L);
        assertThat(data.get("counterpartyWalletId")).isEqualTo("wallet-target");
    }

    @Test
    @DisplayName("B-03: Ví đích thấy giao dịch REVERSED là REVERSED, không credit ảo (runningBalance null)")
    void reversedTransaction_FromTargetPerspective_ShouldNotBeCredit() {
        when(transactionRepository.findById("tx-reversed-2")).thenReturn(Optional.of(reversedTransfer));

        ResponseEntity<ApiResponse<Map<String, Object>>> response =
                controller.detail("tx-reversed-2", "wallet-target");

        assertThat(response.getStatusCode().is2xxSuccessful()).isTrue();
        Map<String, Object> data = response.getBody().getData();
        assertThat(data.get("type")).isEqualTo("REVERSED");
        assertThat(data.get("status")).isEqualTo("REVERSED");
        assertThat(data.get("runningBalance")).isNull();
        assertThat(data.get("counterpartyWalletId")).isEqualTo("wallet-source");
    }

    @Test
    @DisplayName("Giao dịch bình thường SUCCESS: Ví nguồn là TRANSFER_OUT, Ví đích là TRANSFER_IN")
    void normalTransfer_ShouldDifferentiateSourceAndTarget() {
        when(transactionRepository.findById("tx-normal-1")).thenReturn(Optional.of(normalTransfer));

        // Source
        Map<String, Object> sourceView = controller.detail("tx-normal-1", "wallet-source").getBody().getData();
        assertThat(sourceView.get("type")).isEqualTo("TRANSFER_OUT");
        assertThat(sourceView.get("runningBalance")).isEqualTo(4_500_000L);

        // Target
        Map<String, Object> targetView = controller.detail("tx-normal-1", "wallet-target").getBody().getData();
        assertThat(targetView.get("type")).isEqualTo("TRANSFER_IN");
        assertThat(targetView.get("runningBalance")).isEqualTo(500_000L);
    }

    @Test
    @DisplayName("Danh sách giao dịch phân trang phản ánh đúng góc nhìn ví")
    void listTransactions_ShouldReflectPerspective() {
        when(transactionRepository.findWalletHistory(eq("wallet-source"), eq(""), any(PageRequest.class)))
                .thenReturn(new PageImpl<>(List.of(reversedTransfer, normalTransfer)));

        ResponseEntity<ApiResponse<Map<String, Object>>> response =
                controller.list("wallet-source", null, 0, 10);

        assertThat(response.getStatusCode().is2xxSuccessful()).isTrue();
        List<Map<String, Object>> content = (List<Map<String, Object>>) response.getBody().getData().get("content");
        assertThat(content).hasSize(2);
        assertThat(content.get(0).get("type")).isEqualTo("TRANSFER_IN"); // Reversed hoàn tiền
        assertThat(content.get(1).get("type")).isEqualTo("TRANSFER_OUT"); // Normal chuyển đi
    }

    @Test
    @DisplayName("GET /{id}/receipt.pdf: Trả về file biên lai định dạng PDF")
    void getReceiptPdf_Success() {
        byte[] pdfBytes = "%PDF-1.4 test receipt".getBytes();
        when(receiptExportService.generateReceiptPdf("tx-normal-1")).thenReturn(pdfBytes);

        ResponseEntity<byte[]> response = controller.getReceiptPdf("tx-normal-1");

        assertThat(response.getStatusCode().is2xxSuccessful()).isTrue();
        assertThat(response.getBody()).isEqualTo(pdfBytes);
        assertThat(response.getHeaders().getFirst("Content-Disposition")).contains("receipt-tx-normal-1.pdf");
    }

    @Test
    @DisplayName("GET /export/{format}: Xuất sao kê tài khoản định dạng CSV")
    void exportTransactions_Csv_Success() {
        byte[] csvBytes = "Mã giao dịch,Thời gian,Số tiền\nTXC-1001,2026-10-21,500000".getBytes();
        when(receiptExportService.exportTransactions("wallet-source", "csv")).thenReturn(csvBytes);

        ResponseEntity<byte[]> response = controller.exportTransactions("csv", "wallet-source");

        assertThat(response.getStatusCode().is2xxSuccessful()).isTrue();
        assertThat(response.getBody()).isEqualTo(csvBytes);
        assertThat(response.getHeaders().getFirst("Content-Disposition")).contains("statement-wallet-source.csv");
    }
}
