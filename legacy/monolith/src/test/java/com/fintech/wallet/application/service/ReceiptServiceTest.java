package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.model.Money;
import com.fintech.wallet.domain.model.Transaction;
import com.fintech.wallet.domain.model.TransactionStatus;
import com.fintech.wallet.domain.model.TransactionType;
import com.fintech.wallet.domain.model.Wallet;
import com.fintech.wallet.domain.port.in.GetWalletUseCase;
import com.fintech.wallet.domain.port.out.TransactionPersistencePort;
import com.fintech.wallet.presentation.response.RecipientInfoResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
public class ReceiptServiceTest {

    @Mock
    private TransactionPersistencePort transactionPersistencePort;

    @Mock
    private GetWalletUseCase getWalletUseCase;

    @InjectMocks
    private ReceiptService receiptService;

    private Transaction transferTx;
    private Wallet sourceWallet;
    private Wallet targetWallet;

    @BeforeEach
    void setUp() {
        transferTx = new Transaction(
                "tx-123",
                "req-1",
                "wallet-1",
                "wallet-2",
                new Money(new BigDecimal("100000"), "VND"),
                TransactionType.TRANSFER,
                TransactionStatus.SUCCESS,
                Instant.now()
        );

        sourceWallet = new Wallet("wallet-1", "user-1", new Money(new BigDecimal("500000"), "VND"), Instant.now(), Instant.now(), 1L);
        targetWallet = new Wallet("wallet-2", "user-2", new Money(new BigDecimal("200000"), "VND"), Instant.now(), Instant.now(), 1L);
    }

    @Test
    void testGenerateReceiptPdf_Success_SourceOwner() {
        when(transactionPersistencePort.findTransactionById("tx-123")).thenReturn(Optional.of(transferTx));
        when(getWalletUseCase.getWalletById("wallet-1")).thenReturn(sourceWallet);
        when(getWalletUseCase.getWalletById("wallet-2")).thenReturn(targetWallet);

        when(getWalletUseCase.getRecipientInfo("wallet-1", null))
                .thenReturn(new RecipientInfoResponse("wallet-1", "0901234567", "NGUYEN V** A"));
        when(getWalletUseCase.getRecipientInfo("wallet-2", null))
                .thenReturn(new RecipientInfoResponse("wallet-2", "0987654321", "TRAN T** B"));

        byte[] pdfBytes = receiptService.generateReceiptPdf("tx-123", "user-1");
        
        assertNotNull(pdfBytes);
        assertTrue(pdfBytes.length > 0);
        // PDF magic number check %PDF-
        assertEquals("%PDF-", new String(pdfBytes, 0, 5));
    }

    @Test
    void testGenerateReceiptPdf_Success_TargetOwner() {
        when(transactionPersistencePort.findTransactionById("tx-123")).thenReturn(Optional.of(transferTx));
        when(getWalletUseCase.getWalletById("wallet-1")).thenReturn(sourceWallet);
        when(getWalletUseCase.getWalletById("wallet-2")).thenReturn(targetWallet);

        when(getWalletUseCase.getRecipientInfo("wallet-1", null))
                .thenReturn(new RecipientInfoResponse("wallet-1", "0901234567", "NGUYEN V** A"));
        when(getWalletUseCase.getRecipientInfo("wallet-2", null))
                .thenReturn(new RecipientInfoResponse("wallet-2", "0987654321", "TRAN T** B"));

        byte[] pdfBytes = receiptService.generateReceiptPdf("tx-123", "user-2");
        
        assertNotNull(pdfBytes);
        assertTrue(pdfBytes.length > 0);
    }

    @Test
    void testGenerateReceiptPdf_Unauthorized_ThrowsException() {
        when(transactionPersistencePort.findTransactionById("tx-123")).thenReturn(Optional.of(transferTx));
        when(getWalletUseCase.getWalletById("wallet-1")).thenReturn(sourceWallet);
        when(getWalletUseCase.getWalletById("wallet-2")).thenReturn(targetWallet);

        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, () -> {
            receiptService.generateReceiptPdf("tx-123", "user-3");
        });

        assertEquals("Unauthorized to view this receipt", ex.getMessage());
    }

    @Test
    void testGenerateReceiptPdf_TransactionNotFound() {
        when(transactionPersistencePort.findTransactionById("tx-999")).thenReturn(Optional.empty());

        assertThrows(IllegalArgumentException.class, () -> {
            receiptService.generateReceiptPdf("tx-999", "user-1");
        });
    }
}
