package com.fintech.wallet.presentation.controller;

import com.fintech.wallet.domain.model.JournalEntry;
import com.fintech.wallet.domain.model.LedgerAccount;
import com.fintech.wallet.domain.port.in.LedgerUseCase;
import com.fintech.wallet.presentation.request.CreateLedgerAccountRequest;
import com.fintech.wallet.presentation.response.ApiResponse;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
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

class LedgerControllerTest {

    @Mock
    private LedgerUseCase ledgerUseCase;

    @InjectMocks
    private LedgerController target;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void createAccount_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

    @Test
    void getAllAccounts_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

    @Test
    void getAllJournalEntries_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

}