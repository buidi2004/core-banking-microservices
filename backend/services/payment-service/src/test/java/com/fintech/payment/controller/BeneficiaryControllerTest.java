package com.fintech.payment.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fintech.payment.dto.BeneficiaryDto;
import com.fintech.payment.dto.CreateBeneficiaryRequest;
import com.fintech.payment.service.BeneficiaryService;
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

@WebMvcTest(BeneficiaryController.class)
@AutoConfigureMockMvc(addFilters = false)
class BeneficiaryControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private BeneficiaryService beneficiaryService;

    private final String userId = UUID.randomUUID().toString();

    @Test
    @DisplayName("GET /api/v1/beneficiaries: Lấy danh sách danh bạ người thụ hưởng")
    void getBeneficiaries_Success() throws Exception {
        BeneficiaryDto b = BeneficiaryDto.builder()
                .id(UUID.randomUUID().toString())
                .name("Trần Văn B")
                .nickname("Bạn Thân")
                .phoneNumber("0912345678")
                .bankCode("VCB")
                .accountNumber("001100223344")
                .build();

        when(beneficiaryService.getBeneficiaries(userId)).thenReturn(List.of(b));

        mockMvc.perform(get("/api/v1/beneficiaries")
                        .header("X-User-Id", userId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data[0].nickname").value("Bạn Thân"))
                .andExpect(jsonPath("$.data[0].phoneNumber").value("0912345678"));
    }

    @Test
    @DisplayName("POST /api/v1/beneficiaries: Lưu người thụ hưởng mới")
    void addBeneficiary_Success() throws Exception {
        CreateBeneficiaryRequest req = CreateBeneficiaryRequest.builder()
                .phoneNumber("0912345678")
                .name("Trần Văn B")
                .nickname("Bạn Thân")
                .build();

        BeneficiaryDto res = BeneficiaryDto.builder()
                .id(UUID.randomUUID().toString())
                .nickname("Bạn Thân")
                .phoneNumber("0912345678")
                .build();

        when(beneficiaryService.addBeneficiary(eq(userId), any(CreateBeneficiaryRequest.class))).thenReturn(res);

        mockMvc.perform(post("/api/v1/beneficiaries")
                        .header("X-User-Id", userId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.nickname").value("Bạn Thân"));
    }

    @Test
    @DisplayName("DELETE /api/v1/beneficiaries/{id}: Xóa người thụ hưởng")
    void deleteBeneficiary_Success() throws Exception {
        String id = UUID.randomUUID().toString();
        doNothing().when(beneficiaryService).deleteBeneficiary(userId, id);

        mockMvc.perform(delete("/api/v1/beneficiaries/" + id)
                        .header("X-User-Id", userId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }
}

