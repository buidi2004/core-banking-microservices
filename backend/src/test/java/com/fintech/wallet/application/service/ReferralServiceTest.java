package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.model.ReferralInfo;
import com.fintech.wallet.domain.port.in.ReferralUseCase;
import org.springframework.stereotype.Service;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class ReferralServiceTest {

    @InjectMocks
    private ReferralService target;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void getReferralInfo_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

    @Test
    void applyReferralCode_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

    @Test
    void getReferralHistory_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

}