package com.fintech.payment.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fintech.payment.dto.DepositRequest;
import com.fintech.payment.dto.DepositResponse;
import com.fintech.payment.dto.WithdrawRequest;
import com.fintech.payment.dto.WithdrawResponse;
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

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest({DepositWithdrawController.class, WalletMutationController.class})
@AutoConfigureMockMvc(addFilters = false)
class DepositWithdrawControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private PaymentSagaOrchestrator sagaOrchestrator;

    @MockBean
    private PinTokenValidator pinTokenValidator;

    @Test
    @DisplayName("Deposit: Nạp tiền ví thành công trả về mã giao dịch và số dư mới")
    void deposit_Success() throws Exception {
        DepositRequest request = DepositRequest.builder()
                .walletId("wallet-123")
                .amount(500_000L)
                .currency("VND")
                .requestId("req-dep-1001")
                .build();

        SagaContext ctx = new SagaContext();
        ctx.setTransactionId("tx-dep-1001");
        ctx.setTransactionCode("DEP_1001");
        ctx.setTargetWalletId("wallet-123");
        ctx.setAmount(500_000L);
        ctx.setStatus("SUCCESS");
        ctx.setTargetBalanceAfter("5500000");

        when(sagaOrchestrator.deposit(eq("user-123"), eq("wallet-123"), eq(500_000L), eq("VND"), any()))
                .thenReturn(ctx);

        mockMvc.perform(post("/api/v1/payments/deposit")
                        .header("X-User-Id", "user-123")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.transactionCode").value("DEP_1001"))
                .andExpect(jsonPath("$.data.balanceAfter").value(5500000L))
                .andExpect(jsonPath("$.data.status").value("SUCCESS"));
    }

    @Test
    @DisplayName("Deposit qua alias /api/v1/wallets/deposit hoạt động bình thường")
    void deposit_WalletAlias_Success() throws Exception {
        DepositRequest request = DepositRequest.builder()
                .walletId("wallet-123")
                .amount(200_000L)
                .currency("VND")
                .build();

        SagaContext ctx = new SagaContext();
        ctx.setTransactionId("tx-dep-1002");
        ctx.setTransactionCode("DEP_1002");
        ctx.setTargetWalletId("wallet-123");
        ctx.setAmount(200_000L);
        ctx.setStatus("SUCCESS");
        ctx.setTargetBalanceAfter("5700000");

        when(sagaOrchestrator.deposit(eq("user-123"), eq("wallet-123"), eq(200_000L), eq("VND"), any()))
                .thenReturn(ctx);

        mockMvc.perform(post("/api/v1/wallets/deposit")
                        .header("X-User-Id", "user-123")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }

    @Test
    @DisplayName("Withdraw: Thiếu hoặc sai pinToken sẽ bị từ chối với mã lỗi INVALID_PIN_TOKEN")
    void withdraw_MissingOrInvalidPinToken_ShouldFail() throws Exception {
        WithdrawRequest request = WithdrawRequest.builder()
                .walletId("wallet-123")
                .bankAccountId("bank-acc-8888")
                .amount(300_000L)
                .currency("VND")
                .pinToken("invalid-pin-token")
                .build();

        when(pinTokenValidator.validatePinToken("invalid-pin-token", "user-123")).thenReturn(false);

        mockMvc.perform(post("/api/v1/payments/withdraw")
                        .header("X-User-Id", "user-123")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("INVALID_PIN_TOKEN"));

        verify(sagaOrchestrator, never()).withdraw(any(), any(), any(), any(), any(), any());
    }

    @Test
    @DisplayName("Withdraw: pinToken hợp lệ và số dư đủ sẽ trừ tiền ví và hoàn tất thành công")
    void withdraw_Success() throws Exception {
        WithdrawRequest request = WithdrawRequest.builder()
                .walletId("wallet-123")
                .bankAccountId("bank-acc-8888")
                .amount(300_000L)
                .currency("VND")
                .pinToken("valid-pin-token")
                .build();

        when(pinTokenValidator.validatePinToken("valid-pin-token", "user-123")).thenReturn(true);

        SagaContext ctx = new SagaContext();
        ctx.setTransactionId("tx-wd-2001");
        ctx.setTransactionCode("WDR_2001");
        ctx.setSourceWalletId("wallet-123");
        ctx.setAmount(300_000L);
        ctx.setStatus("SUCCESS");
        ctx.setSourceBalanceAfter("5200000");

        when(sagaOrchestrator.withdraw(eq("user-123"), eq("wallet-123"), eq(300_000L), eq("VND"), eq("bank-acc-8888"), any()))
                .thenReturn(ctx);

        mockMvc.perform(post("/api/v1/payments/withdraw")
                        .header("X-User-Id", "user-123")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.transactionCode").value("WDR_2001"))
                .andExpect(jsonPath("$.data.balanceAfter").value(5200000L))
                .andExpect(jsonPath("$.data.status").value("SUCCESS"));
    }
}

