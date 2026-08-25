package com.fintech.wallet.presentation.controller;

import com.fintech.wallet.domain.model.SupportTicket;
import com.fintech.wallet.domain.model.TicketMessage;
import com.fintech.wallet.domain.port.in.SupportUseCase;
import com.fintech.wallet.presentation.response.ApiResponse;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/support")
public class SupportController {

    private final SupportUseCase supportUseCase;

    public SupportController(SupportUseCase supportUseCase) {
        this.supportUseCase = supportUseCase;
    }

    @PostMapping("/tickets")
    public ResponseEntity<ApiResponse<SupportTicket>> createTicket(
            Authentication auth,
            @RequestParam String subject,
            @RequestParam(required = false, defaultValue = "GENERAL") String category,
            @RequestParam String initialMessage) {
        String userId = auth.getName();
        SupportTicket ticket = supportUseCase.createTicket(userId, subject, category, initialMessage);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Dispute ticket created", ticket));
    }

    @GetMapping("/tickets")
    public ResponseEntity<ApiResponse<List<SupportTicket>>> getTickets(Authentication auth) {
        String userId = auth.getName();
        List<SupportTicket> tickets = supportUseCase.getTickets(userId);
        return ResponseEntity.ok(ApiResponse.success("Tickets retrieved", tickets));
    }

    @GetMapping("/tickets/{id}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getTicketDetail(@PathVariable String id) {
        SupportTicket ticket = supportUseCase.getTicketById(id);
        List<TicketMessage> messages = supportUseCase.getTicketMessages(id);
        Map<String, Object> response = Map.of("ticket", ticket, "messages", messages);
        return ResponseEntity.ok(ApiResponse.success("Ticket details retrieved", response));
    }

    @PostMapping("/tickets/{id}/messages")
    public ResponseEntity<ApiResponse<TicketMessage>> addMessage(
            Authentication auth,
            @PathVariable String id,
            @RequestParam String content) {
        String userId = auth.getName();
        TicketMessage msg = supportUseCase.addMessage(id, userId, "USER", content);
        return ResponseEntity.ok(ApiResponse.success("Message sent to ticket thread", msg));
    }

    @GetMapping("/faq")
    public ResponseEntity<ApiResponse<List<Map<String, String>>>> getFaqs() {
        List<Map<String, String>> faqs = supportUseCase.getFaqs();
        return ResponseEntity.ok(ApiResponse.success("FAQ list retrieved", faqs));
    }
}
