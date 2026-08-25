package com.fintech.wallet.presentation.controller;

import com.fintech.wallet.domain.model.FundingSource;
import com.fintech.wallet.domain.model.FundingSourceType;
import com.fintech.wallet.domain.port.in.FundingSourceUseCase;
import com.fintech.wallet.presentation.request.LinkFundingSourceRequest;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
public class FundingSourceControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private FundingSourceUseCase fundingSourceUseCase;

    @Test
    @WithMockUser(username = "user-1")
    void testGetFundingSources() throws Exception {
        FundingSource source = FundingSource.create("user-1", FundingSourceType.BANK_ACCOUNT, "VCB", "1234567890");
        when(fundingSourceUseCase.getFundingSources("user-1")).thenReturn(List.of(source));

        mockMvc.perform(get("/api/v1/funding-sources"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].provider").value("VCB"))
                .andExpect(jsonPath("$.data[0].maskedNumber").value("12****90"));
    }

    @Test
    @WithMockUser(username = "user-1")
    void testLinkFundingSource() throws Exception {
        LinkFundingSourceRequest req = new LinkFundingSourceRequest(FundingSourceType.CREDIT_CARD, "VISA", "4970123456789012", "NAME", "12/26", "123");
        FundingSource source = FundingSource.create("user-1", FundingSourceType.CREDIT_CARD, "VISA", "4970123456789012");
        
        when(fundingSourceUseCase.linkFundingSource(eq("user-1"), any(LinkFundingSourceRequest.class))).thenReturn(source);

        mockMvc.perform(post("/api/v1/funding-sources/link")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.maskedNumber").value("4970 **** **** 9012"));
    }

    @Test
    @WithMockUser(username = "user-1")
    void testUnlinkFundingSource() throws Exception {
        doNothing().when(fundingSourceUseCase).unlinkFundingSource("user-1", "fs-1");

        mockMvc.perform(delete("/api/v1/funding-sources/fs-1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Hủy liên kết thành công"));
    }
}
