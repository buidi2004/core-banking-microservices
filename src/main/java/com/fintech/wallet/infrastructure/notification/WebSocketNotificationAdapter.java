package com.fintech.wallet.infrastructure.notification;

import com.fintech.wallet.domain.model.Transaction;
import com.fintech.wallet.domain.model.Wallet;
import com.fintech.wallet.domain.port.out.NotificationPort;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Component;

/**
 * Infrastructure Adapter: WebSocketNotificationAdapter
 * Implements domain.port.out.NotificationPort.
 * Pushes real-time transaction & balance updates to WebSocket topics for client apps (React Native).
 *
 * Fixes applied:
 * - OPT #4: Uses type-safe NotificationPayload DTO instead of raw HashMap
 * - OPT #5: Payload details logged at DEBUG level to avoid exposing sensitive financial data in production logs
 */
@Component
public class WebSocketNotificationAdapter implements NotificationPort {

    private static final Logger log = LoggerFactory.getLogger(WebSocketNotificationAdapter.class);
    private final SimpMessagingTemplate messagingTemplate;

    public WebSocketNotificationAdapter(SimpMessagingTemplate messagingTemplate) {
        this.messagingTemplate = messagingTemplate;
    }

    @Override
    public void notifyTransactionCompleted(Transaction transaction, Wallet wallet) {
        if (wallet == null || wallet.getId() == null) {
            return;
        }

        String destination = "/topic/wallets/" + wallet.getId() + "/notifications";

        // OPT #4: Type-safe DTO instead of raw HashMap
        NotificationPayload payload = new NotificationPayload(
                transaction.getId(),
                transaction.getRequestId(),
                transaction.getType().name(),
                transaction.getStatus().name(),
                wallet.getId(),
                transaction.getAmount().getAmount(),
                transaction.getAmount().getCurrency(),
                wallet.getBalance().getAmount(),
                wallet.getBalance().getCurrency(),
                transaction.getCreatedAt().toString()
        );

        try {
            messagingTemplate.convertAndSend(destination, payload);
            // OPT #5: Only log destination at INFO; full payload at DEBUG to avoid leaking sensitive data
            log.info("Pushed transaction notification to {}", destination);
            log.debug("Notification payload: {}", payload);
        } catch (Exception e) {
            log.error("Failed to send WebSocket notification to {}", destination, e);
        }
    }
}
