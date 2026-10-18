package com.fintech.ledger;

import com.fintech.ledger.application.dto.TransactionEventMessage;
import com.fintech.ledger.application.service.LedgerService;
import com.fintech.ledger.domain.exception.LedgerUnbalancedException;
import com.fintech.ledger.domain.model.AccountType;
import com.fintech.ledger.domain.model.JournalEntry;
import com.fintech.ledger.domain.model.JournalEntryStatus;
import com.fintech.ledger.domain.model.LedgerAccount;
import com.fintech.ledger.domain.model.LedgerPosting;
import com.fintech.ledger.domain.model.PostingSide;
import com.fintech.ledger.application.kafka.KafkaEventEnvelope;
import com.fintech.ledger.application.kafka.KafkaLedgerEventTranslator;
import com.fintech.ledger.it.InMemoryLedgerPersistencePort;
import com.fintech.ledger.presentation.controller.LedgerController;
import com.fintech.ledger.presentation.controller.LedgerQueryController;
import com.fintech.ledger.presentation.dto.ApiResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.ResponseEntity;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Kịch bản kiểm thử Sổ cái kép (Double-Entry General Ledger) cho nghiệp vụ Nạp tiền mặt tại quầy:
 * - Hạch toán Nợ TK 1011 (Quỹ tiền mặt mặt đất - ASSET) / Có TK 4211 (Tiền gửi ví khách hàng - LIABILITY)
 * - Ràng buộc bất biến Debit = Credit (Delta = 0.00 VND)
 * - Bảo toàn tính Append-Only và cơ chế Idempotency chống ghi đúp
 * - Cơ chế bút toán bù Reversal (đảo chiều Có 1011 / Nợ 4211)
 */
@DisplayName("Agent 5: Ledger Service - Kịch bản Hạch toán Sổ cái kép Nạp tiền mặt (Nợ 1011 / Có 4211)")
class LedgerCashDepositTest {

    private static final String CASH_ACCOUNT_CODE = "1011:BR_Q1";
    private static final String CASH_ACCOUNT_NAME = "CASH_ON_HAND:BR_Q1";
    private static final String CUSTOMER_ACCOUNT_CODE = "4211:BOB_TRAN";
    private static final String CUSTOMER_ACCOUNT_NAME = "CUSTOMER_DEPOSITS:bob";

    private InMemoryLedgerPersistencePort persistencePort;
    private LedgerService ledgerService;

    private LedgerAccount account1011CashOnHand;
    private LedgerAccount account4211CustomerDeposits;

    @BeforeEach
    void setUp() {
        persistencePort = new InMemoryLedgerPersistencePort();
        ledgerService = new LedgerService(persistencePort);

        // TK 1011: Quỹ tiền mặt mặt đất tại Chi nhánh Quận 1 (Tài sản - ASSET)
        account1011CashOnHand = LedgerAccount.create(
                CASH_ACCOUNT_CODE,
                CASH_ACCOUNT_NAME,
                AccountType.ASSET,
                "VND"
        );
        persistencePort.saveAccount(account1011CashOnHand);

        // TK 4211: Tiền gửi ví khách hàng Bob Tran (Nguồn vốn / Nợ phải trả - LIABILITY)
        account4211CustomerDeposits = LedgerAccount.create(
                CUSTOMER_ACCOUNT_CODE,
                CUSTOMER_ACCOUNT_NAME,
                AccountType.LIABILITY,
                "VND"
        );
        persistencePort.saveAccount(account4211CustomerDeposits);
    }

    @Test
    @DisplayName("Kịch bản 1: Hạch toán kép nạp tiền mặt 200,000,000 VND (Nợ 1011 / Có 4211) - Delta = 0.00 VND")
    void shouldSuccessfullyPostCashDeposit_Debit1011_Credit4211() {
        // Arrange: Chuẩn bị 2 dòng bút toán nạp tiền mặt tại quầy 200M VND
        BigDecimal depositAmount = new BigDecimal("200000000.00");
        String transactionId = "DEP-REAL-200M-002";
        String eventId = "REF_DEP_200M_002";

        // NỢ (Debit) TK 1011 - Quỹ tiền mặt (Tài sản tăng)
        LedgerPosting debitPosting = new LedgerPosting(
                UUID.randomUUID().toString(),
                null,
                account1011CashOnHand.getId(),
                PostingSide.DEBIT,
                depositAmount,
                "VND"
        );

        // CÓ (Credit) TK 4211 - Khách hàng (Nghĩa vụ nợ tăng)
        LedgerPosting creditPosting = new LedgerPosting(
                UUID.randomUUID().toString(),
                null,
                account4211CustomerDeposits.getId(),
                PostingSide.CREDIT,
                depositAmount,
                "VND"
        );

        // Act: Tạo chứng từ gốc ghi sổ (POSTED)
        JournalEntry journalEntry = JournalEntry.createOriginal(
                transactionId,
                "Nạp tiền mặt tại quầy 200,000,000 VND vào ví Bob Tran",
                eventId,
                List.of(debitPosting, creditPosting)
        );
        JournalEntry savedEntry = persistencePort.saveJournalEntry(journalEntry);

        // Assert: Kiểm tra định lý bảo toàn tiền tệ & cấu trúc chứng từ kép
        assertThat(savedEntry).isNotNull();
        assertThat(savedEntry.getStatus()).isEqualTo(JournalEntryStatus.POSTED);
        assertThat(savedEntry.getTransactionId()).isEqualTo(transactionId);
        assertThat(savedEntry.getReferenceNumber()).isEqualTo(eventId);
        assertThat(savedEntry.getPostings()).hasSize(2);

        // Tính tổng Nợ và tổng Có
        BigDecimal totalDebit = sumSide(savedEntry, PostingSide.DEBIT);
        BigDecimal totalCredit = sumSide(savedEntry, PostingSide.CREDIT);
        BigDecimal delta = totalDebit.subtract(totalCredit);

        // Bất biến cốt lõi: Tổng Nợ = Tổng Có, Delta = 0
        assertThat(totalDebit).isEqualByComparingTo(depositAmount);
        assertThat(totalCredit).isEqualByComparingTo(depositAmount);
        assertThat(delta).isEqualByComparingTo(BigDecimal.ZERO);

        // Xác nhận dòng Nợ thuộc TK 1011 và dòng Có thuộc TK 4211
        LedgerPosting actualDebit = savedEntry.getPostings().stream()
                .filter(p -> p.getSide() == PostingSide.DEBIT)
                .findFirst()
                .orElseThrow();
        LedgerPosting actualCredit = savedEntry.getPostings().stream()
                .filter(p -> p.getSide() == PostingSide.CREDIT)
                .findFirst()
                .orElseThrow();

        assertThat(actualDebit.getAccountId()).isEqualTo(account1011CashOnHand.getId());
        assertThat(actualCredit.getAccountId()).isEqualTo(account4211CustomerDeposits.getId());
        assertThat(actualDebit.getJournalEntryId()).isEqualTo(savedEntry.getId());
        assertThat(actualCredit.getJournalEntryId()).isEqualTo(savedEntry.getId());
    }

    @Test
    @DisplayName("Kịch bản 2: Xác nhận tính chất số dư chuẩn (Normal Balance) của TK 1011 và TK 4211")
    void shouldVerifyAccountTypesAndNormalBalances() {
        // TK 1011 (Quỹ tiền mặt) thuộc loại ASSET -> số dư thông thường bên Nợ (Debit normal)
        assertThat(account1011CashOnHand.getType()).isEqualTo(AccountType.ASSET);
        assertThat(account1011CashOnHand.getType().isDebitNormal()).isTrue();
        assertThat(account1011CashOnHand.getCode()).isEqualTo("1011:BR_Q1");

        // TK 4211 (Tiền gửi ví) thuộc loại LIABILITY -> số dư thông thường bên Có (Credit normal)
        assertThat(account4211CustomerDeposits.getType()).isEqualTo(AccountType.LIABILITY);
        assertThat(account4211CustomerDeposits.getType().isDebitNormal()).isFalse();
        assertThat(account4211CustomerDeposits.getCode()).isEqualTo("4211:BOB_TRAN");
    }

    @Test
    @DisplayName("Kịch bản 3: Bảo toàn sổ cái - Chặn đứng hạch toán mất cân bằng (Unbalanced Entry)")
    void shouldRejectUnbalancedCashDepositEntry() {
        // Nợ 1011 = 200,000,000 VND nhưng Có 4211 = 150,000,000 VND (lệch 50M)
        LedgerPosting debit = new LedgerPosting(null, null, account1011CashOnHand.getId(),
                PostingSide.DEBIT, new BigDecimal("200000000.00"), "VND");
        LedgerPosting credit = new LedgerPosting(null, null, account4211CustomerDeposits.getId(),
                PostingSide.CREDIT, new BigDecimal("150000000.00"), "VND");

        assertThatThrownBy(() -> JournalEntry.createOriginal(
                "tx-unbalanced",
                "Nạp tiền mặt lệch Nợ/Có",
                "ref-unbalanced",
                List.of(debit, credit)
        ))
                .isInstanceOf(LedgerUnbalancedException.class)
                .hasMessageContaining("Unbalanced journal entry");
    }

    @Test
    @DisplayName("Kịch bản 4: Chặn đứng chứng từ chỉ có 1 vế bút toán đơn (Single-Sided Posting)")
    void shouldRejectSingleSidedPosting() {
        LedgerPosting debitOnly = new LedgerPosting(null, null, account1011CashOnHand.getId(),
                PostingSide.DEBIT, new BigDecimal("200000000.00"), "VND");

        assertThatThrownBy(() -> JournalEntry.createOriginal(
                "tx-single-side",
                "Bút toán đơn không hợp lệ",
                "ref-single",
                List.of(debitOnly)
        ))
                .isInstanceOf(LedgerUnbalancedException.class)
                .hasMessageContaining("at least two postings");
    }

    @Test
    @DisplayName("Kịch bản 5: Chặn đứng giao dịch nạp số tiền <= 0 (Zero or Negative Amount)")
    void shouldRejectZeroOrNegativeAmount() {
        assertThatThrownBy(() -> new LedgerPosting(null, null, account1011CashOnHand.getId(),
                PostingSide.DEBIT, BigDecimal.ZERO, "VND"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("strictly positive");

        assertThatThrownBy(() -> new LedgerPosting(null, null, account1011CashOnHand.getId(),
                PostingSide.DEBIT, new BigDecimal("-50000.00"), "VND"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("strictly positive");
    }

    @Test
    @DisplayName("Kịch bản 6: Chặn đứng hạch toán không cùng loại tiền tệ (Currency Mismatch)")
    void shouldRejectCurrencyMismatchBetweenDebitAndCredit() {
        LedgerPosting debitVnd = new LedgerPosting(null, null, account1011CashOnHand.getId(),
                PostingSide.DEBIT, new BigDecimal("200000000.00"), "VND");
        LedgerPosting creditUsd = new LedgerPosting(null, null, account4211CustomerDeposits.getId(),
                PostingSide.CREDIT, new BigDecimal("200000000.00"), "USD");

        assertThatThrownBy(() -> JournalEntry.createOriginal(
                "tx-mismatch-curr",
                "Xung đột tiền tệ",
                "ref-curr",
                List.of(debitVnd, creditUsd)
        ))
                .isInstanceOf(LedgerUnbalancedException.class)
                .hasMessageContaining("mixed currencies");
    }

    @Test
    @DisplayName("Kịch bản 7: Bút toán bù Reversal - Đảo chiều Có 1011 / Nợ 4211 bảo toàn chứng từ gốc")
    void shouldCompensateAndReverseCashDepositCorrectly() {
        BigDecimal amount = new BigDecimal("200000000.00");
        String txId = "DEP-REAL-200M-REVERSE";
        String originalRef = "REF_ORIGINAL_200M";

        // Ghi chứng từ nạp tiền gốc
        JournalEntry original = JournalEntry.createOriginal(
                txId,
                "Thu tiền mặt gốc",
                originalRef,
                List.of(
                        new LedgerPosting(null, null, account1011CashOnHand.getId(), PostingSide.DEBIT, amount, "VND"),
                        new LedgerPosting(null, null, account4211CustomerDeposits.getId(), PostingSide.CREDIT, amount, "VND")
                )
        );
        persistencePort.saveJournalEntry(original);

        // Act: Sinh bút toán bù đảo chiều
        List<LedgerPosting> compensatingPostings = original.compensatePostings();
        JournalEntry reversal = JournalEntry.createReversal(
                txId,
                "Hoàn tiền nạp mặt tại quầy cho khách",
                "REF_REVERSAL_200M",
                original.getId(),
                compensatingPostings
        );
        JournalEntry savedReversal = persistencePort.saveJournalEntry(reversal);

        // Assert: Bút toán bù cân bằng và đảo đúng bên
        assertThat(savedReversal.getStatus()).isEqualTo(JournalEntryStatus.REVERSAL);
        assertThat(savedReversal.getReversalOf()).isEqualTo(original.getId());

        BigDecimal revDebit = sumSide(savedReversal, PostingSide.DEBIT);
        BigDecimal revCredit = sumSide(savedReversal, PostingSide.CREDIT);
        assertThat(revDebit).isEqualByComparingTo(revCredit);
        assertThat(revDebit).isEqualByComparingTo(amount);

        // Đảo chiều: Nợ vào 4211 (giảm nghĩa vụ nợ), Có vào 1011 (giảm quỹ tiền mặt)
        LedgerPosting revDebitPosting = savedReversal.getPostings().stream()
                .filter(p -> p.getSide() == PostingSide.DEBIT)
                .findFirst().orElseThrow();
        LedgerPosting revCreditPosting = savedReversal.getPostings().stream()
                .filter(p -> p.getSide() == PostingSide.CREDIT)
                .findFirst().orElseThrow();

        assertThat(revDebitPosting.getAccountId()).isEqualTo(account4211CustomerDeposits.getId());
        assertThat(revCreditPosting.getAccountId()).isEqualTo(account1011CashOnHand.getId());

        // Bất biến Append-Only: Chứng từ gốc không bị sửa đổi
        assertThat(original.getStatus()).isEqualTo(JournalEntryStatus.POSTED);
        assertThat(original.getPostings().get(0).getAmount()).isEqualByComparingTo(amount);
    }

    @Test
    @DisplayName("Kịch bản 8: Bảo toàn tính Idempotency - Ngăn chặn nạp đúp cùng EventId hoặc TransactionId")
    void shouldPreventDoublePostingIdempotency() {
        BigDecimal amount = new BigDecimal("200000000.00");
        String txId = "DEP-DUPLICATE-CHECK";
        String eventId = "EVENT-DEP-001";

        JournalEntry firstEntry = JournalEntry.createOriginal(
                txId,
                "Lần nạp thứ nhất",
                eventId,
                List.of(
                        new LedgerPosting(null, null, account1011CashOnHand.getId(), PostingSide.DEBIT, amount, "VND"),
                        new LedgerPosting(null, null, account4211CustomerDeposits.getId(), PostingSide.CREDIT, amount, "VND")
                )
        );
        persistencePort.saveJournalEntry(firstEntry);

        // Thử nạp lại với cùng eventId (reference_number)
        JournalEntry duplicateEventEntry = JournalEntry.createOriginal(
                "OTHER-TX",
                "Trùng eventId",
                eventId,
                List.of(
                        new LedgerPosting(null, null, account1011CashOnHand.getId(), PostingSide.DEBIT, amount, "VND"),
                        new LedgerPosting(null, null, account4211CustomerDeposits.getId(), PostingSide.CREDIT, amount, "VND")
                )
        );
        assertThatThrownBy(() -> persistencePort.saveJournalEntry(duplicateEventEntry))
                .isInstanceOf(DataIntegrityViolationException.class)
                .hasMessageContaining("Duplicate reference_number");

        // Thử nạp lại với cùng transactionId
        JournalEntry duplicateTxEntry = JournalEntry.createOriginal(
                txId,
                "Trùng transactionId",
                "DIFFERENT-EVENT-ID",
                List.of(
                        new LedgerPosting(null, null, account1011CashOnHand.getId(), PostingSide.DEBIT, amount, "VND"),
                        new LedgerPosting(null, null, account4211CustomerDeposits.getId(), PostingSide.CREDIT, amount, "VND")
                )
        );
        assertThatThrownBy(() -> persistencePort.saveJournalEntry(duplicateTxEntry))
                .isInstanceOf(DataIntegrityViolationException.class)
                .hasMessageContaining("already has a POSTED entry");
    }

    @Test
    @DisplayName("Kịch bản 9: Tích lũy nhiều giao dịch nạp tiền mặt tại quầy - Bảo toàn tổng số dư 205,000,000 VND")
    void shouldAccumulateMultipleCashDepositsAndConserveLedgerTotal() {
        // Giao dịch 1: Nạp 5,000,000 VND
        postDeposit("TX-CASH-1", "REF-1", new BigDecimal("5000000.00"));
        // Giao dịch 2: Nạp 200,000,000 VND
        postDeposit("TX-CASH-2", "REF-2", new BigDecimal("200000000.00"));

        List<JournalEntry> allEntries = persistencePort.findAllEntries();
        assertThat(allEntries).hasSize(2);

        BigDecimal cumulativeDebit = allEntries.stream()
                .flatMap(e -> e.getPostings().stream())
                .filter(p -> p.getSide() == PostingSide.DEBIT)
                .map(LedgerPosting::getAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal cumulativeCredit = allEntries.stream()
                .flatMap(e -> e.getPostings().stream())
                .filter(p -> p.getSide() == PostingSide.CREDIT)
                .map(LedgerPosting::getAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal grandDelta = cumulativeDebit.subtract(cumulativeCredit);

        // Tổng quỹ nạp đạt đúng 205,000,000 VND như portal
        assertThat(cumulativeDebit).isEqualByComparingTo(new BigDecimal("205000000.00"));
        assertThat(cumulativeCredit).isEqualByComparingTo(new BigDecimal("205000000.00"));
        assertThat(grandDelta).isEqualByComparingTo(BigDecimal.ZERO);
    }

    @Test
    @DisplayName("Kịch bản 10: Tích hợp LedgerService xử lý TransactionEventMessage nạp tiền (DEPOSIT)")
    void shouldIntegrateWithLedgerServiceDepositFlow() {
        TransactionEventMessage message = new TransactionEventMessage();
        message.setEventId("EVT-SERVICE-DEP-200M");
        message.setTransactionId("TX-SERVICE-DEP-200M");
        message.setType("DEPOSIT");
        message.setStatus("SUCCESS");
        message.setAmount(new BigDecimal("200000000.00"));
        message.setCurrency("VND");
        message.setTargetWalletId("bob-target-wallet");

        JournalEntry result = ledgerService.recordTransactionPosting(message);

        assertThat(result).isNotNull();
        assertThat(result.getStatus()).isEqualTo(JournalEntryStatus.POSTED);
        BigDecimal debit = sumSide(result, PostingSide.DEBIT);
        BigDecimal credit = sumSide(result, PostingSide.CREDIT);
        assertThat(debit).isEqualByComparingTo(credit);
        assertThat(debit).isEqualByComparingTo(new BigDecimal("200000000.00"));

        // Gọi lại lần 2 kiểm tra Idempotency tầng Service -> trả về null, không ghi đúp
        JournalEntry duplicateResult = ledgerService.recordTransactionPosting(message);
        assertThat(duplicateResult).isNull();
    }

    @Test
    @DisplayName("Kịch bản 11: LedgerService xử lý trực tiếp sự kiện CASH_DEPOSIT (Nợ 1011 / Có 4211)")
    void shouldIntegrateWithLedgerServiceCashDepositFlow() {
        TransactionEventMessage cashDepositMsg = new TransactionEventMessage();
        cashDepositMsg.setEventId("EVT-CASH-DEP-999");
        cashDepositMsg.setTransactionId("TX-CASH-DEP-999");
        cashDepositMsg.setType("CASH_DEPOSIT");
        cashDepositMsg.setStatus("COMPLETED");
        cashDepositMsg.setAmount(new BigDecimal("15000000.00"));
        cashDepositMsg.setCurrency("VND");
        cashDepositMsg.setTargetWalletId("bob-wallet-target");

        JournalEntry result = ledgerService.recordTransactionPosting(cashDepositMsg);

        assertThat(result).isNotNull();
        assertThat(result.getStatus()).isEqualTo(JournalEntryStatus.POSTED);
        assertThat(result.getPostings()).hasSize(2);

        // Nợ TK 1011 (Quỹ tiền mặt)
        LedgerPosting debitPosting = result.getPostings().stream()
                .filter(p -> p.getSide() == PostingSide.DEBIT)
                .findFirst().orElseThrow();
        // Có TK 4211 (Ví khách hàng)
        LedgerPosting creditPosting = result.getPostings().stream()
                .filter(p -> p.getSide() == PostingSide.CREDIT)
                .findFirst().orElseThrow();

        assertThat(debitPosting.getAmount()).isEqualByComparingTo(new BigDecimal("15000000.00"));
        assertThat(creditPosting.getAmount()).isEqualByComparingTo(new BigDecimal("15000000.00"));

        LedgerAccount debitAcc = persistencePort.findAccountById(debitPosting.getAccountId()).orElseThrow();
        assertThat(debitAcc.getCode()).startsWith("1011");

        LedgerAccount creditAcc = persistencePort.findAccountById(creditPosting.getAccountId()).orElseThrow();
        assertThat(creditAcc.getType()).isEqualTo(AccountType.LIABILITY);
    }

    @Test
    @DisplayName("Kịch bản 12: LedgerService tính toán chính xác Tổng phát sinh (Turnover Summary) cho Frontend")
    void shouldCalculateTurnoverSummary_ForFrontend() {
        // Given: Nạp 2 giao dịch tiền mặt tại quầy (200M và 5M)
        postDeposit("TX-SUM-1", "REF-SUM-1", new BigDecimal("200000000.00"));
        postDeposit("TX-SUM-2", "REF-SUM-2", new BigDecimal("5000000.00"));

        // Act: Lấy tổng phát sinh
        LedgerService.LedgerTurnoverSummary summary = ledgerService.getTurnoverSummary();

        // Assert: Các chỉ số khớp hoàn toàn với UI Dashboard
        assertThat(summary).isNotNull();
        assertThat(summary.totalDebit()).isEqualByComparingTo(new BigDecimal("205000000.00"));
        assertThat(summary.totalCredit()).isEqualByComparingTo(new BigDecimal("205000000.00"));
        assertThat(summary.delta()).isEqualByComparingTo(BigDecimal.ZERO);
        assertThat(summary.balanced()).isTrue();
        assertThat(summary.debit1011()).isEqualByComparingTo(new BigDecimal("205000000.00"));
        assertThat(summary.credit4211()).isEqualByComparingTo(new BigDecimal("205000000.00"));
        assertThat(summary.cashDelta()).isEqualByComparingTo(BigDecimal.ZERO);
        assertThat(summary.totalEntries()).isEqualTo(2);
        assertThat(summary.totalPostings()).isEqualTo(4);
        assertThat(summary.currency()).isEqualTo("VND");
        assertThat(summary.generatedAt()).isNotNull();
    }

    @Test
    @DisplayName("Kịch bản 13: Controller REST API trả về Tổng phát sinh cho Frontend (GET /api/v1/ledger/summary)")
    void shouldExposeTurnoverSummaryViaLedgerControllerEndpoint() {
        // Given
        postDeposit("TX-API-1", "REF-API-1", new BigDecimal("50000000.00"));
        LedgerController controller = new LedgerController(ledgerService);

        // Act
        ResponseEntity<ApiResponse<LedgerService.LedgerTurnoverSummary>> response = controller.getTurnoverSummary();

        // Assert
        assertThat(response.getStatusCode().is2xxSuccessful()).isTrue();
        ApiResponse<LedgerService.LedgerTurnoverSummary> body = response.getBody();
        assertThat(body).isNotNull();
        assertThat(body.getCode()).isEqualTo(200);
        assertThat(body.getMessage()).isEqualTo("Ledger turnover summary retrieved");

        LedgerService.LedgerTurnoverSummary data = body.getData();
        assertThat(data).isNotNull();
        assertThat(data.totalDebit()).isEqualByComparingTo(new BigDecimal("50000000.00"));
        assertThat(data.totalCredit()).isEqualByComparingTo(new BigDecimal("50000000.00"));
        assertThat(data.delta()).isEqualByComparingTo(BigDecimal.ZERO);
        assertThat(data.balanced()).isTrue();
        assertThat(data.debit1011()).isEqualByComparingTo(new BigDecimal("50000000.00"));
        assertThat(data.credit4211()).isEqualByComparingTo(new BigDecimal("50000000.00"));
    }

    @Test
    @DisplayName("Kịch bản 14: LedgerQueryController - GET /api/v1/ledger/cash-summary trả về tổng Nợ 1011 và tổng Có 4211")
    void shouldExposeCashSummaryViaLedgerQueryController() {
        // Given: Hạch toán nạp tiền mặt 200M VND
        postDeposit("TX-QUERY-1", "REF-QUERY-1", new BigDecimal("200000000.00"));
        LedgerQueryController queryController = new LedgerQueryController(ledgerService);

        // Act: Gọi GET /api/v1/ledger/cash-summary
        ResponseEntity<ApiResponse<LedgerQueryController.CashSummaryResponse>> response = queryController.getCashSummary();

        // Assert: HTTP 200 OK và dữ liệu trả về đủ các trường
        assertThat(response.getStatusCode().is2xxSuccessful()).isTrue();
        ApiResponse<LedgerQueryController.CashSummaryResponse> body = response.getBody();
        assertThat(body).isNotNull();
        assertThat(body.getCode()).isEqualTo(200);
        assertThat(body.getMessage()).isEqualTo("Cash summary retrieved");

        LedgerQueryController.CashSummaryResponse data = body.getData();
        assertThat(data).isNotNull();
        // Kiểm tra đúng Nợ 1011 và Có 4211
        assertThat(data.totalDebit1011()).isEqualByComparingTo(new BigDecimal("200000000.00"));
        assertThat(data.totalCredit4211()).isEqualByComparingTo(new BigDecimal("200000000.00"));
        assertThat(data.debit1011()).isEqualByComparingTo(new BigDecimal("200000000.00"));
        assertThat(data.credit4211()).isEqualByComparingTo(new BigDecimal("200000000.00"));
        // Định lý bảo toàn: Delta = 0, Balanced = true
        assertThat(data.delta()).isEqualByComparingTo(BigDecimal.ZERO);
        assertThat(data.balanced()).isTrue();
        assertThat(data.currency()).isEqualTo("VND");
        assertThat(data.totalEntries()).isGreaterThanOrEqualTo(1);
        assertThat(data.totalPostings()).isGreaterThanOrEqualTo(2);
        assertThat(data.timestamp()).isNotNull();
    }

    @Test
    @DisplayName("Kịch bản 15: Kafka Consumer xử lý banking.cash.deposit-completed.v1 hạch toán kép chuẩn Nợ 1011 / Có 4211")
    void shouldTranslateAndPostBankingCashDepositCompletedKafkaEvent() {
        // Given: Giả lập message từ topic banking.cash.deposit-completed.v1 (khớp script 07-cash-deposit-real-test.sh)
        KafkaEventEnvelope envelope = new KafkaEventEnvelope();
        envelope.setTopic("banking.cash.deposit-completed.v1");
        envelope.setTimestamp("1729237000000");

        Map<String, Object> payload = new HashMap<>();
        payload.put("eventType", "DepositCompletedEvent");
        payload.put("depositCode", "DEP-REAL-200M-002");
        payload.put("accountNumber", "0909876543");
        payload.put("customerName", "Bob Tran");
        payload.put("amount", 200000000);
        payload.put("branchId", "BR_Q1");
        payload.put("timestamp", 1729237000000L);
        envelope.setPayload(payload);

        // Act 1: Translator chuyển message sang hợp đồng TransactionEventMessage của Ledger
        KafkaLedgerEventTranslator translator = new KafkaLedgerEventTranslator();
        TransactionEventMessage eventMsg = translator.fromPaymentLifecycle(envelope);

        assertThat(eventMsg).isNotNull();
        assertThat(eventMsg.getType()).isEqualTo("CASH_DEPOSIT");
        assertThat(eventMsg.getStatus()).isEqualTo("COMPLETED");
        assertThat(eventMsg.getTransactionId()).isEqualTo("DEP-REAL-200M-002");
        assertThat(eventMsg.getTargetWalletId()).isEqualTo("0909876543");
        assertThat(eventMsg.getAmount()).isEqualByComparingTo(new BigDecimal("200000000"));

        // Act 2: Hạch toán kép vào Sổ cái
        JournalEntry journalEntry = ledgerService.recordTransactionPosting(eventMsg);

        // Assert: Bút toán kép Nợ 1011 / Có 4211 chuẩn xác
        assertThat(journalEntry).isNotNull();
        assertThat(journalEntry.getStatus()).isEqualTo(JournalEntryStatus.POSTED);
        assertThat(journalEntry.getPostings()).hasSize(2);

        LedgerPosting debitPosting = journalEntry.getPostings().stream()
                .filter(p -> p.getSide() == PostingSide.DEBIT)
                .findFirst().orElseThrow();
        LedgerPosting creditPosting = journalEntry.getPostings().stream()
                .filter(p -> p.getSide() == PostingSide.CREDIT)
                .findFirst().orElseThrow();

        // Nợ 1011 (Quỹ tiền mặt)
        LedgerAccount debitAcc = persistencePort.findAccountById(debitPosting.getAccountId()).orElseThrow();
        assertThat(debitAcc.getCode()).startsWith("1011");
        assertThat(debitPosting.getAmount()).isEqualByComparingTo(new BigDecimal("200000000"));

        // Có 4211 (Ví khách hàng)
        LedgerAccount creditAcc = persistencePort.findAccountById(creditPosting.getAccountId()).orElseThrow();
        assertThat(creditAcc.getType()).isEqualTo(AccountType.LIABILITY);
        assertThat(creditPosting.getAmount()).isEqualByComparingTo(new BigDecimal("200000000"));

        // Delta = 0 (Bảo toàn số cái tuyệt đối)
        BigDecimal delta = debitPosting.getAmount().subtract(creditPosting.getAmount());
        assertThat(delta).isEqualByComparingTo(BigDecimal.ZERO);
    }

    private void postDeposit(String txId, String refId, BigDecimal amount) {
        JournalEntry entry = JournalEntry.createOriginal(
                txId,
                "Nạp tiền mặt " + amount + " VND",
                refId,
                List.of(
                        new LedgerPosting(null, null, account1011CashOnHand.getId(), PostingSide.DEBIT, amount, "VND"),
                        new LedgerPosting(null, null, account4211CustomerDeposits.getId(), PostingSide.CREDIT, amount, "VND")
                )
        );
        persistencePort.saveJournalEntry(entry);
    }

    private BigDecimal sumSide(JournalEntry entry, PostingSide side) {
        return entry.getPostings().stream()
                .filter(p -> p.getSide() == side)
                .map(LedgerPosting::getAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }
}
