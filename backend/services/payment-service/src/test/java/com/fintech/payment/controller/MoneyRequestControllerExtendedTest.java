package com.fintech.payment.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fintech.payment.domain.entity.MoneyRequest;
import com.fintech.payment.repository.MoneyRequestRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.web.servlet.MockMvc;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(MoneyRequestController.class)
@AutoConfigureMockMvc(addFilters = false)
class MoneyRequestControllerExtendedTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private MoneyRequestRepository moneyRequestRepository;

    private final String userId = UUID.randomUUID().toString();

    @Test
    @DisplayName("GET /api/v1/payments/money-requests/{id}: Xem chi tiết yêu cầu tiền")
    void getDetail_Success() throws Exception {
        String id = UUID.randomUUID().toString();
        MoneyRequest mr = MoneyRequest.builder()
                .id(id)
                .requesterId(userId)
                .targetUserId("user-target")
                .amount(50000L)
                .status("PENDING")
                .note("Cà phê sáng")
                .expiresAt(Instant.now().plusSeconds(3600))
                .build();

        when(moneyRequestRepository.findById(id)).thenReturn(Optional.of(mr));

        mockMvc.perform(get("/api/v1/payments/money-requests/" + id))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.id").value(id))
                .andExpect(jsonPath("$.data.amount").value(50000));
    }

    @Test
    @DisplayName("POST /api/v1/payments/money-requests/{id}/cancel: Người gửi hủy yêu cầu tiền")
    void cancel_Success() throws Exception {
        String id = UUID.randomUUID().toString();
        MoneyRequest mr = MoneyRequest.builder()
                .id(id)
                .requesterId(userId)
                .targetUserId("user-target")
                .amount(50000L)
                .status("PENDING")
                .expiresAt(Instant.now().plusSeconds(3600))
                .build();

        when(moneyRequestRepository.findById(id)).thenReturn(Optional.of(mr));
        when(moneyRequestRepository.save(any(MoneyRequest.class))).thenAnswer(invocation -> invocation.getArgument(0));

        mockMvc.perform(post("/api/v1/payments/money-requests/" + id + "/cancel")
                        .header("X-User-Id", userId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.status").value("CANCELLED"));
    }

    @Test
    @DisplayName("GET /api/v1/payments/money-requests/received: Danh sách yêu cầu tiền nhận được")
    void getReceived_Success() throws Exception {
        MoneyRequest mr = MoneyRequest.builder()
                .id(UUID.randomUUID().toString())
                .requesterId("user-requester")
                .targetUserId(userId)
                .amount(80000L)
                .status("PENDING")
                .build();

        when(moneyRequestRepository.findByTargetUserId(userId)).thenReturn(List.of(mr));

        mockMvc.perform(get("/api/v1/payments/money-requests/received")
                        .header("X-User-Id", userId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data[0].amount").value(80000));
    }

    @Test
    @DisplayName("GET /api/v1/payments/money-requests/sent: Danh sách yêu cầu tiền đã gửi đi")
    void getSent_Success() throws Exception {
        MoneyRequest mr = MoneyRequest.builder()
                .id(UUID.randomUUID().toString())
                .requesterId(userId)
                .targetUserId("user-target")
                .amount(120000L)
                .status("PENDING")
                .build();

        when(moneyRequestRepository.findByRequesterId(userId)).thenReturn(List.of(mr));

        mockMvc.perform(get("/api/v1/payments/money-requests/sent")
                        .header("X-User-Id", userId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data[0].amount").value(120000));
    }
}

