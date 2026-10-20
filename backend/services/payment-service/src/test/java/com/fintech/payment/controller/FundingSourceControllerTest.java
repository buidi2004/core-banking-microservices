package com.fintech.payment.controller;

import com.fintech.payment.dto.FundingSourceDto;
import com.fintech.payment.service.FundingSourceService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(FundingSourceController.class)
@AutoConfigureMockMvc(addFilters = false)
class FundingSourceControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private FundingSourceService fundingSourceService;

    private final String userId = UUID.randomUUID().toString();

    @Test
    @DisplayName("GET /api/v1/funding-sources: Lấy danh sách nguồn tiền thanh toán")
    void getFundingSources_Success() throws Exception {
        FundingSourceDto source = FundingSourceDto.builder()
                .id(UUID.randomUUID().toString())
                .sourceType("WALLET")
                .sourceRefId(UUID.randomUUID().toString())
                .title("Ví chính Sen Hồng Pay")
                .subtitle("Số dư khả dụng")
                .balanceOrLimit(new BigDecimal("5000000"))
                .active(true)
                .priority(1)
                .build();

        when(fundingSourceService.getFundingSources(userId)).thenReturn(List.of(source));

        mockMvc.perform(get("/api/v1/funding-sources")
                        .header("X-User-Id", userId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data[0].sourceType").value("WALLET"));
    }
}

