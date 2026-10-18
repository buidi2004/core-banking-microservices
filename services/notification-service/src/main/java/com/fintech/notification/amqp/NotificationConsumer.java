package com.fintech.notification.amqp;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fintech.notification.config.RabbitMqConfig;
import com.fintech.notification.entity.Notification;
import com.fintech.notification.notification.EventIdempotencyStore;
import com.fintech.notification.notification.FcmPushSender;
import com.fintech.notification.notification.NotificationPayload;
import com.fintech.notification.notification.WebSocketNotifier;
import com.fintech.notification.service.NotificationService;
import com.fintech.wallet.domain.event.TransactionEvent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.text.NumberFormat;
import java.time.Instant;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;

@Component
public class NotificationConsumer {

    private static final Logger log = LoggerFactory.getLogger(NotificationConsumer.class);

    private static final DateTimeFormatter TIME_FORMATTER =
            DateTimeFormatter.ofPattern("HH:mm dd/MM/yyyy").withZone(java.time.ZoneId.of("Asia/Ho_Chi_Minh"));

    private final EventIdempotencyStore idempotencyStore;
    private final NotificationService notificationService;
    private final WebSocketNotifier webSocketNotifier;
    private final FcmPushSender fcmPushSender;
    private final ObjectMapper objectMapper;

    public NotificationConsumer(EventIdempotencyStore idempotencyStore,
                                NotificationService notificationService,
                                WebSocketNotifier webSocketNotifier,
                                FcmPushSender fcmPushSender,
                                ObjectMapper objectMapper) {
        this.idempotencyStore = idempotencyStore;
        this.notificationService = notificationService;
        this.webSocketNotifier = webSocketNotifier;
        this.fcmPushSender = fcmPushSender;
        this.objectMapper = objectMapper;
    }

    @RabbitListener(queues = RabbitMqConfig.QUEUE_NOTIFICATION)
    public void onTransactionEvent(TransactionEvent event) {
        if (event == null || event.getTransactionId() == null) {
            log.warn("Received empty transaction event, ignoring");
            return;
        }
        if (!idempotencyStore.markProcessed(event.getEventId())) {
            return;
        }

        log.info("Processing transaction notification for txId={} type={}",
                event.getTransactionId(), event.getType());
        try {
            boolean sameWallet = isSameWallet(event);
            if (hasText(event.getSourceWalletId())) {
                dispatch(event, event.getSourceWalletId(), event.getSourceUserId(), event.getSourcePhone(),
                        true, event.getTargetWalletId(), event.getTargetUserId(), event.getTargetPhone());
            }
            if (hasText(event.getTargetWalletId()) && !sameWallet) {
                dispatch(event, event.getTargetWalletId(), event.getTargetUserId(), event.getTargetPhone(),
                        false, event.getSourceWalletId(), event.getSourceUserId(), event.getSourcePhone());
            }
        } catch (Exception e) {
            log.error("Error processing notification for txId={}", event.getTransactionId(), e);
            idempotencyStore.forget(event.getEventId());
            throw new RuntimeException(e);
        }
    }

    private void dispatch(TransactionEvent event, String walletId, String userId, String phone,
                          boolean isDeduct, String counterpartyWalletId,
                          String counterpartyUserId, String counterpartyPhone) {
        String operation = operationType(event.getType(), isDeduct);
        String amount = format(displayAmount(event, isDeduct));
        String balance = format(snapshotBalance(event, isDeduct));
        String currency = hasText(event.getCurrency()) ? event.getCurrency() : "VND";
        String recipient = hasText(phone) ? phone : walletId;

        String title = "Biến động số dư: " + operation;
        String sign = isDeduct ? "-" : "+";
        StringBuilder body = new StringBuilder();
        body.append(String.format("TK %s GD thành công. PS: %s%s %s. SD: %s %s",
                recipient, sign, amount, currency, balance, currency));

        String counterparty = hasText(counterpartyPhone) ? counterpartyPhone : counterpartyWalletId;
        if (hasText(counterparty)) {
            body.append(isDeduct ? " - Đến: " : " - Từ: ").append(counterparty);
        }
        if (hasText(event.getNote())) {
            body.append(" - ND: ").append(event.getNote());
        }
        String bodyText = body.toString();

        String payloadType = payloadType(event.getType(), isDeduct);
        String status = hasText(event.getStatus()) ? event.getStatus() : "SUCCESS";
        Instant occurredAt = event.getOccurredAt() != null ? event.getOccurredAt() : Instant.now();

        Map<String, String> data = buildData(event, walletId, isDeduct, currency, title, bodyText);
        String dataPayload = writeJson(data);
        String resolvedUserId = hasText(userId) ? userId : walletId;

        NotificationPayload payload = new NotificationPayload(
                event.getTransactionId(),
                event.getTransactionId(),
                payloadType,
                status,
                walletId,
                displayAmount(event, isDeduct),
                currency,
                snapshotBalance(event, isDeduct),
                currency,
                TIME_FORMATTER.format(occurredAt),
                event.getNote(),
                title,
                bodyText
        );

        try {
            notificationService.save(Notification.create(resolvedUserId, "BALANCE", title, bodyText, "FCM", dataPayload));
        } catch (Exception e) {
            log.error("Failed to persist notification for userId={} walletId={}", resolvedUserId, walletId, e);
        }

        webSocketNotifier.pushToWallet(walletId, payload);
        if (hasText(userId)) {
            webSocketNotifier.pushToUser(userId, payload);
        }

        fcmPushSender.sendPushNotification(resolvedUserId, title, bodyText, data);
    }

    private String writeJson(Map<String, String> data) {
        try {
            return objectMapper.writeValueAsString(data);
        } catch (Exception e) {
            log.error("Failed to serialize notification data payload", e);
            return "{}";
        }
    }

    private Map<String, String> buildData(TransactionEvent event, String walletId, boolean isDeduct,
                                          String currency, String title, String body) {
        Map<String, String> data = new HashMap<>();
        data.put("transactionId", nullSafe(event.getTransactionId()));
        data.put("type", payloadType(event.getType(), isDeduct));
        data.put("status", hasText(event.getStatus()) ? event.getStatus() : "SUCCESS");
        data.put("walletId", nullSafe(walletId));
        data.put("transactionAmount", String.valueOf(displayAmount(event, isDeduct)));
        data.put("amount", String.valueOf(displayAmount(event, isDeduct)));
        data.put("currency", currency);
        data.put("transactionCurrency", currency);
        data.put("newBalance", String.valueOf(snapshotBalance(event, isDeduct)));
        data.put("timestamp", (event.getOccurredAt() != null ? event.getOccurredAt() : Instant.now()).toString());
        data.put("note", nullSafe(event.getNote()));
        data.put("title", title);
        data.put("body", body);
        return data;
    }

    private boolean isSameWallet(TransactionEvent event) {
        return hasText(event.getSourceWalletId())
                && event.getSourceWalletId().equals(event.getTargetWalletId());
    }

    private String operationType(String type, boolean isDeduct) {
        if (type == null) {
            return "Giao dịch";
        }
        switch (type.toUpperCase()) {
            case "TRANSFER":
                return isDeduct ? "Chuyển tiền" : "Nhận tiền";
            case "WITHDRAWAL":
                return "Rút tiền";
            case "DEPOSIT":
                return "Nạp tiền";
            case "REVERSAL":
                return "Hoàn tiền";
            case "BILL_PAYMENT":
                return "Thanh toán hoá đơn";
            case "TOPUP":
                return "Nạp tiền điện thoại";
            default:
                return "Giao dịch";
        }
    }

    private String payloadType(String type, boolean isDeduct) {
        if ("TRANSFER".equalsIgnoreCase(type)) {
            return isDeduct ? "TRANSFER_OUT" : "TRANSFER_IN";
        }
        return type != null ? type.toUpperCase() : "TRANSACTION";
    }

    private BigDecimal displayAmount(TransactionEvent event, boolean isDeduct) {
        BigDecimal amount = event.getAmount() != null ? event.getAmount() : BigDecimal.ZERO;
        if (isDeduct && event.getFeeAmount() != null) {
            amount = amount.add(event.getFeeAmount());
        }
        return amount;
    }

    private BigDecimal snapshotBalance(TransactionEvent event, boolean isDeduct) {
        BigDecimal snapshot = isDeduct ? event.getSourceBalanceAfter() : event.getTargetBalanceAfter();
        return snapshot != null ? snapshot : BigDecimal.ZERO;
    }

    private String format(BigDecimal value) {
        NumberFormat formatter = NumberFormat.getInstance(new Locale("vi", "VN"));
        return formatter.format(value != null ? value : BigDecimal.ZERO);
    }

    private boolean hasText(String value) {
        return value != null && !value.isBlank();
    }

    private String nullSafe(String value) {
        return value != null ? value : "";
    }
}
