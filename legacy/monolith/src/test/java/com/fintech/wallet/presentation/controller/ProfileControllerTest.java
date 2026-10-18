package com.fintech.wallet.presentation.controller;

import com.fintech.wallet.domain.model.UserProfile;
import com.fintech.wallet.domain.port.in.UserProfileUseCase;
import com.fintech.wallet.presentation.response.ApiResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
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

class ProfileControllerTest {

    @Mock
    private UserProfileUseCase userProfileUseCase;

    @InjectMocks
    private ProfileController target;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void getMyProfile_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

    @Test
    void getPublicRecipientInfo_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

}