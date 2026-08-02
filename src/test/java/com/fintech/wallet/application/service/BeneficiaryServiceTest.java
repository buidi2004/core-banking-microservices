package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.model.Beneficiary;
import com.fintech.wallet.domain.port.in.BeneficiaryUseCase;
import com.fintech.wallet.domain.port.out.BeneficiaryPersistencePort;
import org.springframework.stereotype.Service;
import java.util.List;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class BeneficiaryServiceTest {

    @Mock
    private BeneficiaryPersistencePort beneficiaryPersistencePort;

    @InjectMocks
    private BeneficiaryService target;

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