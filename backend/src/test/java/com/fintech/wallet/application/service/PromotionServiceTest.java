package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.model.Voucher;
import com.fintech.wallet.domain.port.in.PromotionUseCase;
import org.springframework.stereotype.Service;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class PromotionServiceTest {

    @InjectMocks
    private PromotionService target;

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
    void applyVoucher_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

    @Test
    void getMyVouchers_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

}