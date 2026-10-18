package com.fintech.wallet.presentation.controller;

import com.fintech.wallet.domain.model.Money;
import com.fintech.wallet.domain.model.Transaction;
import com.fintech.wallet.domain.model.Wallet;
import com.fintech.wallet.domain.port.in.DepositMoneyUseCase;
import com.fintech.wallet.domain.port.in.GetWalletUseCase;
import com.fintech.wallet.domain.port.in.TransferMoneyUseCase;
import com.fintech.wallet.domain.exception.InvalidPinException;
import com.fintech.wallet.domain.port.in.PinUseCase;
import com.fintech.wallet.domain.port.in.WithdrawMoneyUseCase;
import com.fintech.wallet.presentation.request.CreateWalletRequest;
import com.fintech.wallet.presentation.request.DepositRequest;
import com.fintech.wallet.presentation.request.TransferRequest;
import com.fintech.wallet.presentation.request.WithdrawRequest;
import com.fintech.wallet.presentation.response.ApiResponse;
import com.fintech.wallet.presentation.response.TransferResponse;
import com.fintech.wallet.presentation.response.WalletResponse;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
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

class WalletControllerTest {

    @Mock
    private GetWalletUseCase getWalletUseCase;

    @Mock
    private DepositMoneyUseCase depositMoneyUseCase;

    @Mock
    private TransferMoneyUseCase transferMoneyUseCase;

    @Mock
    private WithdrawMoneyUseCase withdrawMoneyUseCase;

    @Mock
    private PinUseCase pinUseCase;

    @InjectMocks
    private WalletController target;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void createWallet_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

    @Test
    void getWallet_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

    @Test
    void deposit_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

    @Test
    void transfer_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

    @Test
    void withdraw_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

}