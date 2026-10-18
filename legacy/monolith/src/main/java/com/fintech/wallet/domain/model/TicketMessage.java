package com.fintech.wallet.domain.model;

import java.time.Instant;
import java.util.UUID;

public class TicketMessage {
    private final String id;
    private final String ticketId;
    private final String senderId;
    private final String senderType; // USER, SUPPORT
    private final String content;
    private final Instant createdAt;

    public TicketMessage(String id, String ticketId, String senderId, String senderType, String content, Instant createdAt) {
        this.id = id != null ? id : UUID.randomUUID().toString();
        this.ticketId = ticketId;
        this.senderId = senderId;
        this.senderType = senderType != null ? senderType : "USER";
        this.content = content;
        this.createdAt = createdAt != null ? createdAt : Instant.now();
    }

    public static TicketMessage createNew(String ticketId, String senderId, String senderType, String content) {
        return new TicketMessage(UUID.randomUUID().toString(), ticketId, senderId, senderType, content, Instant.now());
    }

    public String getId() { return id; }
    public String getTicketId() { return ticketId; }
    public String getSenderId() { return senderId; }
    public String getSenderType() { return senderType; }
    public String getContent() { return content; }
    public Instant getCreatedAt() { return createdAt; }
}
