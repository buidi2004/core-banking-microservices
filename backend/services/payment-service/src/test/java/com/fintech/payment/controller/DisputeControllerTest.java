package com.fintech.payment.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fintech.payment.domain.entity.DisputeCase;
import com.fintech.payment.domain.entity.Transaction;
import com.fintech.payment.dto.dispute.AssignDisputeRequest;
import com.fintech.payment.dto.dispute.CreateDisputeRequest;
import com.fintech.payment.dto.dispute.ManualReversalRequest;
import com.fintech.payment.dto.dispute.ResolveDisputeRequest;
import com.fintech.payment.service.DisputeRefundService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.data.domain.PageImpl;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(controllers = DisputeController.class)
@AutoConfigureMockMvc(addFilters = false)
class DisputeControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private DisputeRefundService service;

    @Test
    @DisplayName("POST /api/v1/payments/disputes - Tạo yêu cầu tra soát thành công")
    void createDispute_success() throws Exception {
        UUID id = UUID.randomUUID();
        DisputeCase dispute = DisputeCase.builder()
                .id(id)
                .transactionId("tx-100")
                .customerId("user-01")
                .disputeType("GENERAL")
                .reason("Không nhận được tiền")
                .status("OPEN")
                .refundAmount(500_000L)
                .createdBy("user-01")
                .createdAt(Instant.now())
                .updatedAt(Instant.now())
                .build();

        when(service.createDispute(any(), eq("user-01"), eq("user-01"))).thenReturn(dispute);

        CreateDisputeRequest request = new CreateDisputeRequest("tx-100", "GENERAL", "Không nhận được tiền", 500_000L);

        mockMvc.perform(post("/api/v1/payments/disputes")
                        .header("X-User-Id", "user-01")
                        .header("X-User-Role", "USER")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.transactionId").value("tx-100"))
                .andExpect(jsonPath("$.data.status").value("OPEN"));
    }

    @Test
    @DisplayName("GET /api/v1/payments/disputes - Lấy danh sách tra soát")
    void listDisputes_success() throws Exception {
        UUID id = UUID.randomUUID();
        DisputeCase dispute = DisputeCase.builder()
                .id(id)
                .transactionId("tx-100")
                .customerId("user-01")
                .status("OPEN")
                .refundAmount(500_000L)
                .reason("Test")
                .createdBy("user-01")
                .createdAt(Instant.now())
                .updatedAt(Instant.now())
                .build();

        when(service.listDisputes(any(), any())).thenReturn(new PageImpl<>(List.of(dispute)));

        mockMvc.perform(get("/api/v1/payments/disputes")
                        .header("X-User-Id", "staff-01")
                        .header("X-User-Role", "ROLE_TELLER"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.content[0].transactionId").value("tx-100"));
    }

    @Test
    @DisplayName("POST /api/v1/payments/disputes/{id}/resolve - Quản lý duyệt hoàn tiền tra soát")
    void resolveDispute_asManager_success() throws Exception {
        UUID id = UUID.randomUUID();
        DisputeCase dispute = DisputeCase.builder()
                .id(id)
                .transactionId("tx-100")
                .customerId("user-01")
                .status("REVERSED")
                .refundAmount(500_000L)
                .resolutionNote("Đã xác minh và hoàn tiền")
                .resolvedBy("manager-01")
                .createdBy("user-01")
                .createdAt(Instant.now())
                .updatedAt(Instant.now())
                .build();

        when(service.resolveDispute(eq(id), any(), eq("manager-01"))).thenReturn(dispute);

        ResolveDisputeRequest request = new ResolveDisputeRequest("REFUND", "Đã xác minh và hoàn tiền");

        mockMvc.perform(post("/api/v1/payments/disputes/" + id + "/resolve")
                        .header("X-User-Id", "manager-01")
                        .header("X-User-Role", "ROLE_MANAGER")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.status").value("REVERSED"));
    }

    @Test
    @DisplayName("POST /api/v1/payments/disputes/{id}/resolve - Chặn nếu không phải Quản lý")
    void resolveDispute_forbiddenForNonManager() throws Exception {
        UUID id = UUID.randomUUID();
        ResolveDisputeRequest request = new ResolveDisputeRequest("REFUND", "Hoàn tiền");

        mockMvc.perform(post("/api/v1/payments/disputes/" + id + "/resolve")
                        .header("X-User-Id", "teller-01")
                        .header("X-User-Role", "ROLE_TELLER")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("POST /api/v1/payments/transactions/{id}/reversal - Quản lý thực hiện đảo bút toán trực tiếp")
    void manualReversal_success() throws Exception {
        Transaction tx = Transaction.builder()
                .id("tx-200")
                .transactionCode("TXC-200")
                .status("REVERSED")
                .amount(200_000L)
                .build();

        when(service.executeDirectReversal(eq("tx-200"), anyString(), eq("manager-01"))).thenReturn(tx);

        ManualReversalRequest request = new ManualReversalRequest("Lỗi hạch toán giao dịch trùng");

        mockMvc.perform(post("/api/v1/payments/transactions/tx-200/reversal")
                        .header("X-User-Id", "manager-01")
                        .header("X-User-Role", "ROLE_MANAGER")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.status").value("REVERSED"));
    }
}

