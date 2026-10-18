package com.fintech.payment;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fintech.payment.controller.CashDepositController;
import com.fintech.payment.domain.entity.CashDeposit;
import com.fintech.payment.dto.CashDepositApproveRequest;
import com.fintech.payment.dto.CashDepositRejectRequest;
import com.fintech.payment.dto.CashDepositRequest;
import com.fintech.payment.exception.GlobalExceptionHandler;
import com.fintech.payment.kafka.PaymentKafkaProducer;
import com.fintech.payment.repository.CashDepositRepository;
import com.fintech.payment.rule.MakerCheckerRule;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.boot.test.mock.mockito.SpyBean;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.hamcrest.Matchers.is;
import static org.hamcrest.Matchers.notNullValue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(controllers = CashDepositController.class)
@AutoConfigureMockMvc(addFilters = false)
@Import({GlobalExceptionHandler.class, MakerCheckerRule.class})
@DisplayName("Kiểm thử CashDepositController (Nạp tiền quầy & Maker-Checker)")
class CashDepositControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private CashDepositRepository cashDepositRepository;

    @SpyBean
    private MakerCheckerRule makerCheckerRule;

    @MockBean
    private PaymentKafkaProducer paymentKafkaProducer;

    private static final String TELLER_A_ID = "t0000001-0000-0000-0000-000000000001";
    private static final String MANAGER_C_ID = "m0000001-0000-0000-0000-000000000001";

    @Nested
    @DisplayName("1. POST /api/v1/cash/deposits - Lập lệnh nạp tiền tại quầy")
    class CreateDepositTests {

        @Test
        @DisplayName("Nạp tiền trong hạn mức (<= 50M) -> Tự động duyệt hoàn tất (COMPLETED)")
        void shouldAutoApproveWhenAmountWithinLimit() throws Exception {
            CashDepositRequest request = CashDepositRequest.builder()
                    .accountNumber("0901234567")
                    .customerName("Alice Nguyen")
                    .amount(5_000_000L)
                    .currency("VND")
                    .branchId("BR_Q1")
                    .idempotencyKey("idem_5m_test")
                    .build();

            when(cashDepositRepository.findByIdempotencyKey("idem_5m_test")).thenReturn(Optional.empty());
            when(cashDepositRepository.save(any(CashDeposit.class))).thenAnswer(invocation -> invocation.getArgument(0));

            mockMvc.perform(post("/api/v1/cash/deposits")
                            .header("X-User-Id", TELLER_A_ID)
                            .header("X-User-Role", "ROLE_TELLER")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success", is(true)))
                    .andExpect(jsonPath("$.data.status", is("COMPLETED")))
                    .andExpect(jsonPath("$.data.amount", is(5_000_000)))
                    .andExpect(jsonPath("$.data.customerName", is("Alice Nguyen")))
                    .andExpect(jsonPath("$.data.checkerName", is("Hệ thống tự duyệt (≤50M)")))
                    .andExpect(jsonPath("$.data.code", notNullValue()));

            verify(paymentKafkaProducer).sendCashDepositCompleted(any(), eq("0901234567"), eq("Alice Nguyen"), eq(5_000_000L), eq("BR_Q1"));
        }

        @Test
        @DisplayName("Nạp tiền vượt hạn mức (> 50M) -> Chờ duyệt (PENDING_APPROVAL)")
        void shouldRequireApprovalWhenAmountExceedsLimit() throws Exception {
            CashDepositRequest request = CashDepositRequest.builder()
                    .accountNumber("0909876543")
                    .customerName("Bob Tran")
                    .amount(200_000_000L)
                    .currency("VND")
                    .branchId("BR_Q1")
                    .idempotencyKey("idem_200m_test")
                    .build();

            when(cashDepositRepository.findByIdempotencyKey("idem_200m_test")).thenReturn(Optional.empty());
            when(cashDepositRepository.save(any(CashDeposit.class))).thenAnswer(invocation -> invocation.getArgument(0));

            mockMvc.perform(post("/api/v1/cash/deposits")
                            .header("X-User-Id", TELLER_A_ID)
                            .header("X-User-Role", "ROLE_TELLER")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success", is(true)))
                    .andExpect(jsonPath("$.data.status", is("PENDING_APPROVAL")))
                    .andExpect(jsonPath("$.data.amount", is(200_000_000)))
                    .andExpect(jsonPath("$.data.customerName", is("Bob Tran")));
        }

        @Test
        @DisplayName("Gửi lại cùng Idempotency Key -> Trả về giao dịch đã tồn tại (Chống duplicate)")
        void shouldReturnExistingWhenDuplicateIdempotencyKey() throws Exception {
            CashDeposit existing = CashDeposit.builder()
                    .id("existing-id")
                    .depositCode("DEP-EXISTING-001")
                    .accountNumber("0901234567")
                    .customerName("Alice Nguyen")
                    .amount(5_000_000L)
                    .currency("VND")
                    .makerId(TELLER_A_ID)
                    .status(CashDeposit.STATUS_COMPLETED)
                    .idempotencyKey("idem_dup_test")
                    .createdAt(Instant.now())
                    .build();

            when(cashDepositRepository.findByIdempotencyKey("idem_dup_test")).thenReturn(Optional.of(existing));

            CashDepositRequest request = CashDepositRequest.builder()
                    .accountNumber("0901234567")
                    .customerName("Alice Nguyen")
                    .amount(5_000_000L)
                    .idempotencyKey("idem_dup_test")
                    .build();

            mockMvc.perform(post("/api/v1/cash/deposits")
                            .header("X-User-Id", TELLER_A_ID)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success", is(true)))
                    .andExpect(jsonPath("$.message").value(org.hamcrest.Matchers.containsString("Idempotent")))
                    .andExpect(jsonPath("$.data.id", is("existing-id")))
                    .andExpect(jsonPath("$.data.code", is("DEP-EXISTING-001")));
        }

        @Test
        @DisplayName("Validation lỗi: Số tiền <= 0 -> Phải trả về HTTP 400 Bad Request")
        void shouldReturn400WhenAmountIsZeroOrNegative() throws Exception {
            CashDepositRequest request = CashDepositRequest.builder()
                    .accountNumber("0901234567")
                    .customerName("Alice Nguyen")
                    .amount(0L)
                    .build();

            mockMvc.perform(post("/api/v1/cash/deposits")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isBadRequest())
                    .andExpect(jsonPath("$.success", is(false)));
        }
    }

    @Nested
    @DisplayName("2. POST /api/v1/cash/deposits/{id}/approve - Phê duyệt lệnh nạp tiền")
    class ApproveDepositTests {

        @Test
        @DisplayName("Manager duyệt hợp lệ (ROLE_MANAGER và checker_id != maker_id) -> Thành công HTTP 200")
        void shouldApproveSuccessfullyWhenValidManagerAndDifferentActor() throws Exception {
            CashDeposit deposit = CashDeposit.builder()
                    .id("dep-200m")
                    .depositCode("DEP-200M")
                    .accountNumber("0909876543")
                    .customerName("Bob Tran")
                    .amount(200_000_000L)
                    .currency("VND")
                    .makerId(TELLER_A_ID)
                    .branchId("BR_Q1")
                    .status(CashDeposit.STATUS_PENDING_APPROVAL)
                    .idempotencyKey("idem_200m")
                    .createdAt(Instant.now())
                    .build();

            when(cashDepositRepository.findById("dep-200m")).thenReturn(Optional.of(deposit));
            when(cashDepositRepository.save(any(CashDeposit.class))).thenAnswer(invocation -> invocation.getArgument(0));

            mockMvc.perform(post("/api/v1/cash/deposits/dep-200m/approve")
                            .header("X-User-Id", MANAGER_C_ID)
                            .header("X-User-Role", "ROLE_MANAGER")
                            .contentType(MediaType.APPLICATION_JSON))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success", is(true)))
                    .andExpect(jsonPath("$.data.status", is("COMPLETED")))
                    .andExpect(jsonPath("$.data.checkerId", is(MANAGER_C_ID)))
                    .andExpect(jsonPath("$.data.checkerName", is("Manager Lê Hoàng C")));

            verify(paymentKafkaProducer).sendCashDepositCompleted(eq("DEP-200M"), eq("0909876543"), eq("Bob Tran"), eq(200_000_000L), eq("BR_Q1"));
        }

        @Test
        @DisplayName("CHẶN ĐỨNG MAKER == CHECKER: Teller A cố tình tự duyệt lệnh của chính mình -> HTTP 403 Forbidden")
        void shouldBlockWhenMakerAttemptsToApproveOwnDeposit() throws Exception {
            CashDeposit deposit = CashDeposit.builder()
                    .id("dep-200m")
                    .depositCode("DEP-200M")
                    .accountNumber("0909876543")
                    .customerName("Bob Tran")
                    .amount(200_000_000L)
                    .currency("VND")
                    .makerId(TELLER_A_ID) // Maker là Teller A
                    .branchId("BR_Q1")
                    .status(CashDeposit.STATUS_PENDING_APPROVAL)
                    .idempotencyKey("idem_200m")
                    .createdAt(Instant.now())
                    .build();

            when(cashDepositRepository.findById("dep-200m")).thenReturn(Optional.of(deposit));

            // Checker cố tình gửi chính là Teller A (maker_id == checker_id), dù gắn ROLE_MANAGER
            mockMvc.perform(post("/api/v1/cash/deposits/dep-200m/approve")
                            .header("X-User-Id", TELLER_A_ID)
                            .header("X-User-Role", "ROLE_MANAGER")
                            .contentType(MediaType.APPLICATION_JSON))
                    .andExpect(status().isForbidden())
                    .andExpect(jsonPath("$.success", is(false)))
                    .andExpect(jsonPath("$.message").value(org.hamcrest.Matchers.containsString("Vi phạm nguyên tắc Maker-Checker")));
        }

        @Test
        @DisplayName("CHẶN PHÂN QUYỀN: User không phải ROLE_MANAGER (ví dụ ROLE_TELLER) -> HTTP 403 Forbidden")
        void shouldBlockWhenRoleIsNotManager() throws Exception {
            mockMvc.perform(post("/api/v1/cash/deposits/dep-200m/approve")
                            .header("X-User-Id", MANAGER_C_ID)
                            .header("X-User-Role", "ROLE_TELLER") // Sai role
                            .contentType(MediaType.APPLICATION_JSON))
                    .andExpect(status().isForbidden())
                    .andExpect(jsonPath("$.success", is(false)))
                    .andExpect(jsonPath("$.message").value(org.hamcrest.Matchers.containsString("ROLE_MANAGER")));
        }

        @Test
        @DisplayName("Lệnh không ở trạng thái PENDING_APPROVAL -> HTTP 400 Bad Request")
        void shouldFailWhenNotPendingApproval() throws Exception {
            CashDeposit deposit = CashDeposit.builder()
                    .id("dep-already-completed")
                    .depositCode("DEP-DONE")
                    .accountNumber("0901234567")
                    .customerName("Alice Nguyen")
                    .amount(5_000_000L)
                    .makerId(TELLER_A_ID)
                    .status(CashDeposit.STATUS_COMPLETED)
                    .build();

            when(cashDepositRepository.findById("dep-already-completed")).thenReturn(Optional.of(deposit));

            mockMvc.perform(post("/api/v1/cash/deposits/dep-already-completed/approve")
                            .header("X-User-Id", MANAGER_C_ID)
                            .header("X-User-Role", "ROLE_MANAGER"))
                    .andExpect(status().isBadRequest())
                    .andExpect(jsonPath("$.success", is(false)))
                    .andExpect(jsonPath("$.message").value(org.hamcrest.Matchers.containsString("PENDING_APPROVAL")));
        }
    }

    @Nested
    @DisplayName("3. POST /api/v1/cash/deposits/{id}/reject - Từ chối lệnh nạp tiền")
    class RejectDepositTests {

        @Test
        @DisplayName("Manager từ chối hợp lệ (checker_id != maker_id) -> Thành công HTTP 200")
        void shouldRejectSuccessfullyWhenDifferentActor() throws Exception {
            CashDeposit deposit = CashDeposit.builder()
                    .id("dep-reject-1")
                    .depositCode("DEP-REJ-01")
                    .accountNumber("0909876543")
                    .customerName("Bob Tran")
                    .amount(200_000_000L)
                    .makerId(TELLER_A_ID)
                    .status(CashDeposit.STATUS_PENDING_APPROVAL)
                    .build();

            when(cashDepositRepository.findById("dep-reject-1")).thenReturn(Optional.of(deposit));
            when(cashDepositRepository.save(any(CashDeposit.class))).thenAnswer(invocation -> invocation.getArgument(0));

            CashDepositRejectRequest rejectRequest = CashDepositRejectRequest.builder()
                    .reason("Sai số tài khoản nhận tiền")
                    .build();

            mockMvc.perform(post("/api/v1/cash/deposits/dep-reject-1/reject")
                            .header("X-User-Id", MANAGER_C_ID)
                            .header("X-User-Role", "ROLE_MANAGER")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(rejectRequest)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success", is(true)))
                    .andExpect(jsonPath("$.data.status", is("REJECTED")))
                    .andExpect(jsonPath("$.data.rejectionReason", is("Sai số tài khoản nhận tiền")));
        }

        @Test
        @DisplayName("CHẶN ĐỨNG: Maker cố tình tự từ chối lệnh của mình giả làm Checker -> HTTP 403 Forbidden")
        void shouldBlockWhenMakerAttemptsToRejectOwnDeposit() throws Exception {
            CashDeposit deposit = CashDeposit.builder()
                    .id("dep-reject-2")
                    .depositCode("DEP-REJ-02")
                    .accountNumber("0909876543")
                    .customerName("Bob Tran")
                    .amount(200_000_000L)
                    .makerId(TELLER_A_ID)
                    .status(CashDeposit.STATUS_PENDING_APPROVAL)
                    .build();

            when(cashDepositRepository.findById("dep-reject-2")).thenReturn(Optional.of(deposit));

            mockMvc.perform(post("/api/v1/cash/deposits/dep-reject-2/reject")
                            .header("X-User-Id", TELLER_A_ID)
                            .header("X-User-Role", "ROLE_MANAGER")
                            .contentType(MediaType.APPLICATION_JSON))
                    .andExpect(status().isForbidden())
                    .andExpect(jsonPath("$.success", is(false)))
                    .andExpect(jsonPath("$.message").value(org.hamcrest.Matchers.containsString("Vi phạm nguyên tắc Maker-Checker")));
        }
    }

    @Nested
    @DisplayName("4. GET /api/v1/cash/deposits - Danh sách giao dịch nạp tiền quầy")
    class ListDepositsTests {

        @Test
        @DisplayName("Lấy danh sách thành công")
        void shouldReturnDepositsList() throws Exception {
            CashDeposit d1 = CashDeposit.builder()
                    .id("d1")
                    .depositCode("DEP-001")
                    .accountNumber("0901234567")
                    .customerName("Alice")
                    .amount(5_000_000L)
                    .makerId(TELLER_A_ID)
                    .status(CashDeposit.STATUS_COMPLETED)
                    .createdAt(Instant.now())
                    .build();

            when(cashDepositRepository.findAllByOrderByCreatedAtDesc()).thenReturn(List.of(d1));

            mockMvc.perform(get("/api/v1/cash/deposits"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success", is(true)))
                    .andExpect(jsonPath("$.data[0].code", is("DEP-001")))
                    .andExpect(jsonPath("$.data[0].amount", is(5_000_000)));
        }

        @Test
        @DisplayName("Lọc danh sách theo status=PENDING_APPROVAL")
        void shouldFilterByStatus() throws Exception {
            CashDeposit d2 = CashDeposit.builder()
                    .id("d2")
                    .depositCode("DEP-002")
                    .accountNumber("0909876543")
                    .customerName("Bob")
                    .amount(200_000_000L)
                    .makerId(TELLER_A_ID)
                    .status(CashDeposit.STATUS_PENDING_APPROVAL)
                    .createdAt(Instant.now())
                    .build();

            when(cashDepositRepository.findByStatusOrderByCreatedAtDesc("PENDING_APPROVAL")).thenReturn(List.of(d2));

            mockMvc.perform(get("/api/v1/cash/deposits?status=PENDING_APPROVAL"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success", is(true)))
                    .andExpect(jsonPath("$.data[0].code", is("DEP-002")))
                    .andExpect(jsonPath("$.data[0].status", is("PENDING_APPROVAL")));
        }
    }

    @Nested
    @DisplayName("5. GET /api/v1/cash/vault/summary - Báo cáo tổng kết quỹ tiền mặt quầy")
    class VaultSummaryTests {

        @Test
        @DisplayName("Tính toán chính xác tồn quỹ đầu ngày, tổng thu, tồn thực tế, số lượng hoàn tất & chờ duyệt")
        void shouldCalculateVaultSummaryAccurately() throws Exception {
            when(cashDepositRepository.sumCompletedAmount()).thenReturn(205_000_000L);
            when(cashDepositRepository.countByStatus(CashDeposit.STATUS_COMPLETED)).thenReturn(3L);
            when(cashDepositRepository.countByStatus(CashDeposit.STATUS_PENDING_APPROVAL)).thenReturn(1L);

            mockMvc.perform(get("/api/v1/cash/vault/summary"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success", is(true)))
                    .andExpect(jsonPath("$.data.openingBalance", is(50_000_000)))
                    .andExpect(jsonPath("$.data.totalCashIn", is(205_000_000)))
                    .andExpect(jsonPath("$.data.currentBalance", is(255_000_000))) // 50M + 205M = 255M
                    .andExpect(jsonPath("$.data.maxLimit", is(500_000_000)))
                    .andExpect(jsonPath("$.data.successCount", is(3)))
                    .andExpect(jsonPath("$.data.pendingCount", is(1)));
        }
    }
}
