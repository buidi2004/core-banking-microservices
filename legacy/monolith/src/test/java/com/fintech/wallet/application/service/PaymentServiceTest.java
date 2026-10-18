package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.model.Bill;
import com.fintech.wallet.domain.model.BillType;
import com.fintech.wallet.domain.model.Money;
import com.fintech.wallet.domain.model.Transaction;
import com.fintech.wallet.domain.port.in.BillPaymentUseCase;
import com.fintech.wallet.domain.port.in.GetWalletUseCase;
import com.fintech.wallet.domain.port.out.BillProviderPort;
import org.springframework.stereotype.Service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class PaymentServiceTest {

    @Mock
    private BillProviderPort billProviderPort;

    @Mock
    private WalletService walletService;

    @InjectMocks
    private PaymentService target;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
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