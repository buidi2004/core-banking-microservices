package com.fintech.wallet.infrastructure.amqp.consumer;

import com.fintech.wallet.domain.model.Transaction;
import com.fintech.wallet.domain.model.TransactionEvent;
import com.fintech.wallet.domain.model.Wallet;
import com.fintech.wallet.domain.port.out.NotificationPort;
import com.fintech.wallet.domain.port.out.TransactionPersistencePort;
import com.fintech.wallet.domain.port.out.UserPersistencePort;
import com.fintech.wallet.domain.port.out.WalletPersistencePort;
import com.fintech.wallet.infrastructure.config.RabbitMqConfig;
import com.fintech.wallet.domain.port.out.FcmNotificationPort;
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
    private final FcmNotificationPort fcmNotificationAdapter;

    public NotificationConsumer(NotificationPort notificationPort, 
                              TransactionPersistencePort transactionPersistencePort, 
                              WalletPersistencePort walletPersistencePort, 
                              UserPersistencePort userPersistencePort,
                              StringRedisTemplate redisTemplate,
                              FcmNotificationPort fcmNotificationAdapter) {
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

            Wallet sourceW = tx.getSourceWalletId() != null ? walletPersistencePort.findWalletById(tx.getSourceWalletId()).orElse(null) : null;
            Wallet targetW = tx.getTargetWalletId() != null ? walletPersistencePort.findWalletById(tx.getTargetWalletId()).orElse(null) : null;
            
            com.fintech.wallet.domain.model.User sourceU = sourceW != null ? userPersistencePort.findUserById(sourceW.getOwnerId()).orElse(null) : null;
            com.fintech.wallet.domain.model.User targetU = targetW != null ? userPersistencePort.findUserById(targetW.getOwnerId()).orElse(null) : null;

            if (sourceW != null) {
                try {
                    notificationPort.notifyTransactionCompleted(tx, sourceW, sourceU, targetW, targetU);
                } catch (Exception e) {
                    log.error("Failed to send WebSocket notification for source wallet={}", sourceW.getId(), e);
                }
                try {
                    sendFcmPushNotification(tx, sourceW, sourceU, targetW, targetU);
                } catch (Exception e) {
                    log.error("Failed to send FCM push notification for source wallet={}", sourceW.getId(), e);
                }
            }

            if (targetW != null && !targetW.getId().equals(tx.getSourceWalletId())) {
                try {
                    notificationPort.notifyTransactionCompleted(tx, targetW, targetU, sourceW, sourceU);
                } catch (Exception e) {
                    log.error("Failed to send WebSocket notification for target wallet={}", targetW.getId(), e);
                }
                try {
                    sendFcmPushNotification(tx, targetW, targetU, sourceW, sourceU);
                } catch (Exception e) {
                    log.error("Failed to send FCM push notification for target wallet={}", targetW.getId(), e);
                }
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

    private void sendFcmPushNotification(Transaction tx, Wallet wallet, com.fintech.wallet.domain.model.User user, Wallet counterpartyWallet, com.fintech.wallet.domain.model.User counterpartyUser) {
        boolean isDeduct = wallet.getId().equals(tx.getSourceWalletId());

        String myPhone = user != null ? user.getPhoneNumber() : wallet.getId();

        String counterpartyPhone = null;
        String counterpartyName = null;
        
        if (counterpartyUser != null) {
            counterpartyPhone = counterpartyUser.getPhoneNumber();
            counterpartyName = counterpartyUser.getFullName();
        } else if (counterpartyWallet != null) {
            counterpartyPhone = counterpartyWallet.getId();
        }

        java.math.BigDecimal displayAmountValue = tx.getAmount().getAmount();
        if (isDeduct && tx.getFeeAmount() != null) {
            displayAmountValue = displayAmountValue.add(tx.getFeeAmount().getAmount());
        }

        // Use the balance snapshot captured at commit time, not the live wallet balance.
        // Live balance can differ if another transaction modified the wallet between commit and
        // when this consumer runs (async via RabbitMQ). Snapshot is always correct for this tx.
        boolean isDeductForBalance = wallet.getId().equals(tx.getSourceWalletId());
        java.math.BigDecimal snapshotBalance;
        if (isDeductForBalance) {
            snapshotBalance = tx.getBalanceAfter() != null
                    ? tx.getBalanceAfter().getAmount()
                    : wallet.getBalance().getAmount(); // fallback only if snapshot missing
        } else {
            snapshotBalance = tx.getReceiverBalanceAfter() != null
                    ? tx.getReceiverBalanceAfter().getAmount()
                    : wallet.getBalance().getAmount(); // fallback only if snapshot missing
        }

        java.text.NumberFormat formatter = java.text.NumberFormat.getInstance(new java.util.Locale("vi", "VN"));
        String formattedAmount = formatter.format(displayAmountValue);
        String formattedBalance = formatter.format(snapshotBalance);

        String operationType = "Giao dịch";
        String payloadType = tx.getType() != null ? tx.getType().name() : "TRANSACTION";
        if (tx.getType() == com.fintech.wallet.domain.model.TransactionType.TRANSFER) {
            if (isDeduct) {
                operationType = "Chuyển tiền";
                payloadType = "TRANSFER_OUT";
            } else {
                operationType = "Nhận tiền";
                payloadType = "TRANSFER_IN";
            }
        } else if (tx.getType() == com.fintech.wallet.domain.model.TransactionType.WITHDRAWAL) {
            operationType = "Rút tiền";
        } else if (tx.getType() == com.fintech.wallet.domain.model.TransactionType.DEPOSIT) {
            operationType = "Nạp tiền";
        } else if (tx.getType() == com.fintech.wallet.domain.model.TransactionType.REVERSAL) {
            operationType = "Hoàn tiền";
        } else if (tx.getType() == com.fintech.wallet.domain.model.TransactionType.BILL_PAYMENT) {
            operationType = "Thanh toán hoá đơn";
        } else if (tx.getType() == com.fintech.wallet.domain.model.TransactionType.TOPUP) {
            operationType = "Nạp tiền điện thoại";
        }
        String title = "Biến động số dư: " + operationType;
        StringBuilder bodyBuilder = new StringBuilder();
        String sign = isDeduct ? "-" : "+";
        bodyBuilder.append(String.format("TK %s GD thành công. PS: %s%s %s. SD: %s %s",
                myPhone, sign, formattedAmount, tx.getAmount().getCurrency(),
                formattedBalance, tx.getAmount().getCurrency()));
        
        if (counterpartyPhone != null) {
            String displayCounterparty = (counterpartyName != null && !counterpartyName.isBlank()) ? counterpartyName + " (" + counterpartyPhone + ")" : counterpartyPhone;
            if (isDeduct) {
                bodyBuilder.append(" - Đến: ").append(displayCounterparty);
            } else {
                bodyBuilder.append(" - Từ: ").append(displayCounterparty);
            }
        }
        if (tx.getNote() != null && !tx.getNote().isBlank()) {
            bodyBuilder.append(" - ND: ").append(tx.getNote());
        }

        String body = bodyBuilder.toString();

        java.util.Map<String, String> data = new java.util.HashMap<>();
        data.put("transactionId", tx.getId() != null ? tx.getId() : "");
        data.put("requestId", tx.getRequestId() != null ? tx.getRequestId() : "");
        data.put("type", payloadType);
        data.put("status", tx.getStatus() != null ? tx.getStatus().name() : "SUCCESS");
        data.put("walletId", wallet.getId() != null ? wallet.getId() : "");
        data.put("transactionAmount", String.valueOf(tx.getAmount().getAmount()));
        data.put("amount", String.valueOf(tx.getAmount().getAmount()));
        data.put("transactionCurrency", tx.getAmount().getCurrency() != null ? tx.getAmount().getCurrency() : "VND");
        data.put("newBalance", String.valueOf(snapshotBalance));
        data.put("currency", wallet.getBalance() != null ? wallet.getBalance().getCurrency() : "VND");
        data.put("timestamp", tx.getCreatedAt() != null ? tx.getCreatedAt().toString() : java.time.Instant.now().toString());
        data.put("note", tx.getNote() != null ? tx.getNote() : "");
        data.put("title", title);
        data.put("body", body);

        fcmNotificationAdapter.sendPushNotification(wallet.getOwnerId(), title, body, data);
    }
}
