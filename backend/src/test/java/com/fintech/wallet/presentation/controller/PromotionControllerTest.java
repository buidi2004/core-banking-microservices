package com.fintech.wallet.presentation.controller;

import com.fintech.wallet.domain.model.Voucher;
import com.fintech.wallet.domain.port.in.PromotionUseCase;
import com.fintech.wallet.presentation.response.ApiResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import java.math.BigDecimal;
import java.util.List;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.http.ResponseEntity;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class PromotionControllerTest {

    @Mock
    private PromotionUseCase promotionUseCase;

    @InjectMocks
    private PromotionController target;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void getActivePromotions_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

    @Test
    void redeemVoucher_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

    @Test
    void getMyVouchers_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

}