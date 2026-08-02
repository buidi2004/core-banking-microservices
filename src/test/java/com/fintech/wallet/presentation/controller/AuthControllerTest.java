package com.fintech.wallet.presentation.controller;

import com.fintech.wallet.domain.model.User;
import com.fintech.wallet.domain.port.in.AuthUseCase;
import com.fintech.wallet.presentation.request.LoginRequest;
import com.fintech.wallet.presentation.request.RegisterRequest;
import com.fintech.wallet.presentation.response.ApiResponse;
import com.fintech.wallet.presentation.response.AuthResponse;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
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

class AuthControllerTest {

    @Mock
    private AuthUseCase authUseCase;

    @InjectMocks
    private AuthController target;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void register_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

    @Test
    void login_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

    @Test
    void sendOtp_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

    @Test
    void verifyOtp_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

    @Test
    void refreshToken_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

    @Test
    void forgotPassword_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

}