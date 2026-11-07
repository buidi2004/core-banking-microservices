package com.fintech.payment.controller;

import com.fintech.payment.dto.resilience.ResilienceDashboardResponse;
import com.fintech.payment.dto.resilience.ResilienceDashboardResponse.*;
import com.fintech.payment.service.ResilienceOpsService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.time.Instant;
import java.util.Map;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@ExtendWith(MockitoExtension.class)
class PaymentResilienceOpsControllerTest {

    @Mock
    private ResilienceOpsService resilienceOpsService;

    @InjectMocks
    private PaymentResilienceOpsController controller;

    @Test
    @DisplayName("GET /resilience: Staff can access resilience metrics")
    void shouldReturnResilienceMetricsForStaff() throws Exception {
        MockMvc mockMvc = MockMvcBuilders.standaloneSetup(controller).build();

        ResilienceDashboardResponse response = ResilienceDashboardResponse.builder()
                .overallStatus("HEALTHY")
                .timestamp(Instant.now())
                .database(DatabaseMetrics.builder().status("UP").build())
                .redis(RedisMetrics.builder().status("UP").build())
                .messaging(MessagingMetrics.builder().rabbitMqStatus("UP").kafkaStatus("UP").build())
                .grpc(GrpcMetrics.builder().status("UP").build())
                .microservices(Map.of())
                .build();

        when(resilienceOpsService.getResilienceDashboard()).thenReturn(response);

        mockMvc.perform(get("/api/v1/payments/ops/resilience")
                        .header("X-User-Role", "ROLE_TELLER"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.overallStatus").value("HEALTHY"))
                .andExpect(jsonPath("$.data.database.status").value("UP"));
    }

    @Test
    @DisplayName("GET /resilience: Non-staff is forbidden")
    void shouldReturnForbiddenForNonStaff() throws Exception {
        MockMvc mockMvc = MockMvcBuilders.standaloneSetup(controller).build();

        mockMvc.perform(get("/api/v1/payments/ops/resilience")
                        .header("X-User-Role", "ROLE_CUSTOMER"))
                .andExpect(status().isForbidden());
    }
}

