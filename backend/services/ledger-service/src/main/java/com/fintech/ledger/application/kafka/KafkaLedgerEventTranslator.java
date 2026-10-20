package com.fintech.ledger.application.kafka;

import com.fintech.ledger.application.dto.TransactionEventMessage;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.Map;

/**
 * Chuyển 2 schema payload Kafka về TransactionEventMessage (hợp đồng nội bộ của LedgerService):
 *
 * 1) wallet balance-changed (Agent 2, key = walletId):
 *    { walletId, transactionId?, event/direction: CREDIT|DEBIT, amount, currency? , balanceAfter? }
 *    - CREDIT  (số dư tăng)  ≈ DEPOSIT  → Nợ BANK_SETTLEMENT, Có CUSTOMER_DEPOSITS:{walletId}
 *    - DEBIT   (số dư giảm) ≈ WITHDRAWAL → Nợ CUSTOMER_DEPOSITS:{walletId}, Có BANK_SETTLEMENT
 *
 * 2) payment transaction-lifecycle (Agent 3, key = transactionId):
 *    { transactionId, type/eventType, status/sagaStatus, sourceWalletId, targetWalletId, amount, currency }
 *    - PASS THÔNG trực tiếp vì cùng hợp đồng TransactionEvent (SUCCESS → POSTED, REVERSED → bù).
 */
@Component
public class KafkaLedgerEventTranslator {

    public TransactionEventMessage fromWalletBalanceChanged(KafkaEventEnvelope envelope) {
        Map<String, Object> payload = requirePayload(envelope);
        String walletId = requireString(payload, "walletId", "wallet_id", "WalletId");
        BigDecimal amount = requireAmount(payload);
        String direction = firstString(payload, "event", "direction", "changeType", "balanceChangeEvent", "type");
        String transactionId = firstString(payload, "transactionId", "TransactionId", "txId");
        String currency = firstString(payload, "currency", "Currency");
        if (currency == null) {
            currency = "VND";
        }

        if (transactionId == null || transactionId.isBlank()) {
            transactionId = "wallet-event:" + walletId + ":" + envelope.getEventId();
        }

        TransactionEventMessage event = new TransactionEventMessage();
        event.setEventId(envelope.getEventId());
        event.setTransactionId(transactionId);
        if ("CREDIT".equalsIgnoreCase(direction)) {
            event.setType("DEPOSIT");
            event.setTargetWalletId(walletId);
        } else if ("DEBIT".equalsIgnoreCase(direction)) {
            event.setType("WITHDRAWAL");
            event.setSourceWalletId(walletId);
        } else {
            throw new IllegalArgumentException("Wallet balance-changed event must carry CREDIT or DEBIT direction, got: "
                    + direction + ", envelope=" + envelope);
        }
        event.setStatus("SUCCESS");
        event.setAmount(amount);
        event.setCurrency(currency);
        event.setOccurredAt(envelope.timestampInstant());
        return event;
    }

    public TransactionEventMessage fromPaymentLifecycle(KafkaEventEnvelope envelope) {
        Map<String, Object> payload = requirePayload(envelope);
        String transactionId = firstString(payload, "transactionId", "transaction_id", "TransactionId", "depositCode");
        if (transactionId == null || transactionId.isBlank()) {
            transactionId = requireString(payload, "transactionId", "transaction_id", "TransactionId");
        }
        BigDecimal amount = requireAmount(payload);
        String type = firstString(payload, "type", "transactionType", "eventType");
        if ("DepositCompletedEvent".equalsIgnoreCase(type)) {
            type = "CASH_DEPOSIT";
        }
        String status = firstString(payload, "status", "sagaStatus", "eventStatus", "lifecycleStatus");
        if ((status == null || status.isBlank()) && "CASH_DEPOSIT".equalsIgnoreCase(type)) {
            status = "COMPLETED";
        }

        TransactionEventMessage event = new TransactionEventMessage();
        event.setEventId(envelope.getEventId() != null ? envelope.getEventId() : "evt-" + transactionId);
        event.setTransactionId(transactionId);
        event.setType(type);
        event.setStatus(status);
        event.setSourceWalletId(firstString(payload, "sourceWalletId", "source_wallet_id", "sourceWallet"));
        event.setTargetWalletId(firstString(payload, "targetWalletId", "target_wallet_id", "targetWallet", "accountNumber"));
        event.setAmount(amount);
        String currency = firstString(payload, "currency", "Currency");
        event.setCurrency(currency != null ? currency : "VND");
        event.setOccurredAt(envelope.timestampInstant());
        return event;
    }

    private Map<String, Object> requirePayload(KafkaEventEnvelope envelope) {
        if (envelope == null) {
            throw new IllegalArgumentException("Kafka envelope is null");
        }
        Map<String, Object> payload = envelope.getPayload();
        if (payload == null) {
            throw new IllegalArgumentException("Kafka envelope must carry payload: " + envelope);
        }
        if (envelope.getEventId() == null || envelope.getEventId().isBlank()) {
            String derived = firstString(payload, "depositCode", "deposit_code", "transactionId", "txId");
            if (derived != null && !derived.isBlank()) {
                envelope.setEventId("evt-" + derived);
            } else {
                throw new IllegalArgumentException("Kafka envelope must carry eventId (idempotency key)");
            }
        }
        return payload;
    }

    private String requireString(Map<String, Object> payload, String... keys) {
        String value = firstString(payload, keys);
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException("Payload must carry one of keys " + String.join("/", keys));
        }
        return value;
    }

    private BigDecimal requireAmount(Map<String, Object> payload) {
        Object amount = firstValue(payload, "amount", "Amount", "value");
        if (amount == null) {
            throw new IllegalArgumentException("Payload must carry amount");
        }
        BigDecimal parsed = new BigDecimal(String.valueOf(amount));
        if (parsed.signum() <= 0) {
            throw new IllegalArgumentException("Amount must be strictly positive, got: " + parsed);
        }
        return parsed;
    }

    private String firstString(Map<String, Object> payload, String... keys) {
        Object value = firstValue(payload, keys);
        return value != null ? String.valueOf(value) : null;
    }

    private Object firstValue(Map<String, Object> payload, String... keys) {
        for (String key : keys) {
            if (payload.containsKey(key) && payload.get(key) != null) {
                return payload.get(key);
            }
        }
        return null;
    }
}
