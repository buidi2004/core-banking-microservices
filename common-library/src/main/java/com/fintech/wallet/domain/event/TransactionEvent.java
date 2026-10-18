package com.fintech.wallet.domain.event;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * Hợp đồng sự kiện giao dịch dùng chung giữa các microservices.
 *
 * <p>Được Payment Service publish (Outbox Relay) lên RabbitMQ, tiêu thụ bởi
 * Ledger Service và Notification Service. Các trường {@code sourceUserId},
 * {@code targetUserId}, số dư snapshot và {@code note} là tùy chọn để tương
 * thích ngược với event phiên bản cũ chỉ chứa wallet id.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public class TransactionEvent {

    private String eventId;
    private String transactionId;
    private String type;
    private String status;

    private String sourceWalletId;
    private String targetWalletId;

    private String sourceUserId;
    private String targetUserId;

    private String sourcePhone;
    private String targetPhone;

    private BigDecimal amount;
    private BigDecimal feeAmount;
    private String currency;

    private BigDecimal sourceBalanceAfter;
    private BigDecimal targetBalanceAfter;

    private String note;
    private Instant occurredAt;

    public TransactionEvent() {
    }

    public String getEventId() { return eventId; }
    public void setEventId(String eventId) { this.eventId = eventId; }

    public String getTransactionId() { return transactionId; }
    public void setTransactionId(String transactionId) { this.transactionId = transactionId; }

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getSourceWalletId() { return sourceWalletId; }
    public void setSourceWalletId(String sourceWalletId) { this.sourceWalletId = sourceWalletId; }

    public String getTargetWalletId() { return targetWalletId; }
    public void setTargetWalletId(String targetWalletId) { this.targetWalletId = targetWalletId; }

    public String getSourceUserId() { return sourceUserId; }
    public void setSourceUserId(String sourceUserId) { this.sourceUserId = sourceUserId; }

    public String getTargetUserId() { return targetUserId; }
    public void setTargetUserId(String targetUserId) { this.targetUserId = targetUserId; }

    public String getSourcePhone() { return sourcePhone; }
    public void setSourcePhone(String sourcePhone) { this.sourcePhone = sourcePhone; }

    public String getTargetPhone() { return targetPhone; }
    public void setTargetPhone(String targetPhone) { this.targetPhone = targetPhone; }

    public BigDecimal getAmount() { return amount; }
    public void setAmount(BigDecimal amount) { this.amount = amount; }

    public BigDecimal getFeeAmount() { return feeAmount; }
    public void setFeeAmount(BigDecimal feeAmount) { this.feeAmount = feeAmount; }

    public String getCurrency() { return currency; }
    public void setCurrency(String currency) { this.currency = currency; }

    public BigDecimal getSourceBalanceAfter() { return sourceBalanceAfter; }
    public void setSourceBalanceAfter(BigDecimal sourceBalanceAfter) { this.sourceBalanceAfter = sourceBalanceAfter; }

    public BigDecimal getTargetBalanceAfter() { return targetBalanceAfter; }
    public void setTargetBalanceAfter(BigDecimal targetBalanceAfter) { this.targetBalanceAfter = targetBalanceAfter; }

    public String getNote() { return note; }
    public void setNote(String note) { this.note = note; }

    public Instant getOccurredAt() { return occurredAt; }
    public void setOccurredAt(Instant occurredAt) { this.occurredAt = occurredAt; }
}
