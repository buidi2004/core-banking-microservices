package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.model.Merchant;
import com.fintech.wallet.domain.model.MerchantOrder;
import com.fintech.wallet.domain.model.Money;
import com.fintech.wallet.domain.model.Transaction;
import com.fintech.wallet.domain.port.in.MerchantUseCase;
import com.fintech.wallet.domain.port.in.TransferMoneyUseCase;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class MerchantServiceTest {

    @Mock
    private TransferMoneyUseCase transferMoneyUseCase;

    @InjectMocks
    private MerchantService target;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void registerMerchant_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

    @Test
    void createPaymentRequest_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

    @Test
    void confirmMerchantPayment_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

}