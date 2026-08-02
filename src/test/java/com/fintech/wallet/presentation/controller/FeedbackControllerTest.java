package com.fintech.wallet.presentation.controller;

import com.fintech.wallet.domain.model.AppFeedback;
import com.fintech.wallet.domain.port.in.FeedbackUseCase;
import com.fintech.wallet.presentation.response.ApiResponse;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.PostMapping;
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

class FeedbackControllerTest {

    @Mock
    private FeedbackUseCase feedbackUseCase;

    @InjectMocks
    private FeedbackController target;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
    }

}