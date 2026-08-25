package com.fintech.wallet.presentation.controller;

import com.fintech.wallet.application.service.OtpService;
import com.fintech.wallet.application.service.UserService;
import com.fintech.wallet.domain.model.Money;
import com.fintech.wallet.domain.model.Transaction;
import com.fintech.wallet.domain.model.TransactionStatus;
import com.fintech.wallet.domain.model.TransactionType;
import com.fintech.wallet.domain.model.VietQrPayload;
import com.fintech.wallet.domain.model.Wallet;
import com.fintech.wallet.domain.port.in.DepositMoneyUseCase;
import com.fintech.wallet.domain.port.in.FeeEstimationUseCase;
import com.fintech.wallet.domain.port.in.GetWalletUseCase;
import com.fintech.wallet.domain.port.in.PinUseCase;
import com.fintech.wallet.domain.port.in.TransactionQueryUseCase;
import com.fintech.wallet.domain.port.in.TransactionReversalUseCase;
import com.fintech.wallet.domain.port.in.TransferMoneyUseCase;
import com.fintech.wallet.domain.port.in.VietQrUseCase;
import com.fintech.wallet.domain.port.in.WithdrawMoneyUseCase;
import com.fintech.wallet.presentation.request.TransferQrRequest;
import com.fintech.wallet.presentation.response.ApiResponse;
import com.fintech.wallet.presentation.response.TransferResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;

import java.math.BigDecimal;
import java.time.Instant;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

class WalletControllerQrTest {

    @Mock
    private GetWalletUseCase getWalletUseCase;
    @Mock
    private DepositMoneyUseCase depositMoneyUseCase;
    @Mock
    private TransferMoneyUseCase transferMoneyUseCase;
    @Mock
    private WithdrawMoneyUseCase withdrawMoneyUseCase;
    @Mock
    private PinUseCase pinUseCase;
    @Mock
    private FeeEstimationUseCase feeEstimationUseCase;
    @Mock
    private TransactionReversalUseCase transactionReversalUseCase;
    @Mock
    private OtpService otpService;
    @Mock
    private UserService userService;
    @Mock
    private VietQrUseCase vietQrUseCase;
    @Mock
    private TransactionQueryUseCase transactionQueryUseCase;
    @Mock
    private Authentication auth;

    @InjectMocks
    private WalletController walletController;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
        when(auth.getName()).thenReturn("user-1");
        // Mock ownership check: source wallet belongs to authenticated user
        Wallet sourceWallet = Wallet.createNew("user-1", "VND");
        when(getWalletUseCase.getWalletById("wallet-source")).thenReturn(sourceWallet);
    }

    @Test
    void initTransferQr_shouldParseQrAndInitTransfer() {
        TransferQrRequest request = new TransferQrRequest();
        request.setSourceWalletId("wallet-source");
        request.setQrCode("FAKE_QR_STRING");
        request.setCurrency("VND");
        
        VietQrPayload mockPayload = new VietQrPayload("970415", "wallet-target", new BigDecimal("50000"), "Tra tien", "FAKE_QR_STRING");
        when(vietQrUseCase.decodeQr(request.getQrCode())).thenReturn(mockPayload);
        
        Transaction mockTx = new Transaction(
            "tx-123", "req-1", "wallet-source", "wallet-target", 
            Money.of(new BigDecimal("50000"), "VND"), 
            TransactionType.TRANSFER, 
            TransactionStatus.PENDING_CONFIRMATION, 
            Instant.now()
        );
        when(transferMoneyUseCase.initTransfer(any(), eq("wallet-source"), eq("wallet-target"), any(Money.class))).thenReturn(mockTx);
        
        ResponseEntity<ApiResponse<TransferResponse>> response = walletController.initTransferQr(auth, request);
        
        assertEquals(200, response.getStatusCode().value());
        assertNotNull(response.getBody());
        assertEquals("QR Transfer initiated. Please confirm with OTP/PIN.", response.getBody().getMessage());
        
        TransferResponse txResponse = response.getBody().getData();
        assertEquals("tx-123", txResponse.getTransactionId());
        assertEquals("PENDING_CONFIRMATION", txResponse.getStatus());
        
        verify(otpService).generateAndStoreOtp("tx-123");
        verify(transferMoneyUseCase).initTransfer(any(), eq("wallet-source"), eq("wallet-target"), eq(Money.of(new BigDecimal("50000"), "VND")));
    }

    @Test
    void initTransferQr_whenAmountNotInQr_shouldUseAmountFromRequest() {
        TransferQrRequest request = new TransferQrRequest();
        request.setSourceWalletId("wallet-source");
        request.setQrCode("FAKE_QR_STRING");
        request.setAmount(new BigDecimal("100000")); // Amount explicitly provided by user
        request.setCurrency("VND");
        
        // Payload without amount
        VietQrPayload mockPayload = new VietQrPayload("970415", "wallet-target", null, "Tra tien", "FAKE_QR_STRING");
        when(vietQrUseCase.decodeQr(request.getQrCode())).thenReturn(mockPayload);
        
        Transaction mockTx = new Transaction(
            "tx-123", "req-1", "wallet-source", "wallet-target", 
            Money.of(new BigDecimal("100000"), "VND"), 
            TransactionType.TRANSFER, 
            TransactionStatus.PENDING_CONFIRMATION, 
            Instant.now()
        );
        when(transferMoneyUseCase.initTransfer(any(), eq("wallet-source"), eq("wallet-target"), any(Money.class))).thenReturn(mockTx);
        
        ResponseEntity<ApiResponse<TransferResponse>> response = walletController.initTransferQr(auth, request);
        
        assertEquals(200, response.getStatusCode().value());
        
        verify(transferMoneyUseCase).initTransfer(any(), eq("wallet-source"), eq("wallet-target"), eq(Money.of(new BigDecimal("100000"), "VND")));
    }

    @Test
    void initTransferQr_withoutAmount_shouldThrowException() {
        TransferQrRequest request = new TransferQrRequest();
        request.setSourceWalletId("wallet-source");
        request.setQrCode("FAKE_QR_STRING");
        
        VietQrPayload mockPayload = new VietQrPayload("970415", "wallet-target", null, "Tra tien", "FAKE_QR_STRING");
        when(vietQrUseCase.decodeQr(request.getQrCode())).thenReturn(mockPayload);
        
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, () -> walletController.initTransferQr(auth, request));
        assertTrue(ex.getMessage().contains("Amount must be specified"));
    }
}
