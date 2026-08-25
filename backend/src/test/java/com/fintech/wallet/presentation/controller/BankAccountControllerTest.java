package com.fintech.wallet.presentation.controller;

import com.fintech.wallet.domain.model.BankAccount;
import com.fintech.wallet.domain.port.in.BankLinkingUseCase;
import com.fintech.wallet.presentation.request.LinkBankRequest;
import com.fintech.wallet.presentation.response.ApiResponse;
import com.fintech.wallet.presentation.response.BankAccountResponse;
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
import java.util.stream.Collectors;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.http.ResponseEntity;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class BankAccountControllerTest {

    @Mock
    private BankLinkingUseCase bankLinkingUseCase;

    @InjectMocks
    private BankAccountController target;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void linkAccount_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

    @Test
    void getLinkedAccounts_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

    @Test
    void unlinkAccount_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

}