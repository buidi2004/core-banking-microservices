package com.fintech.ledger.presentation.controller;

import com.fintech.ledger.infrastructure.persistence.entity.AuditLogJpaEntity;
import com.fintech.ledger.infrastructure.persistence.repository.SpringAuditLogRepository;
import com.fintech.ledger.presentation.dto.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@RestController
@RequestMapping("/api/v1/ledger/admin/audit-logs")
@RequiredArgsConstructor
public class AuditLogController {
    private final SpringAuditLogRepository repository;

    @GetMapping
    public ResponseEntity<ApiResponse<List<AuditLogJpaEntity>>> list(
            @RequestHeader(value = "X-User-Role", required = false) String role,
            @RequestParam(required = false) String actorId,
            @RequestParam(required = false) String entityType,
            @RequestParam(required = false) String entityId,
            @RequestParam(required = false) String correlationId) {
        requireManager(role);
        List<AuditLogJpaEntity> result;
        if (correlationId != null && !correlationId.isBlank()) {
            result = repository.findTop500ByCorrelationIdOrderByPerformedAtDesc(correlationId.trim());
        } else if (actorId != null && !actorId.isBlank()) {
            result = repository.findTop500ByPerformedByOrderByPerformedAtDesc(actorId.trim());
        } else if (entityType != null && !entityType.isBlank()
                && entityId != null && !entityId.isBlank()) {
            result = repository.findTop500ByEntityTypeAndEntityIdOrderByPerformedAtDesc(
                    entityType.trim(), entityId.trim());
        } else {
            result = repository.findTop500ByOrderByPerformedAtDesc();
        }
        return ResponseEntity.ok(ApiResponse.ok("Audit logs retrieved", result));
    }

    private void requireManager(String role) {
        if (role == null || (!"ROLE_MANAGER".equalsIgnoreCase(role.trim())
                && !"MANAGER".equalsIgnoreCase(role.trim()))) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                    "Only ROLE_MANAGER may access audit logs");
        }
    }
}
