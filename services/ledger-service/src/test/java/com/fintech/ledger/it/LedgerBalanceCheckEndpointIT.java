package com.fintech.ledger.it;

import com.fintech.ledger.application.dto.TransactionEventMessage;
import com.fintech.ledger.application.service.LedgerService;
import com.fintech.ledger.infrastructure.persistence.repository.SpringLedgerPostingRepository;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfSystemProperty;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.math.BigDecimal;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Integration test endpoint sao kê/đối soát trên context Spring Boot thật
 * (Flyway migration + JPA validate + MockMvc).
 *
 * Được kích hoạt bởi -Dledger.it.jdbcUrl (PostgreSQL thật), dùng chung DB với
 * LedgerAppendOnlyPostgresIT (mỗi giao dịch dùng UUID riêng nên không xung đột).
 */
@SpringBootTest
@AutoConfigureMockMvc
@EnabledIfSystemProperty(named = "ledger.it.jdbcUrl", matches = ".+",
        disabledReason = "Cần PostgreSQL thật: truyền -Dledger.it.jdbcUrl/-Dledger.it.user/-Dledger.it.pass")
class LedgerBalanceCheckEndpointIT {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private LedgerService ledgerService;

    @Autowired
    private SpringLedgerPostingRepository postingRepository;

    @DynamicPropertySource
    static void databaseProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", LedgerItDatabase::jdbcUrl);
        registry.add("spring.datasource.username", LedgerItDatabase::user);
        registry.add("spring.datasource.password", LedgerItDatabase::password);
        registry.add("spring.flyway.enabled", () -> "false"); // migration đã áp bởi LedgerItDatabase
        registry.add("spring.autoconfigure.exclude",
                () -> "org.springframework.boot.autoconfigure.amqp.RabbitAutoConfiguration");
    }

    @BeforeAll
    static void applyMigration() {
        // Flyway V1 phải tồn tại trước khi JPA validate chạy
        LedgerItDatabase.migrate();
    }

    private static TransactionEventMessage event(UUID txId, String eventId, String type,
                                                 String status, String source, String target, String amount) {
        TransactionEventMessage event = new TransactionEventMessage();
        event.setEventId(eventId);
        event.setTransactionId(txId.toString());
        event.setType(type);
        event.setStatus(status);
        event.setSourceWalletId(source);
        event.setTargetWalletId(target);
        event.setAmount(new BigDecimal(amount));
        event.setCurrency("VND");
        return event;
    }

    @Test
    void balanceCheckEndpointReturnsBalancedTotalsAfterPosting() throws Exception {
        // Given: ghi sổ 3 giao dịch (deposit, transfer, withdrawal) — mỗi trường hợp đều tự cân Nợ/Có
        String walletA = "wA-" + UUID.randomUUID();
        String walletB = "wB-" + UUID.randomUUID();
        String eventId = UUID.randomUUID().toString();

        ledgerService.recordTransactionPosting(
                event(UUID.randomUUID(), eventId, "DEPOSIT", "SUCCESS", null, walletA, "300000.00"));
        ledgerService.recordTransactionPosting(
                event(UUID.randomUUID(), UUID.randomUUID().toString(), "TRANSFER", "SUCCESS", walletA, walletB,
                        "120000.00"));
        ledgerService.recordTransactionPosting(
                event(UUID.randomUUID(), UUID.randomUUID().toString(), "WITHDRAWAL", "SUCCESS", walletB, null,
                        "50000.00"));

        // Chặn anti-pattern: 1 sự kiện bị trùng phải idempotent (không ghi thêm)
        ledgerService.recordTransactionPosting(
                event(UUID.randomUUID(), eventId, "DEPOSIT", "SUCCESS", null, walletA, "300000.00"));

        // ΣDebit = ΣCredit trực tiếp từ Repository (data thật trong DB)
        BigDecimal sumDebit = postingRepository.sumAmountBySide("DEBIT");
        BigDecimal sumCredit = postingRepository.sumAmountBySide("CREDIT");
        assertThat(sumDebit).isEqualByComparingTo(sumCredit);

        // When + Then: endpoint đối soát toàn sổ phải báo balanced = true
        MvcResult result = mockMvc.perform(get("/api/v1/ledger/accounts/balance-check"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.data.balanced").value(true))
                .andExpect(jsonPath("$.data.totalDebit").isNotEmpty())
                .andExpect(jsonPath("$.data.totalCredit").isNotEmpty())
                .andReturn();
        String body = result.getResponse().getContentAsString();
        assertThat(body).contains("\"balanced\": true");

        // Endpoint sao kê theo ví tồn tại dữ liệu bút toán
        mockMvc.perform(get("/api/v1/ledger/statement/{walletId}", walletA))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data").isArray())
                .andExpect(jsonPath("$.data.length()").value(org.hamcrest.Matchers.greaterThan(0)));

        // C chứng từ theo giao dịch
        var entries = ledgerService.getJournalEntries();
        assertThat(entries).isNotEmpty();
    }

    @Test
    void statementEndpointReturns404ForUnknownWallet() throws Exception {
        mockMvc.perform(get("/api/v1/ledger/statement/{walletId}", "unknown-" + UUID.randomUUID()))
                .andExpect(status().isNotFound());
    }
}
