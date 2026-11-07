package com.fintech.payment.controller;

import com.fintech.payment.dto.eod.PaymentEodGateResponse;
import com.fintech.payment.service.PaymentEodOpsService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.util.List;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@ExtendWith(MockitoExtension.class)
class PaymentEodOpsControllerTest {

    @Mock
    private PaymentEodOpsService paymentEodOpsService;

    @InjectMocks
    private PaymentEodOpsController controller;

    private MockMvc mockMvc;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(controller).build();
    }

    @Test
    void checkEodGate_whenManager_shouldReturnOk() throws Exception {
        PaymentEodGateResponse response = PaymentEodGateResponse.builder()
                .canCloseEod(true)
                .gateStatus("CLEARED")
                .pendingMakerCheckerTotal(0)
                .pendingOutboxCount(0)
                .blockingReasons(List.of())
                .build();

        when(paymentEodOpsService.checkEodGate()).thenReturn(response);

        mockMvc.perform(get("/api/v1/payments/ops/eod-gate")
                        .header("X-User-Role", "ROLE_MANAGER"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.gateStatus").value("CLEARED"))
                .andExpect(jsonPath("$.data.canCloseEod").value(true));
    }

    @Test
    void checkEodGate_whenNotManager_shouldReturnForbidden() throws Exception {
        mockMvc.perform(get("/api/v1/payments/ops/eod-gate")
                        .header("X-User-Role", "ROLE_TELLER"))
                .andExpect(status().isForbidden());
    }

    @Test
    void drainOutbox_whenManager_shouldReturnOk() throws Exception {
        when(paymentEodOpsService.drainOutbox()).thenReturn(0L);

        mockMvc.perform(post("/api/v1/payments/ops/outbox/drain")
                        .header("X-User-Role", "ROLE_ADMIN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.drained").value(true))
                .andExpect(jsonPath("$.data.remainingPending").value(0));
    }
}
