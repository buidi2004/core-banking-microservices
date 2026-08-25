package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.model.NotificationInfo;
import com.fintech.wallet.domain.model.NotificationType;
import com.fintech.wallet.domain.port.out.NotificationQueryPort;
import com.fintech.wallet.presentation.response.PageResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

class NotificationServiceTest {

    @Mock
    private NotificationQueryPort notificationQueryPort;

    @InjectMocks
    private NotificationService target;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void getNotifications_shouldReturnPageResponse() {
        // Arrange
        String userId = "user123";
        String type = "BALANCE";
        int page = 0;
        int size = 10;
        NotificationInfo info = NotificationInfo.createNew(userId, "Title", "Body", NotificationType.BALANCE, null);
        PageResponse<NotificationInfo> mockResponse = PageResponse.of(List.of(info), page, size, 1);
        when(notificationQueryPort.getNotifications(userId, type, page, size)).thenReturn(mockResponse);

        // Act
        PageResponse<NotificationInfo> result = target.getNotifications(userId, type, page, size);

        // Assert
        assertNotNull(result);
        assertEquals(1, result.getTotalElements());
        assertEquals("Title", result.getContent().get(0).getTitle());
        verify(notificationQueryPort, times(1)).getNotifications(userId, type, page, size);
    }

    @Test
    void markAsRead_shouldCallPort() {
        String userId = "user123";
        String notificationId = "notif123";

        target.markAsRead(userId, notificationId);

        verify(notificationQueryPort, times(1)).markAsRead(userId, notificationId);
    }

    @Test
    void markAllAsRead_shouldCallPort() {
        String userId = "user123";
        String type = "PROMOTION";

        target.markAllAsRead(userId, type);

        verify(notificationQueryPort, times(1)).markAllAsRead(userId, type);
    }

    @Test
    void addNotification_shouldSaveToPort() {
        String userId = "user123";
        String title = "Promo";
        String content = "Free Money";
        String type = "PROMOTION";

        target.addNotification(userId, title, content, type);

        verify(notificationQueryPort, times(1)).saveNotification(argThat(n -> 
            n.getUserId().equals(userId) &&
            n.getTitle().equals(title) &&
            n.getType() == NotificationType.PROMOTION
        ));
    }

    @Test
    void addNotification_withInvalidType_shouldDefaultToSystem() {
        String userId = "user123";

        target.addNotification(userId, "T", "C", "INVALID_TYPE");

        verify(notificationQueryPort, times(1)).saveNotification(argThat(n -> 
            n.getType() == NotificationType.SYSTEM
        ));
    }
}