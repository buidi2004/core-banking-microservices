package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.model.BankAccount;
import com.fintech.wallet.domain.port.in.BankLinkingUseCase;
import com.fintech.wallet.domain.port.out.BankAccountPersistencePort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class BankServiceTest {

    @Mock
    private BankAccountPersistencePort bankAccountPersistencePort;

    @InjectMocks
    private BankService target;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void linkBankAccount_shouldExecuteSuccessfully() {
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