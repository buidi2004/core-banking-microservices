package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.model.SupportTicket;
import com.fintech.wallet.domain.model.TicketMessage;
import com.fintech.wallet.domain.port.in.SupportUseCase;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class SupportService implements SupportUseCase {

    private final List<SupportTicket> ticketStore = new ArrayList<>();
    private final List<TicketMessage> messageStore = new ArrayList<>();

    @Override
    public SupportTicket createTicket(String userId, String subject, String category, String initialMessage) {
        SupportTicket ticket = SupportTicket.createNew(userId, subject, category);
        ticketStore.add(ticket);

        TicketMessage msg = TicketMessage.createNew(ticket.getId(), userId, "USER", initialMessage);
        messageStore.add(msg);
        return ticket;
    }

    @Override
    public List<SupportTicket> getTickets(String userId) {
        return ticketStore.stream()
                .filter(t -> t.getUserId().equals(userId))
                .collect(Collectors.toList());
    }

    @Override
    public SupportTicket getTicketById(String ticketId) {
        return ticketStore.stream()
                .filter(t -> t.getId().equals(ticketId))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Ticket not found: " + ticketId));
    }

    @Override
    public TicketMessage addMessage(String ticketId, String senderId, String senderType, String content) {
        SupportTicket ticket = getTicketById(ticketId);
        TicketMessage msg = TicketMessage.createNew(ticket.getId(), senderId, senderType, content);
        messageStore.add(msg);
        ticket.updateStatus("IN_PROGRESS");
        return msg;
    }

    @Override
    public List<TicketMessage> getTicketMessages(String ticketId) {
        return messageStore.stream()
                .filter(m -> m.getTicketId().equals(ticketId))
                .collect(Collectors.toList());
    }

    @Override
    public List<Map<String, String>> getFaqs() {
        List<Map<String, String>> faqs = new ArrayList<>();
        Map<String, String> faq1 = new HashMap<>();
        faq1.put("question", "Làm sao để nạp tiền vào ví?");
        faq1.put("answer", "Bạn có thể nạp tiền thông qua Ngân hàng đã liên kết hoặc mã VietQR.");
        faqs.add(faq1);

        Map<String, String> faq2 = new HashMap<>();
        faq2.put("question", "Hạn mức giao dịch là bao nhiêu?");
        faq2.put("answer", "Hạn mức giao dịch tối đa là 5 triệu/ngày cho tài khoản chưa KYC và 100 triệu/ngày cho tài khoản đã KYC.");
        faqs.add(faq2);
        return faqs;
    }
}
