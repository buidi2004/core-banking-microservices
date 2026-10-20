package com.fintech.payment.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fintech.payment.dto.BankAccountDto;
import com.fintech.payment.dto.LinkBankAccountRequest;
import com.fintech.payment.service.BankAccountService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(BankAccountController.class)
@AutoConfigureMockMvc(addFilters = false)
class BankAccountControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private BankAccountService bankAccountService;

    private final String userId = UUID.randomUUID().toString();

    @Test
    @DisplayName("GET /api/v1/bank-accounts: Lấy danh sách tài khoản ngân hàng liên kết")
    void getAccounts_Success() throws Exception {
        BankAccountDto dto = BankAccountDto.builder()
                .id(UUID.randomUUID().toString())
                .bankCode("VCB")
                .bankName("Vietcombank")
                .shortName("VCB")
                .accountNumber("001100998877")
                .accountHolderName("NGUYEN VAN A")
                .isDefault(true)
                .isVerified(true)
                .build();

        when(bankAccountService.getUserBankAccounts(userId)).thenReturn(List.of(dto));

        mockMvc.perform(get("/api/v1/bank-accounts")
                        .header("X-User-Id", userId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data[0].bankCode").value("VCB"))
                .andExpect(jsonPath("$.data[0].accountNumber").value("001100998877"));
    }

    @Test
    @DisplayName("POST /api/v1/bank-accounts/link: Liên kết tài khoản ngân hàng")
    void linkAccount_Success() throws Exception {
        LinkBankAccountRequest req = LinkBankAccountRequest.builder()
                .bankCode("VCB")
                .accountNumber("001100998877")
                .accountHolderName("NGUYEN VAN A")
                .build();

        BankAccountDto dto = BankAccountDto.builder()
                .id(UUID.randomUUID().toString())
                .bankCode("VCB")
                .accountNumber("001100998877")
                .accountHolderName("NGUYEN VAN A")
                .isDefault(true)
                .build();

        when(bankAccountService.linkBankAccount(eq(userId), any(LinkBankAccountRequest.class))).thenReturn(dto);

        mockMvc.perform(post("/api/v1/bank-accounts/link")
                        .header("X-User-Id", userId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.accountNumber").value("001100998877"));
    }

    @Test
    @DisplayName("DELETE /api/v1/bank-accounts/{id}: Hủy liên kết tài khoản ngân hàng")
    void unlinkAccount_Success() throws Exception {
        String accId = UUID.randomUUID().toString();
        doNothing().when(bankAccountService).unlinkBankAccount(userId, accId);

        mockMvc.perform(delete("/api/v1/bank-accounts/" + accId)
                        .header("X-User-Id", userId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }
}

