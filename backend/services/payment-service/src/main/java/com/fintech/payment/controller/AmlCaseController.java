package com.fintech.payment.controller;

import com.fintech.payment.domain.entity.AmlCase;
import com.fintech.payment.dto.ApiResponse;
import com.fintech.payment.dto.aml.AssignAmlCaseRequest;
import com.fintech.payment.dto.aml.CreateAmlCaseRequest;
import com.fintech.payment.dto.aml.UpdateAmlCaseStatusRequest;
import com.fintech.payment.service.AmlCaseService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/aml/cases")
@RequiredArgsConstructor
public class AmlCaseController {
    private final AmlCaseService service;

    @GetMapping
    public ResponseEntity<ApiResponse<List<AmlCase>>> list(
            @RequestHeader(value = "X-User-Role", required = false) String role,
            @RequestParam(required = false) String status) {
        requireManager(role);
        return ResponseEntity.ok(ApiResponse.success("AML cases retrieved", service.list(status)));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<AmlCase>> create(
            @RequestHeader(value = "X-User-Id", required = false) String actor,
            @RequestHeader(value = "X-User-Role", required = false) String role,
            @Valid @RequestBody CreateAmlCaseRequest request) {
        requireManager(role);
        requireUser(actor);
        int slaHours = request.slaHours() == null ? 24 : request.slaHours();
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.success("AML case created",
                service.create(request.transactionId(), request.customerId(), request.reason(), slaHours, actor)));
    }

    @PostMapping("/{id}/assign")
    public ResponseEntity<ApiResponse<AmlCase>> assign(
            @PathVariable UUID id,
            @RequestHeader(value = "X-User-Id", required = false) String actor,
            @RequestHeader(value = "X-User-Role", required = false) String role,
            @Valid @RequestBody AssignAmlCaseRequest request) {
        requireManager(role);
        requireUser(actor);
        return ResponseEntity.ok(ApiResponse.success("AML case assigned",
                service.assign(id, request.assigneeId(), request.reason(), actor)));
    }

    @PostMapping("/{id}/status")
    public ResponseEntity<ApiResponse<AmlCase>> status(
            @PathVariable UUID id,
            @RequestHeader(value = "X-User-Id", required = false) String actor,
            @RequestHeader(value = "X-User-Role", required = false) String role,
            @Valid @RequestBody UpdateAmlCaseStatusRequest request) {
        requireManager(role);
        requireUser(actor);
        return ResponseEntity.ok(ApiResponse.success("AML case status updated",
                service.transitionWithSideEffects(id, request.status(), request.reason(), actor)));
    }

    @GetMapping("/{id}/events")
    public ResponseEntity<ApiResponse<?>> events(
            @PathVariable UUID id,
            @RequestHeader(value = "X-User-Role", required = false) String role) {
        requireManager(role);
        return ResponseEntity.ok(ApiResponse.success("AML case audit events retrieved", service.events(id)));
    }

    private void requireUser(String id) {
        if (id == null || id.isBlank()) {
            throw new org.springframework.web.server.ResponseStatusException(
                    HttpStatus.UNAUTHORIZED, "Missing trusted user");
        }
    }

    private void requireManager(String role) {
        if (role == null || role.isBlank()) {
            throw new org.springframework.web.server.ResponseStatusException(
                    HttpStatus.FORBIDDEN, "Missing role for AML access");
        }
        String r = role.toUpperCase();
        if (!r.contains("MANAGER") && !r.contains("ADMIN") && !r.contains("COMPLIANCE") && !r.contains("AUDITOR")) {
            throw new org.springframework.web.server.ResponseStatusException(
                    HttpStatus.FORBIDDEN, "Only Manager, Admin or Compliance Officer may access AML cases");
        }
    }
}
