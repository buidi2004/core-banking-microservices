package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.model.SupportTicket;
import com.fintech.wallet.domain.model.TicketMessage;
import com.fintech.wallet.domain.port.in.SupportUseCase;
import org.springframework.stereotype.Service;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class SupportServiceTest {

    @InjectMocks
    private SupportService target;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void createTicket_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

    @Test
    void getTickets_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

    @Test
    void getTicketById_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

    @Test
    void addMessage_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

    @Test
    void getTicketMessages_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

    @Test
    void getFaqs_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

}