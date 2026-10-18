package com.fintech.notification.notification;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Component;

@Component
public class WebSocketNotifier {

    private static final Logger log = LoggerFactory.getLogger(WebSocketNotifier.class);

    private static final String WALLET_TOPIC = "/topic/wallets/%s/notifications";
    private static final String USER_TOPIC = "/topic/users/%s/notifications";

    private final SimpMessagingTemplate messagingTemplate;

    public WebSocketNotifier(SimpMessagingTemplate messagingTemplate) {
        this.messagingTemplate = messagingTemplate;
    }

    public void pushToWallet(String walletId, NotificationPayload payload) {
        if (walletId == null || walletId.isBlank()) {
            return;
        }
        String destination = String.format(WALLET_TOPIC, walletId);
        send(destination, payload);
    }

    public void pushToUser(String userId, NotificationPayload payload) {
        if (userId == null || userId.isBlank()) {
            return;
        }
        String destination = String.format(USER_TOPIC, userId);
        send(destination, payload);
    }

    private void send(String destination, NotificationPayload payload) {
        try {
            messagingTemplate.convertAndSend(destination, payload);
            log.info("Pushed WebSocket notification to {}", destination);
            log.debug("WebSocket payload: {}", payload);
        } catch (Exception e) {
            log.error("Failed to send WebSocket notification to {}", destination, e);
        }
    }
}
