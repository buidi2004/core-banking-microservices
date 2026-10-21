package com.fintech.payment.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fintech.payment.dto.TransferRequest;
import com.fintech.payment.saga.PaymentSagaOrchestrator;
import com.fintech.payment.saga.SagaContext;
import com.fintech.payment.security.PinTokenValidator;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(TransferController.class)
@AutoConfigureMockMvc(addFilters = false)
class TransferControllerPinTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private PaymentSagaOrchestrator sagaOrchestrator;

    @MockBean
    private PinTokenValidator pinTokenValidator;

    @Test
    @DisplayName("P2P Transfer: Khi truyền pinToken sai -> từ chối với INVALID_PIN_TOKEN và không chạy saga")
    void p2pTransfer_InvalidPinToken_ShouldReject() throws Exception {
        TransferRequest request = TransferRequest.builder()
                .sourceUserId("user-source")
                .targetUserId("user-target")
                .amount(100_000L)
                .currency("VND")
                .idempotencyKey("idem-p2p-1001")
                .pinToken("invalid-pin-token")
                .build();

        when(pinTokenValidator.validatePinToken("invalid-pin-token", "user-source")).thenReturn(false);

        mockMvc.perform(post("/api/v1/payments/transfer")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("INVALID_PIN_TOKEN"));

        verify(sagaOrchestrator, never()).transferP2p(any(), any(), any(), any(), any(), any());
    }

    @Test
    @DisplayName("P2P Transfer: pinToken hợp lệ -> chạy saga và thành công")
    void p2pTransfer_ValidPinToken_ShouldSucceed() throws Exception {
        TransferRequest request = TransferRequest.builder()
                .sourceUserId("user-source")
                .targetUserId("user-target")
                .amount(100_000L)
                .currency("VND")
                .idempotencyKey("idem-p2p-1002")
                .pinToken("valid-pin-token")
                .build();

        when(pinTokenValidator.validatePinToken("valid-pin-token", "user-source")).thenReturn(true);

        SagaContext ctx = new SagaContext();
        ctx.setTransactionId("tx-1002");
        ctx.setTransactionCode("TXN_1002");
        ctx.setStatus("SUCCESS");

        when(sagaOrchestrator.transferP2p(eq("user-source"), eq("user-target"), eq(100_000L), eq("VND"), any(), eq("idem-p2p-1002")))
                .thenReturn(ctx);

        mockMvc.perform(post("/api/v1/payments/transfer")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }

    @Test
    @DisplayName("Chuyển tiền thất bại do số dư không đủ trả về HTTP 400 và mã lỗi INSUFFICIENT_BALANCE")
    void p2pTransfer_InsufficientBalance_ReturnsBadRequest() throws Exception {
        TransferRequest request = TransferRequest.builder()
                .sourceUserId("user-source")
                .targetUserId("user-target")
                .amount(5_000_000L)
                .currency("VND")
                .idempotencyKey("idem-p2p-insufficient")
                .pinToken("valid-pin-token")
                .build();

        when(pinTokenValidator.validatePinToken("valid-pin-token", "user-source")).thenReturn(true);

        SagaContext ctx = new SagaContext();
        ctx.setTransactionId("tx-failed-1");
        ctx.setStatus("FAILED");
        ctx.setFailureReason("Balance 10000 < 5000000");

        when(sagaOrchestrator.transferP2p(eq("user-source"), eq("user-target"), eq(5_000_000L), eq("VND"), any(), eq("idem-p2p-insufficient")))
                .thenReturn(ctx);

        mockMvc.perform(post("/api/v1/payments/transfer")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("INSUFFICIENT_BALANCE"));
    }
}

