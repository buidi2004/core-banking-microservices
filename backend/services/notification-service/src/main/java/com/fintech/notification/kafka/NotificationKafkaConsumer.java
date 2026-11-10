package com.fintech.notification.kafka;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fintech.notification.amqp.NotificationConsumer;
import com.fintech.wallet.domain.event.TransactionEvent;
import com.fintech.wallet.kafka.KafkaTopicConstants;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Component
public class NotificationKafkaConsumer {

    private static final Logger log = LoggerFactory.getLogger(NotificationKafkaConsumer.class);

    public static final String TOPIC_CASH_DEPOSIT_COMPLETED = "banking.cash.deposit-completed.v1";

    private final NotificationConsumer notificationConsumer;
    private final ObjectMapper objectMapper;

    public NotificationKafkaConsumer(NotificationConsumer notificationConsumer, ObjectMapper objectMapper) {
        this.notificationConsumer = notificationConsumer;
        this.objectMapper = objectMapper;
    }

    @KafkaListener(
            topics = {
                    KafkaTopicConstants.TOPIC_PAYMENT_TRANSACTION_LIFECYCLE,
                    KafkaTopicConstants.TOPIC_WALLET_BALANCE_CHANGED,
                    TOPIC_CASH_DEPOSIT_COMPLETED
            },
            groupId = KafkaConsumerConfig.CONSUMER_GROUP_ID,
            containerFactory = KafkaConsumerConfig.LISTENER_CONTAINER_FACTORY)
    public void onTransactionEvent(ConsumerRecord<String, String> record, Acknowledgment acknowledgment) {
        try {
            TransactionEvent event = parse(record.value(), record.topic());
            if (event != null) {
                notificationConsumer.onTransactionEvent(event);
                log.info("Kafka notification event consumed: topic={} partition={} offset={} key={} txId={}",
                        record.topic(), record.partition(), record.offset(), record.key(), event.getTransactionId());
            } else {
                log.debug("Kafka notification event skipped: topic={} partition={} offset={} key={}",
                        record.topic(), record.partition(), record.offset(), record.key());
            }
        } catch (Exception e) {
            log.error("Failed to process Kafka notification event: topic={} key={} payload={}",
                    record.topic(), record.key(), record.value(), e);
            throw e;
        } finally {
            acknowledgment.acknowledge();
        }
    }

    public TransactionEvent parse(String payload) {
        return parse(payload, null);
    }

    public TransactionEvent parse(String payload, String topic) {
        if (payload == null || payload.isBlank()) {
            throw new IllegalArgumentException("Empty Kafka transaction event payload");
        }
        try {
            JsonNode root = objectMapper.readTree(payload);
            JsonNode eventNode = root.hasNonNull("payload") ? root.get("payload") : root;
            // Tương thích ngược: outbox cũ publish payload dưới dạng JSON string (double-encoded).
            if (eventNode != null && eventNode.isTextual()) {
                eventNode = objectMapper.readTree(eventNode.asText());
            }

            // 1. Xử lý sự kiện nạp tiền mặt tại quầy (Cash Deposit Completed)
            if (TOPIC_CASH_DEPOSIT_COMPLETED.equals(topic)
                    || (eventNode != null && "DepositCompletedEvent".equals(eventNode.path("eventType").asText()))) {
                return parseCashDepositEvent(eventNode, root);
            }

            // 2. Xử lý sự kiện biến động số dư ví từ Wallet Service (WalletBalanceChangedPayload)
            if (eventNode != null && eventNode.has("changeAmount") && eventNode.has("walletId")) {
                return parseWalletBalanceChanged(eventNode, root);
            }

            // 3. Xử lý chuẩn TransactionEvent từ Payment Lifecycle (Outbox Relay)
            return objectMapper.treeToValue(eventNode, TransactionEvent.class);
        } catch (Exception e) {
            throw new IllegalArgumentException("Cannot deserialize Kafka transaction event", e);
        }
    }

    private TransactionEvent parseCashDepositEvent(JsonNode node, JsonNode root) {
        TransactionEvent tx = new TransactionEvent();
        String eventId = root.hasNonNull("eventId") ? root.get("eventId").asText() : UUID.randomUUID().toString();
        tx.setEventId(eventId);

        String depositCode = node.path("depositCode").asText(root.path("aggregateId").asText(null));
        if (depositCode == null || depositCode.isBlank()) {
            depositCode = "DEP-" + System.currentTimeMillis();
        }
        tx.setTransactionId(depositCode);
        tx.setType("DEPOSIT");
        tx.setStatus("SUCCESS");

        String account = node.path("accountNumber").asText("");
        tx.setTargetWalletId(account);
        if (node.hasNonNull("customerPhone")) {
            tx.setTargetPhone(node.get("customerPhone").asText());
        }

        long amountVal = node.path("amount").asLong(0);
        tx.setAmount(BigDecimal.valueOf(amountVal));
        tx.setFeeAmount(BigDecimal.ZERO);
        tx.setCurrency(node.path("currency").asText("VND"));

        if (node.hasNonNull("targetWalletId")) {
            tx.setTargetWalletId(node.get("targetWalletId").asText());
        }
        if (node.hasNonNull("targetUserId")) {
            tx.setTargetUserId(node.get("targetUserId").asText());
        }
        if (node.hasNonNull("balanceAfter")) {
            tx.setTargetBalanceAfter(BigDecimal.valueOf(node.get("balanceAfter").asLong()));
        } else if (node.hasNonNull("targetBalanceAfter")) {
            tx.setTargetBalanceAfter(BigDecimal.valueOf(node.get("targetBalanceAfter").asLong()));
        }

        String branchId = node.path("branchId").asText("");
        String customerName = node.path("customerName").asText("");
        String note = "Nạp tiền mặt tại quầy " + branchId + (!customerName.isBlank() ? " - " + customerName : "");
        tx.setNote(note);

        long timestamp = node.path("timestamp").asLong(0);
        tx.setOccurredAt(timestamp > 0 ? Instant.ofEpochMilli(timestamp) : Instant.now());
        return tx;
    }

    private TransactionEvent parseWalletBalanceChanged(JsonNode node, JsonNode root) {
        String changeType = node.path("changeType").asText("ADJUSTMENT").toUpperCase();
        // Bỏ qua RESERVE / RELEASE vì chỉ là giữ chỗ tạm thời trong Saga, không thay đổi số dư thực
        if ("RESERVE".equals(changeType) || "RELEASE".equals(changeType)) {
            return null;
        }

        TransactionEvent tx = new TransactionEvent();
        String eventId = root.hasNonNull("eventId") ? root.get("eventId").asText() : UUID.randomUUID().toString();
        tx.setEventId(eventId);

        String txId = node.path("transactionId").asText(null);
        if (txId == null || txId.isBlank()) {
            txId = "BAL-" + UUID.randomUUID().toString().substring(0, 8);
        }
        tx.setTransactionId(txId);

        BigDecimal changeAmount = new BigDecimal(node.path("changeAmount").asText("0"));
        BigDecimal newBalance = new BigDecimal(node.path("newBalance").asText("0"));
        String currency = node.path("currency").asText("VND");
        String walletId = node.path("walletId").asText("");

        tx.setAmount(changeAmount.abs());
        tx.setFeeAmount(BigDecimal.ZERO);
        tx.setCurrency(currency);
        tx.setStatus("SUCCESS");
        tx.setOccurredAt(Instant.now());

        boolean isDeduct = changeAmount.compareTo(BigDecimal.ZERO) < 0
                || "TRANSFER_OUT".equals(changeType)
                || "WITHDRAWAL".equals(changeType)
                || "FEE_CHARGE".equals(changeType);

        if (isDeduct) {
            tx.setType(changeType);
            tx.setSourceWalletId(walletId);
            tx.setSourceBalanceAfter(newBalance);
        } else {
            tx.setType(changeType);
            tx.setTargetWalletId(walletId);
            tx.setTargetBalanceAfter(newBalance);
        }
        return tx;
    }
}
