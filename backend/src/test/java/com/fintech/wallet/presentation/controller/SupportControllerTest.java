package com.fintech.wallet.presentation.controller;

import com.fintech.wallet.domain.model.SupportTicket;
import com.fintech.wallet.domain.model.TicketMessage;
import com.fintech.wallet.domain.port.in.SupportUseCase;
import com.fintech.wallet.presentation.response.ApiResponse;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import java.util.List;
import java.util.Map;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.http.ResponseEntity;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class SupportControllerTest {

    @Mock
    private SupportUseCase supportUseCase;

    @InjectMocks
    private SupportController target;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void getTickets_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

    @Test
    void getTicketDetail_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

    @Test
    void getFaqs_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

}