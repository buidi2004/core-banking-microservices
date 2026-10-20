package com.fintech.notification.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fintech.notification.dto.TicketMessage;
import com.fintech.notification.entity.SupportTicket;
import com.fintech.notification.repository.SupportTicketRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
public class SupportService {

    private static final Logger log = LoggerFactory.getLogger(SupportService.class);

    private final SupportTicketRepository supportTicketRepository;
    private final ObjectMapper objectMapper;

    public SupportService(SupportTicketRepository supportTicketRepository, ObjectMapper objectMapper) {
        this.supportTicketRepository = supportTicketRepository;
        this.objectMapper = objectMapper;
    }

    @Transactional
    public SupportTicket createTicket(String userId, String subject, String category, String initialMessage) {
        SupportTicket ticket = new SupportTicket();
        ticket.setId(UUID.randomUUID());
        ticket.setUserId(userId);
        ticket.setSubject(subject);
        ticket.setDescription(initialMessage != null ? initialMessage : "");
        ticket.setCategory(category != null && !category.isBlank() ? category : "GENERAL");
        ticket.setStatus("OPEN");
        ticket.setPriority("NORMAL");

        List<TicketMessage> messages = new ArrayList<>();
        messages.add(new TicketMessage(UUID.randomUUID().toString(), ticket.getId().toString(),
                userId, "USER", initialMessage, Instant.now()));
        ticket.setMessagesJson(writeMessages(messages));
        return supportTicketRepository.save(ticket);
    }

    public List<SupportTicket> getTickets(String userId) {
        return supportTicketRepository.findByUserIdOrderByCreatedAtDesc(userId);
    }

    public SupportTicket getTicketById(String ticketId) {
        return supportTicketRepository.findById(UUID.fromString(ticketId))
                .orElseThrow(() -> new IllegalArgumentException("Ticket not found: " + ticketId));
    }

    @Transactional
    public TicketMessage addMessage(String ticketId, String senderId, String senderType, String content) {
        SupportTicket ticket = getTicketById(ticketId);
        List<TicketMessage> messages = readMessages(ticket.getMessagesJson());
        TicketMessage message = new TicketMessage(UUID.randomUUID().toString(), ticket.getId().toString(),
                senderId, senderType, content, Instant.now());
        messages.add(message);
        ticket.setMessagesJson(writeMessages(messages));
        if (!"CLOSED".equals(ticket.getStatus()) && !"RESOLVED".equals(ticket.getStatus())) {
            ticket.setStatus("IN_PROGRESS");
        }
        supportTicketRepository.save(ticket);
        return message;
    }

    public List<TicketMessage> getTicketMessages(String ticketId) {
        return readMessages(getTicketById(ticketId).getMessagesJson());
    }

    public List<Map<String, String>> getFaqs() {
        List<Map<String, String>> faqs = new ArrayList<>();
        faqs.add(faq("Làm sao để nạp tiền vào ví?",
                "Bạn có thể nạp tiền thông qua Ngân hàng đã liên kết hoặc mã VietQR."));
        faqs.add(faq("Hạn mức giao dịch là bao nhiêu?",
                "Hạn mức tối đa 5 triệu/ngày cho tài khoản chưa KYC và 100 triệu/ngày cho tài khoản đã KYC."));
        return faqs;
    }

    private Map<String, String> faq(String question, String answer) {
        Map<String, String> faq = new LinkedHashMap<>();
        faq.put("question", question);
        faq.put("answer", answer);
        return faq;
    }

    private List<TicketMessage> readMessages(String json) {
        if (json == null || json.isBlank()) {
            return new ArrayList<>();
        }
        try {
            return objectMapper.readValue(json, new TypeReference<List<TicketMessage>>() { });
        } catch (Exception e) {
            log.error("Failed to parse ticket messages JSON", e);
            return new ArrayList<>();
        }
    }

    private String writeMessages(List<TicketMessage> messages) {
        try {
            return objectMapper.writeValueAsString(messages);
        } catch (Exception e) {
            throw new IllegalStateException("Failed to serialize ticket messages", e);
        }
    }
}
