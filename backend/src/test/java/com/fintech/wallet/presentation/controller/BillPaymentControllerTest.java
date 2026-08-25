package com.fintech.wallet.presentation.controller;

import com.fintech.wallet.domain.model.Bill;
import com.fintech.wallet.domain.model.BillType;
import com.fintech.wallet.domain.model.Money;
import com.fintech.wallet.domain.model.Transaction;
import com.fintech.wallet.domain.model.TransactionStatus;
import com.fintech.wallet.domain.model.TransactionType;
import com.fintech.wallet.domain.port.in.BillPaymentUseCase;
import com.fintech.wallet.presentation.request.PayBillRequest;
import com.fintech.wallet.presentation.request.TopupRequest;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.time.Instant;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
public class BillPaymentControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private BillPaymentUseCase billPaymentUseCase;

    @Test
    @WithMockUser(username = "user-1")
    void testLookupBill() throws Exception {
        Bill bill = new Bill("b1", BillType.ELECTRICITY, "PE123", "EVN", "TEST", new BigDecimal("50000"), "10/2026", false);
        when(billPaymentUseCase.queryBill(BillType.ELECTRICITY, "PE123")).thenReturn(bill);

        mockMvc.perform(get("/api/v1/bills/lookup")
                .param("type", "ELECTRICITY")
                .param("customerCode", "PE123"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.customerCode").value("PE123"))
                .andExpect(jsonPath("$.data.amount").value(50000));
    }

    @Test
    @WithMockUser(username = "user-1")
    void testPayBill() throws Exception {
        PayBillRequest req = new PayBillRequest();
        req.setRequestId("req-1");
        req.setWalletId("w1");
        req.setBillId("b1");
        req.setAmount(new BigDecimal("50000"));
        req.setCurrency("VND");

        Transaction tx = new Transaction("tx-1", "req-1", "w1", "provider", new Money(new BigDecimal("50000"), "VND"), TransactionType.BILL_PAYMENT, TransactionStatus.SUCCESS, Instant.now());
        
        when(billPaymentUseCase.payBill(eq("req-1"), eq("user-1"), eq("w1"), eq("b1"), any())).thenReturn(tx);

        mockMvc.perform(post("/api/v1/bills/pay")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value("SUCCESS"));
    }

    @Test
    @WithMockUser(username = "user-1")
    void testTopupPhone() throws Exception {
        TopupRequest req = new TopupRequest();
        req.setRequestId("req-2");
        req.setWalletId("w1");
        req.setPhoneNumber("0988111222");
        req.setAmount(new BigDecimal("100000"));
        req.setCurrency("VND");

        Transaction tx = new Transaction("tx-2", "req-2", "w1", "provider", new Money(new BigDecimal("100000"), "VND"), TransactionType.BILL_PAYMENT, TransactionStatus.SUCCESS, Instant.now());
        
        when(billPaymentUseCase.topupPhone(eq("req-2"), eq("user-1"), eq("w1"), eq("0988111222"), any())).thenReturn(tx);

        mockMvc.perform(post("/api/v1/bills/topup")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value("SUCCESS"));
    }
}
