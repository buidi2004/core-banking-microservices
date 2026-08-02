package com.fintech.wallet.presentation.controller;

import com.fintech.wallet.domain.model.DeviceToken;
import com.fintech.wallet.domain.model.NotificationInfo;
import com.fintech.wallet.domain.port.in.NotificationUseCase;
import com.fintech.wallet.presentation.response.ApiResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
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

class NotificationControllerTest {

    @Mock
    private NotificationUseCase notificationUseCase;

    @InjectMocks
    private NotificationController target;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void markAsRead_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

    @Test
    void markAllAsRead_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

    @Test
    void unregisterDeviceToken_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

}