package com.fintech.wallet.presentation.controller;

import com.fintech.wallet.domain.model.Merchant;
import com.fintech.wallet.domain.model.MerchantOrder;
import com.fintech.wallet.domain.model.Transaction;
import com.fintech.wallet.domain.port.in.MerchantUseCase;
import com.fintech.wallet.presentation.response.ApiResponse;
import com.fintech.wallet.presentation.response.TransferResponse;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import java.math.BigDecimal;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.http.ResponseEntity;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class MerchantControllerTest {

    @Mock
    private MerchantUseCase merchantUseCase;

    @InjectMocks
    private MerchantController target;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
    }

}