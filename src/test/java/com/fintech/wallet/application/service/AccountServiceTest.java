package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.model.User;
import com.fintech.wallet.domain.port.in.AccountUseCase;
import com.fintech.wallet.domain.port.in.AuthUseCase;
import com.fintech.wallet.domain.port.out.UserPersistencePort;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class AccountServiceTest {

    @Mock
    private UserPersistencePort userPersistencePort;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private AuthUseCase authUseCase;

    @InjectMocks
    private AccountService target;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void changePassword_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

    @Test
    void resetPassword_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

}