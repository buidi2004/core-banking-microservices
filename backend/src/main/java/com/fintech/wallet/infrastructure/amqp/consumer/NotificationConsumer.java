package com.fintech.wallet.infrastructure.amqp.consumer;

import com.fintech.wallet.domain.model.Transaction;
import com.fintech.wallet.domain.model.TransactionEvent;
import com.fintech.wallet.domain.model.Wallet;
import com.fintech.wallet.domain.port.out.NotificationPort;
import com.fintech.wallet.domain.port.out.TransactionPersistencePort;
import com.fintech.wallet.domain.port.out.UserPersistencePort;
import com.fintech.wallet.domain.port.out.WalletPersistencePort;
import com.fintech.wallet.infrastructure.config.RabbitMqConfig;
import com.fintech.wallet.infrastructure.notification.MockFcmNotificationAdapter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

import java.util.Optional;
import java.util.concurrent.TimeUnit;

@Component
public class NotificationConsumer {

    private static final Logger log = LoggerFactory.getLogger(NotificationConsumer.class);
    
    private final NotificationPort notificationPort;
    private final TransactionPersistencePort transactionPersistencePort;
    private final WalletPersistencePort walletPersistencePort;
    private final UserPersistencePort userPersistencePort;
    private final StringRedisTemplate redisTemplate;
    private final MockFcmNotificationAdapter fcmNotificationAdapter;

    public NotificationConsumer(NotificationPort notificationPort, 
                              TransactionPersistencePort transactionPersistencePort, 
                              WalletPersistencePort walletPersistencePort, 
                              UserPersistencePort userPersistencePort,
                              StringRedisTemplate redisTemplate,
                              MockFcmNotificationAdapter fcmNotificationAdapter) {
        this.notificationPort = notificationPort;
        this.transactionPersistencePort = transactionPersistencePort;
        this.walletPersistencePort = walletPersistencePort;
        this.userPersistencePort = userPersistencePort;
        this.redisTemplate = redisTemplate;
        this.fcmNotificationAdapter = fcmNotificationAdapter;
    }

    @RabbitListener(queues = RabbitMqConfig.QUEUE_NOTIFICATION)
    public void receiveMessage(TransactionEvent event) {
        String idempotencyKey = "processed:event:notification:" + event.getEventId();
        Boolean isNew = redisTemplate.opsForValue().setIfAbsent(idempotencyKey, "1", 24, TimeUnit.HOURS);
        
        if (Boolean.FALSE.equals(isNew)) {
            log.info("Duplicate event ignored in NotificationConsumer: {}", event.getEventId());
            return;
        }

        log.info("Processing notification for transaction: {}", event.getTransactionId());
        try {
            Optional<Transaction> txOpt = transactionPersistencePort.findTransactionById(event.getTransactionId());
            if (txOpt.isEmpty()) {
                log.warn("Transaction {} not found for notification", event.getTransactionId());
                return;
            }
            Transaction tx = txOpt.get();

            if (event.getSourceWalletId() != null) {
                walletPersistencePort.findWalletById(event.getSourceWalletId())
                        .ifPresent(w -> {
                            notificationPort.notifyTransactionCompleted(tx, w);
                            sendFcmPushNotification(tx, w);
                        });
            }

            if (event.getTargetWalletId() != null && !event.getTargetWalletId().equals(event.getSourceWalletId())) {
                walletPersistencePort.findWalletById(event.getTargetWalletId())
                        .ifPresent(w -> {
                            notificationPort.notifyTransactionCompleted(tx, w);
                            sendFcmPushNotification(tx, w);
                        });
            }
        } catch (Exception e) {
            log.error("Error processing notification for transaction {}", event.getTransactionId(), e);
            redisTemplate.delete(idempotencyKey); // Allow retry
            if (e instanceof RuntimeException) {
                throw (RuntimeException) e;
            }
            throw new RuntimeException(e);
        }
    }

    private void sendFcmPushNotification(Transaction tx, Wallet wallet) {
        boolean isDeduct = tx.getType() == com.fintech.wallet.domain.model.TransactionType.WITHDRAWAL ||
                (tx.getType() == com.fintech.wallet.domain.model.TransactionType.TRANSFER && wallet.getId().equals(tx.getSourceWalletId()));

        String myPhone = userPersistencePort.findUserById(wallet.getOwnerId())
                .map(com.fintech.wallet.domain.model.User::getPhoneNumber)
                .orElse(wallet.getId());

        String counterpartyPhone = null;
        if (tx.getType() == com.fintech.wallet.domain.model.TransactionType.TRANSFER) {
            String counterpartyWalletId = isDeduct ? tx.getTargetWalletId() : tx.getSourceWalletId();
            if (counterpartyWalletId != null) {
                counterpartyPhone = walletPersistencePort.findWalletById(counterpartyWalletId)
                        .flatMap(w -> userPersistencePort.findUserById(w.getOwnerId()))
                        .map(com.fintech.wallet.domain.model.User::getPhoneNumber)
                        .orElse(counterpartyWalletId);
            }
        }

        String title = "Biến động số dư ví: " + tx.getType().name();
        StringBuilder bodyBuilder = new StringBuilder();
        bodyBuilder.append(String.format("TK %s GD %s thành công %s %s. SD: %s %s",
                myPhone, tx.getStatus(), tx.getAmount().getAmount(), tx.getAmount().getCurrency(),
                wallet.getBalance().getAmount(), wallet.getBalance().getCurrency()));
        
        if (counterpartyPhone != null) {
            if (isDeduct) {
                bodyBuilder.append(" - Đến: ").append(counterpartyPhone);
            } else {
                bodyBuilder.append(" - Từ: ").append(counterpartyPhone);
            }
        }
        if (tx.getNote() != null && !tx.getNote().isBlank()) {
            bodyBuilder.append(" - ND: ").append(tx.getNote());
        }

        fcmNotificationAdapter.sendPushNotification(wallet.getOwnerId(), title, bodyBuilder.toString());
    }
}
