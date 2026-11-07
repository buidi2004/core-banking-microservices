package com.fintech.ledger.presentation.controller;

import com.fintech.ledger.application.service.LedgerService;
import com.fintech.ledger.infrastructure.persistence.entity.EodBatchJpaEntity;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

import static org.mockito.ArgumentMatchers.anyBoolean;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@ExtendWith(MockitoExtension.class)
class LedgerControllerTest {

    @Mock
    private LedgerService ledgerService;

    @InjectMocks
    private LedgerController controller;

    private MockMvc mockMvc;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(controller).build();
    }

    @Test
    void getEodReadiness_whenManager_shouldReturnOk() throws Exception {
        LedgerService.EodReadinessReport report = new LedgerService.EodReadinessReport(
                true, "READY", true, true, 0, 0, List.of(), List.of(), Instant.now()
        );
        when(ledgerService.getEodReadiness()).thenReturn(report);

        mockMvc.perform(get("/api/v1/ledger/admin/eod/readiness")
                        .header("X-User-Role", "ROLE_MANAGER"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.readyToClose").value(true))
                .andExpect(jsonPath("$.data.overallStatus").value("READY"));
    }

    @Test
    void getEodReadiness_whenNotManager_shouldReturnForbidden() throws Exception {
        mockMvc.perform(get("/api/v1/ledger/admin/eod/readiness")
                        .header("X-User-Role", "ROLE_TELLER"))
                .andExpect(status().isForbidden());
    }

    @Test
    void getAccountChecksumReport_whenManager_shouldReturnOk() throws Exception {
        LedgerService.AccountChecksumReport report = new LedgerService.AccountChecksumReport(
                10, 10, 0, List.of(), true
        );
        when(ledgerService.verifyAccountChecksums()).thenReturn(report);

        mockMvc.perform(get("/api/v1/ledger/admin/eod/checksum")
                        .header("X-User-Role", "ROLE_MANAGER"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.allChecksumsValid").value(true))
                .andExpect(jsonPath("$.data.validAccountsCount").value(10));
    }

    @Test
    void closeEndOfDay_whenManager_shouldReturnOk() throws Exception {
        LedgerService.EndOfDayResult result = new LedgerService.EndOfDayResult(
                "EOD-2026-11-07-12345", "2026-11-07", "2026-11-08",
                new BigDecimal("1000.00"), new BigDecimal("1000.00"), BigDecimal.ZERO,
                true, 5, 10, "SUCCESS", Instant.now(), "Thành công"
        );
        when(ledgerService.closeEndOfDay(anyString(), anyBoolean(), anyString())).thenReturn(result);

        mockMvc.perform(post("/api/v1/ledger/admin/eod/close-day")
                        .header("X-User-Id", "manager1")
                        .header("X-User-Role", "ROLE_MANAGER")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"force\":false,\"notes\":\"Manual close\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.eodBatchId").value("EOD-2026-11-07-12345"))
                .andExpect(jsonPath("$.data.status").value("SUCCESS"));
    }

    @Test
    void getEodHistory_whenManager_shouldReturnList() throws Exception {
        EodBatchJpaEntity batch = EodBatchJpaEntity.builder()
                .batchId("EOD-2026-11-07-12345")
                .valueDate(LocalDate.now())
                .nextValueDate(LocalDate.now().plusDays(1))
                .totalDebit(new BigDecimal("1000.00"))
                .totalCredit(new BigDecimal("1000.00"))
                .delta(BigDecimal.ZERO)
                .isBalanced(true)
                .totalEntries(5)
                .totalPostings(10)
                .checksumPassed(true)
                .status("SUCCESS")
                .executedBy("manager1")
                .createdAt(Instant.now())
                .build();
        when(ledgerService.getEodHistory(10)).thenReturn(List.of(batch));

        mockMvc.perform(get("/api/v1/ledger/admin/eod/history")
                        .header("X-User-Role", "ROLE_MANAGER")
                        .param("limit", "10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data").isArray())
                .andExpect(jsonPath("$.data[0].batchId").value("EOD-2026-11-07-12345"));
    }

    @Test
    void exportJournalEntriesCsv_whenTellerOrManager_shouldReturnCsv() throws Exception {
        byte[] csv = "Mã chứng từ,Mã giao dịch\n1,tx1".getBytes(StandardCharsets.UTF_8);
        when(ledgerService.exportJournalEntriesCsv()).thenReturn(csv);

        mockMvc.perform(get("/api/v1/ledger/reports/journal-entries/export")
                        .header("X-User-Role", "ROLE_TELLER"))
                .andExpect(status().isOk())
                .andExpect(header().string("Content-Type", "text/csv; charset=UTF-8"))
                .andExpect(header().string("Content-Disposition", org.hamcrest.Matchers.containsString("journal-entries-")))
                .andExpect(content().bytes(csv));
    }

    @Test
    void exportAccountsCsv_whenTellerOrManager_shouldReturnCsv() throws Exception {
        byte[] csv = "Mã tài khoản,Số hiệu\n1,1011".getBytes(StandardCharsets.UTF_8);
        when(ledgerService.exportAccountsCsv()).thenReturn(csv);

        mockMvc.perform(get("/api/v1/ledger/reports/accounts/export")
                        .header("X-User-Role", "ROLE_MANAGER"))
                .andExpect(status().isOk())
                .andExpect(header().string("Content-Type", "text/csv; charset=UTF-8"))
                .andExpect(header().string("Content-Disposition", org.hamcrest.Matchers.containsString("chart-of-accounts-")))
                .andExpect(content().bytes(csv));
    }

    @Test
    void exportEodHistoryCsv_whenTellerOrManager_shouldReturnCsv() throws Exception {
        byte[] csv = "Mã lô EOD,Ngày giá trị\n1,2026-11-07".getBytes(StandardCharsets.UTF_8);
        when(ledgerService.exportEodBatchesCsv()).thenReturn(csv);

        mockMvc.perform(get("/api/v1/ledger/reports/eod-history/export")
                        .header("X-User-Role", "ROLE_TELLER"))
                .andExpect(status().isOk())
                .andExpect(header().string("Content-Type", "text/csv; charset=UTF-8"))
                .andExpect(header().string("Content-Disposition", org.hamcrest.Matchers.containsString("eod-history-")))
                .andExpect(content().bytes(csv));
    }

    @Test
    void exportReports_whenNoStaffRole_shouldReturnForbidden() throws Exception {
        mockMvc.perform(get("/api/v1/ledger/reports/journal-entries/export")
                        .header("X-User-Role", "ROLE_CUSTOMER"))
                .andExpect(status().isForbidden());
    }
}

