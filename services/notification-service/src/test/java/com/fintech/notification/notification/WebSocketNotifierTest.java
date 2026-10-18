package com.fintech.notification.notification;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.messaging.simp.SimpMessagingTemplate;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

@ExtendWith(MockitoExtension.class)
class WebSocketNotifierTest {

    @Mock
    private SimpMessagingTemplate messagingTemplate;

    @InjectMocks
    private WebSocketNotifier webSocketNotifier;

    private NotificationPayload payload() {
        return new NotificationPayload("tx-1", "tx-1", "TRANSFER_OUT", "SUCCESS", "wallet-A",
                BigDecimal.valueOf(150000), "VND", BigDecimal.valueOf(850000), "VND",
                "2026-10-18T05:00:00Z", "note", "title", "body");
    }

    @Test
    void pushesToWalletTopic() {
        webSocketNotifier.pushToWallet("wallet-A", payload());

        ArgumentCaptor<String> destination = ArgumentCaptor.forClass(String.class);
        verify(messagingTemplate).convertAndSend(destination.capture(), any(NotificationPayload.class));
        assertThat(destination.getValue()).isEqualTo("/topic/wallets/wallet-A/notifications");
    }

    @Test
    void pushesToUserTopic() {
        webSocketNotifier.pushToUser("user-001", payload());

        ArgumentCaptor<String> destination = ArgumentCaptor.forClass(String.class);
        verify(messagingTemplate).convertAndSend(destination.capture(), any(NotificationPayload.class));
        assertThat(destination.getValue()).isEqualTo("/topic/users/user-001/notifications");
    }

    @Test
    void skipsBlankWalletDestination() {
        webSocketNotifier.pushToWallet(null, payload());
        webSocketNotifier.pushToWallet("  ", payload());

        verify(messagingTemplate, never()).convertAndSend(any(String.class), any(NotificationPayload.class));
    }

    @Test
    void skipsBlankUserDestination() {
        webSocketNotifier.pushToUser(null, payload());
        webSocketNotifier.pushToUser("", payload());

        verify(messagingTemplate, never()).convertAndSend(any(String.class), any(NotificationPayload.class));
    }

    @Test
    void payloadIsForwardedUnchanged() {
        NotificationPayload payload = payload();
        webSocketNotifier.pushToUser("user-001", payload);

        verify(messagingTemplate).convertAndSend(eq("/topic/users/user-001/notifications"), eq(payload));
    }
}
