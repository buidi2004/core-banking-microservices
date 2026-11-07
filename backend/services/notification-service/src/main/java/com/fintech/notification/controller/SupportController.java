package com.fintech.notification.controller;

import com.fintech.notification.dto.ApiResponse;
import com.fintech.notification.dto.TicketMessage;
import com.fintech.notification.entity.SupportTicket;
import com.fintech.notification.service.SupportService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/support")
public class SupportController {

    private final SupportService supportService;

    public SupportController(SupportService supportService) {
        this.supportService = supportService;
    }

    @PostMapping("/tickets")
    public ResponseEntity<ApiResponse<SupportTicket>> createTicket(
            @RequestHeader(name = "X-User-Id", required = false) String userId,
            @RequestParam String subject,
            @RequestParam(required = false, defaultValue = "GENERAL") String category,
            @RequestParam String initialMessage) {
        String uid = requireUser(userId);
        SupportTicket ticket = supportService.createTicket(uid, subject, category, initialMessage);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Support ticket created", ticket));
    }

    @GetMapping("/tickets")
    public ResponseEntity<ApiResponse<List<SupportTicket>>> getTickets(
            @RequestHeader(name = "X-User-Id", required = false) String userId) {
        String uid = requireUser(userId);
        return ResponseEntity.ok(ApiResponse.success("Tickets retrieved", supportService.getTickets(uid)));
    }

    @GetMapping("/admin/tickets")
    public ResponseEntity<ApiResponse<List<SupportTicket>>> getAllTickets(
            @RequestHeader(name = "X-User-Id", required = false) String userId,
            @RequestHeader(name = "X-User-Role", required = false) String userRole) {
        requireUser(userId);
        if (!isStaffOrManager(userRole)) {
            throw new org.springframework.web.server.ResponseStatusException(
                    HttpStatus.FORBIDDEN, "Only Bank Staff (Teller, Manager, Admin) may access admin tickets");
        }
        return ResponseEntity.ok(ApiResponse.success("All tickets retrieved", supportService.getAllTickets()));
    }

    @GetMapping("/tickets/{id}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getTicketDetail(@PathVariable String id) {
        SupportTicket ticket = supportService.getTicketById(id);
        List<TicketMessage> messages = supportService.getTicketMessages(id);
        Map<String, Object> response = new LinkedHashMap<>();
        response.put("ticket", ticket);
        response.put("messages", messages);
        return ResponseEntity.ok(ApiResponse.success("Ticket details retrieved", response));
    }

    @PostMapping("/tickets/{id}/messages")
    public ResponseEntity<ApiResponse<TicketMessage>> addMessage(
            @RequestHeader(name = "X-User-Id", required = false) String userId,
            @PathVariable String id,
            @RequestParam String content,
            @RequestParam(required = false, defaultValue = "USER") String senderType) {
        String uid = requireUser(userId);
        TicketMessage message = supportService.addMessage(id, uid, senderType, content);
        return ResponseEntity.ok(ApiResponse.success("Message sent to ticket thread", message));
    }

    @PostMapping("/tickets/{id}/resolve")
    public ResponseEntity<ApiResponse<SupportTicket>> resolveTicket(
            @RequestHeader(name = "X-User-Id", required = false) String userId,
            @RequestHeader(name = "X-User-Role", required = false) String userRole,
            @PathVariable String id,
            @RequestParam(required = false, defaultValue = "Đã giải quyết yêu cầu") String resolutionNotes) {
        String uid = requireUser(userId);
        SupportTicket ticket = supportService.getTicketById(id);
        if (!uid.equalsIgnoreCase(String.valueOf(ticket.getUserId())) && !isStaffOrManager(userRole)) {
            throw new org.springframework.web.server.ResponseStatusException(
                    HttpStatus.FORBIDDEN, "Only ticket owner or bank staff may resolve ticket");
        }
        SupportTicket updated = supportService.resolveTicket(id, uid, resolutionNotes);
        return ResponseEntity.ok(ApiResponse.success("Ticket resolved successfully", updated));
    }

    @PostMapping("/tickets/{id}/close")
    public ResponseEntity<ApiResponse<SupportTicket>> closeTicket(
            @RequestHeader(name = "X-User-Id", required = false) String userId,
            @RequestHeader(name = "X-User-Role", required = false) String userRole,
            @PathVariable String id) {
        String uid = requireUser(userId);
        SupportTicket ticket = supportService.getTicketById(id);
        if (!uid.equalsIgnoreCase(String.valueOf(ticket.getUserId())) && !isStaffOrManager(userRole)) {
            throw new org.springframework.web.server.ResponseStatusException(
                    HttpStatus.FORBIDDEN, "Only ticket owner or bank staff may close ticket");
        }
        SupportTicket updated = supportService.closeTicket(id, uid);
        return ResponseEntity.ok(ApiResponse.success("Ticket closed successfully", updated));
    }

    @GetMapping("/faq")
    public ResponseEntity<ApiResponse<List<Map<String, String>>>> getFaqs() {
        return ResponseEntity.ok(ApiResponse.success("FAQ list retrieved", supportService.getFaqs()));
    }

    private String requireUser(String userId) {
        if (userId == null || userId.isBlank()) {
            throw new IllegalArgumentException("Missing trusted header X-User-Id");
        }
        return userId;
    }

    private boolean isStaffOrManager(String role) {
        if (role == null || role.isBlank()) {
            return false;
        }
        String r = role.toUpperCase();
        return r.contains("TELLER") || r.contains("MANAGER") || r.contains("ADMIN")
                || r.contains("SUPPORT") || r.contains("STAFF");
    }
}
