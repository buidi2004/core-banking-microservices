package com.fintech.notification.dto;

import java.time.Instant;

public record TicketMessage(
        String id,
        String ticketId,
        String senderId,
        String senderType,
        String content,
        Instant createdAt
) {
}
