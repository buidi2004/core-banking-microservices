package com.fintech.wallet.domain.port.in;

import com.fintech.wallet.domain.model.SupportTicket;
import com.fintech.wallet.domain.model.TicketMessage;

import java.util.List;
import java.util.Map;

public interface SupportUseCase {
    SupportTicket createTicket(String userId, String subject, String category, String initialMessage);
    List<SupportTicket> getTickets(String userId);
    SupportTicket getTicketById(String ticketId);
    TicketMessage addMessage(String ticketId, String senderId, String senderType, String content);
    List<TicketMessage> getTicketMessages(String ticketId);
    List<Map<String, String>> getFaqs();
}
