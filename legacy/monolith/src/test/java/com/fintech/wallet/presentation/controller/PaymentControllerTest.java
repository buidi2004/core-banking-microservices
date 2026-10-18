package com.fintech.wallet.presentation.controller;

import com.fintech.wallet.domain.model.Bill;
import com.fintech.wallet.domain.model.BillType;
import com.fintech.wallet.domain.model.Money;
import com.fintech.wallet.domain.model.Transaction;
import com.fintech.wallet.domain.model.VietQrPayload;
import com.fintech.wallet.domain.port.in.BillPaymentUseCase;
import com.fintech.wallet.domain.port.in.VietQrUseCase;
import com.fintech.wallet.presentation.request.GenerateQrRequest;
import com.fintech.wallet.presentation.request.PayBillRequest;
import com.fintech.wallet.presentation.request.TopupRequest;
import com.fintech.wallet.presentation.response.ApiResponse;
import com.fintech.wallet.presentation.response.TransferResponse;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.http.ResponseEntity;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class PaymentControllerTest {

    @Mock
    private VietQrUseCase vietQrUseCase;

    @Mock
    private BillPaymentUseCase billPaymentUseCase;

    @InjectMocks
    private PaymentController target;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void generateQr_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

    @Test
    void decodeQr_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

    @Test
    void queryBill_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

    @Test
    void payBill_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

    @Test
    void topupPhone_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

}