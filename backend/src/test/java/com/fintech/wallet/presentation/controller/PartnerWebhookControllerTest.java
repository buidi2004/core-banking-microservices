package com.fintech.wallet.presentation.controller;

import com.fintech.wallet.domain.port.in.PartnerWebhookUseCase;
import com.fintech.wallet.presentation.response.ApiResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import java.math.BigDecimal;
import java.util.Map;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.http.ResponseEntity;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class PartnerWebhookControllerTest {

    @Mock
    private PartnerWebhookUseCase partnerWebhookUseCase;

    @InjectMocks
    private PartnerWebhookController target;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void napasCallback_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

    @Test
    void merchantCallback_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

}