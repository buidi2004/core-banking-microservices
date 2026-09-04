package com.fintech.wallet.infrastructure.notification;

import com.fintech.wallet.domain.model.Transaction;
import com.fintech.wallet.domain.model.Wallet;
import com.fintech.wallet.domain.port.out.NotificationPort;
import com.fintech.wallet.domain.port.out.NotificationQueryPort;
import com.fintech.wallet.domain.port.out.UserPersistencePort;
import com.fintech.wallet.domain.port.out.WalletPersistencePort;
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
    private final NotificationQueryPort notificationQueryPort;
    private final UserPersistencePort userPersistencePort;
    private final WalletPersistencePort walletPersistencePort;

    public WebSocketNotificationAdapter(SimpMessagingTemplate messagingTemplate, 
                                        NotificationQueryPort notificationQueryPort,
                                        UserPersistencePort userPersistencePort,
                                        WalletPersistencePort walletPersistencePort) {
        this.messagingTemplate = messagingTemplate;
        this.notificationQueryPort = notificationQueryPort;
        this.userPersistencePort = userPersistencePort;
        this.walletPersistencePort = walletPersistencePort;
    }

    @Override
    public void notifyTransactionCompleted(Transaction transaction, Wallet wallet, com.fintech.wallet.domain.model.User user, Wallet counterpartyWallet, com.fintech.wallet.domain.model.User counterpartyUser) {
        if (wallet == null || wallet.getId() == null) {
            return;
        }

        String destination = "/topic/wallets/" + wallet.getId() + "/notifications";

        String payloadType = transaction.getType().name();
        boolean isDeduct = false;
        String operationType = "Giao dịch";
        
        if (transaction.getType() == com.fintech.wallet.domain.model.TransactionType.TRANSFER) {
            if (wallet.getId().equals(transaction.getSourceWalletId())) {
                payloadType = "TRANSFER_OUT";
                isDeduct = true;
                operationType = "Chuyển tiền";
            } else if (wallet.getId().equals(transaction.getTargetWalletId())) {
                payloadType = "TRANSFER_IN";
                isDeduct = false;
                operationType = "Nhận tiền";
            }
        } else if (transaction.getType() == com.fintech.wallet.domain.model.TransactionType.WITHDRAWAL) {
            isDeduct = true;
            operationType = "Rút tiền";
        } else if (transaction.getType() == com.fintech.wallet.domain.model.TransactionType.DEPOSIT) {
            isDeduct = false;
            operationType = "Nạp tiền";
        } else if (transaction.getType() == com.fintech.wallet.domain.model.TransactionType.REVERSAL) {
            isDeduct = false;
            operationType = "Hoàn tiền";
        } else if (transaction.getType() == com.fintech.wallet.domain.model.TransactionType.BILL_PAYMENT) {
            isDeduct = true;
            operationType = "Thanh toán hoá đơn";
        } else if (transaction.getType() == com.fintech.wallet.domain.model.TransactionType.TOPUP) {
            isDeduct = true; 
            operationType = "Nạp tiền điện thoại";
        }

        String sign = isDeduct ? "-" : "+";
        java.math.BigDecimal displayAmountValue = transaction.getAmount().getAmount();
        if (isDeduct && transaction.getFeeAmount() != null) {
            displayAmountValue = displayAmountValue.add(transaction.getFeeAmount().getAmount());
        }

        java.math.BigDecimal snapshotBalance = null;
        if (isDeduct && transaction.getBalanceAfter() != null) {
            snapshotBalance = transaction.getBalanceAfter().getAmount();
        } else if (!isDeduct && transaction.getReceiverBalanceAfter() != null) {
            snapshotBalance = transaction.getReceiverBalanceAfter().getAmount();
        }
        if (snapshotBalance == null) {
            snapshotBalance = wallet.getBalance().getAmount(); // Fallback just in case
        }

        java.text.NumberFormat formatter = java.text.NumberFormat.getInstance(new java.util.Locale("vi", "VN"));
        String formattedAmount = formatter.format(displayAmountValue);
        String formattedBalance = formatter.format(snapshotBalance);
        String currency = transaction.getAmount().getCurrency();
        
        java.time.format.DateTimeFormatter dtf = java.time.format.DateTimeFormatter.ofPattern("HH:mm dd/MM/yyyy").withZone(java.time.ZoneId.of("Asia/Ho_Chi_Minh"));
        String formattedTime = dtf.format(transaction.getCreatedAt());

        String myPhone = user != null ? user.getPhoneNumber() : wallet.getId();
        
        String counterpartyPhone = null;
        String counterpartyName = null;
        if (counterpartyUser != null) {
            counterpartyPhone = counterpartyUser.getPhoneNumber();
            counterpartyName = counterpartyUser.getFullName();
        } else if (counterpartyWallet != null) {
            counterpartyPhone = counterpartyWallet.getId();
        }

        String content = transaction.getNote() != null && !transaction.getNote().isBlank() ? transaction.getNote() : operationType + " thành công";
        String title = "Biến động số dư: " + operationType;
        
        StringBuilder bodyBuilder = new StringBuilder();
        bodyBuilder.append(String.format("Tài khoản: %s\nPS: %s%s %s\nSố dư cuối: %s %s\nThời gian: %s",
                myPhone, sign, formattedAmount, currency, formattedBalance, currency, formattedTime));
        
        if (counterpartyPhone != null) {
            String displayCounterparty = (counterpartyName != null && !counterpartyName.isBlank()) ? counterpartyName + " (" + counterpartyPhone + ")" : counterpartyPhone;
            if (isDeduct) {
                bodyBuilder.append("\nChuyển đến: ").append(displayCounterparty);
            } else {
                bodyBuilder.append("\nNhận từ: ").append(displayCounterparty);
            }
        }
        bodyBuilder.append("\nNội dung: ").append(content);
        String body = bodyBuilder.toString();

        // OPT #4: Type-safe DTO instead of raw HashMap
        NotificationPayload payload = new NotificationPayload(
                transaction.getId(),
                transaction.getRequestId(),
                payloadType,
                transaction.getStatus().name(),
                wallet.getId(),
                transaction.getAmount().getAmount(),
                transaction.getAmount().getCurrency(),
                snapshotBalance,
                wallet.getBalance().getCurrency(),
                transaction.getCreatedAt().toString(),
                transaction.getNote(),
                title,
                body
        );

        try {
            messagingTemplate.convertAndSend(destination, payload);
            // OPT #5: Only log destination at INFO; full payload at DEBUG to avoid leaking sensitive data
            log.info("Pushed transaction notification to {}", destination);
            log.debug("Notification payload: {}", payload);
        } catch (Exception e) {
            log.error("Failed to send WebSocket notification to {}", destination, e);
        }

        try {
            String metadata = "{\"transactionId\":\"" + transaction.getId() + "\"}";
            
            com.fintech.wallet.domain.model.NotificationInfo notification = com.fintech.wallet.domain.model.NotificationInfo.createNew(
                    wallet.getOwnerId(),
                    title,
                    body,
                    com.fintech.wallet.domain.model.NotificationType.BALANCE,
                    metadata
            );
            notificationQueryPort.saveNotification(notification);
        } catch (Exception e) {
            log.error("Failed to persist notification to DB for wallet={}", wallet.getId(), e);
        }
    }
}
