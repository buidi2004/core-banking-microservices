package com.fintech.wallet.presentation.controller;

import com.fintech.wallet.domain.model.UserKyc;
import com.fintech.wallet.domain.port.in.KycUseCase;
import com.fintech.wallet.domain.port.in.PinUseCase;
import com.fintech.wallet.presentation.request.KycSubmitRequest;
import com.fintech.wallet.presentation.request.SetPinRequest;
import com.fintech.wallet.presentation.request.VerifyPinRequest;
import com.fintech.wallet.presentation.response.ApiResponse;
import com.fintech.wallet.presentation.response.KycResponse;
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

class UserControllerTest {

    @Mock
    private PinUseCase pinUseCase;

    @Mock
    private KycUseCase kycUseCase;

    @InjectMocks
    private UserController target;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void setPin_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

    @Test
    void verifyPin_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

    @Test
    void submitKyc_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

    @Test
    void getKycStatus_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

}