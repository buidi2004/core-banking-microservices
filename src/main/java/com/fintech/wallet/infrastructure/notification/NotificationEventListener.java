package com.fintech.wallet.infrastructure.notification;

import com.fintech.wallet.domain.event.TransactionCompletedEvent;
import com.fintech.wallet.domain.model.Transaction;
import com.fintech.wallet.domain.model.Wallet;
import com.fintech.wallet.domain.port.out.NotificationPort;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;

@Component
public class NotificationEventListener {

    private static final Logger log = LoggerFactory.getLogger(NotificationEventListener.class);

    private final NotificationPort webSocketNotificationAdapter;
    private final MockFcmNotificationAdapter fcmNotificationAdapter;

    public NotificationEventListener(NotificationPort webSocketNotificationAdapter,
                                       MockFcmNotificationAdapter fcmNotificationAdapter) {
        this.webSocketNotificationAdapter = webSocketNotificationAdapter;
        this.fcmNotificationAdapter = fcmNotificationAdapter;
    }

    @Async("notificationExecutor")
    @EventListener
    public void handleTransactionCompleted(TransactionCompletedEvent event) {
        Transaction tx = event.getTransaction();
        Wallet wallet = event.getWallet();

        log.info("Async notification processing for txId={} walletId={}", tx.getId(), wallet.getId());

        // 1. Send WebSocket update
        webSocketNotificationAdapter.notifyTransactionCompleted(tx, wallet);

        // 2. Send FCM Push Notification
        String title = "Biến động số dư ví: " + tx.getType().name();
        String body = String.format("Giao dịch %s thành công %s %s. Số dư mới: %s %s",
                tx.getStatus(), tx.getAmount().getAmount(), tx.getAmount().getCurrency(),
                wallet.getBalance().getAmount(), wallet.getBalance().getCurrency());

        fcmNotificationAdapter.sendPushNotification(wallet.getOwnerId(), title, body);
    }
}
