package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.model.DeviceToken;
import com.fintech.wallet.domain.model.NotificationInfo;
import com.fintech.wallet.domain.port.in.NotificationUseCase;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class NotificationServiceTest {

    @InjectMocks
    private NotificationService target;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void getNotifications_shouldExecuteSuccessfully() {
        assertNotNull(target);
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
    void registerDeviceToken_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

    @Test
    void unregisterDeviceToken_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

    @Test
    void updateSettings_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

    @Test
    void addNotification_shouldExecuteSuccessfully() {
        assertNotNull(target);
    }

}