package com.fintech.wallet.presentation.controller;

import com.fintech.wallet.domain.model.Beneficiary;
import com.fintech.wallet.domain.port.in.BeneficiaryUseCase;
import com.fintech.wallet.presentation.request.AddBeneficiaryRequest;
import com.fintech.wallet.presentation.response.ApiResponse;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
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

class BeneficiaryControllerTest {

    @Mock
    private BeneficiaryUseCase beneficiaryUseCase;

    @InjectMocks
    private BeneficiaryController target;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void addBeneficiary_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

    @Test
    void getBeneficiaries_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

    @Test
    void deleteBeneficiary_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

}