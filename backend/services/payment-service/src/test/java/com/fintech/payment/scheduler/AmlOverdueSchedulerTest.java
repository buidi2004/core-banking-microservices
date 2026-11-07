package com.fintech.payment.scheduler;

import com.fintech.payment.domain.entity.AmlCase;
import com.fintech.payment.service.AmlCaseService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AmlOverdueSchedulerTest {

    @Mock
    private AmlCaseService caseService;

    @InjectMocks
    private AmlOverdueScheduler scheduler;

    @Test
    @DisplayName("checkOverdueCases logs warning for each overdue AML case")
    void checkOverdueCases_success() {
        AmlCase overdueCase = AmlCase.builder()
                .id(UUID.randomUUID())
                .transactionId("tx-123")
                .customerId("cust-456")
                .status(AmlCase.OPEN)
                .slaDueAt(Instant.now().minusSeconds(3600))
                .build();

        when(caseService.findOverdueCases()).thenReturn(List.of(overdueCase));

        assertDoesNotThrow(() -> scheduler.checkOverdueCases());

        verify(caseService, times(1)).findOverdueCases();
    }

    @Test
    @DisplayName("checkOverdueCases catches and handles exceptions gracefully")
    void checkOverdueCases_handlesExceptionGracefully() {
        when(caseService.findOverdueCases()).thenThrow(new RuntimeException("Database error"));

        assertDoesNotThrow(() -> scheduler.checkOverdueCases());

        verify(caseService, times(1)).findOverdueCases();
    }
}
