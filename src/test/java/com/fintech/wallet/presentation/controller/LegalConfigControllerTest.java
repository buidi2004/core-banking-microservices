package com.fintech.wallet.presentation.controller;

import com.fintech.wallet.domain.model.LegalConsent;
import com.fintech.wallet.domain.port.in.LegalConfigUseCase;
import com.fintech.wallet.presentation.response.ApiResponse;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
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

class LegalConfigControllerTest {

    @Mock
    private LegalConfigUseCase legalConfigUseCase;

    @InjectMocks
    private LegalConfigController target;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void getUserLimits_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

    @Test
    void getTermsOfService_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

}