package com.fintech.payment;

import com.fintech.payment.domain.entity.CashDeposit;
import com.fintech.payment.exception.MakerCheckerViolationException;
import com.fintech.payment.rule.MakerCheckerRule;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Test nghiệp vụ Maker-Checker (Four-Eyes Principle / Nguyên tắc 4 mắt)
 * Phục vụ nghiệp vụ Nạp tiền tại quầy (Cash Deposit) & Chuyển tiền Core Banking.
 *
 * Mục tiêu cốt lõi: Chứng minh Maker (Giao dịch viên lập lệnh) KHÔNG THỂ tự làm Checker (Kiểm soát viên phê duyệt).
 */
@DisplayName("Kiểm thử nghiệp vụ Maker-Checker (Four-Eyes Principle Rule)")
class MakerCheckerRuleTest {

    private MakerCheckerRule makerCheckerRule;

    // Giả lập ID cán bộ theo kịch bản thực tế 07-cash-deposit-real-test.sh
    private static final String TELLER_A_ID = "t0000001-0000-0000-0000-000000000001"; // Maker
    private static final String MANAGER_C_ID = "m0000001-0000-0000-0000-000000000001"; // Checker hợp lệ
    private static final String ANOTHER_TELLER_ID = "t0000002-0000-0000-0000-000000000002";

    @BeforeEach
    void setUp() {
        makerCheckerRule = new MakerCheckerRule();
    }

    private CashDeposit createPendingDeposit(String makerId, long amount) {
        return CashDeposit.builder()
                .id(UUID.randomUUID().toString())
                .depositCode("DEP-REAL-" + System.currentTimeMillis())
                .accountNumber("0909876543")
                .customerName("Bob Tran")
                .amount(amount)
                .currency("VND")
                .makerId(makerId)
                .branchId("BR_Q1")
                .status(CashDeposit.STATUS_PENDING_APPROVAL)
                .idempotencyKey("idem_" + UUID.randomUUID())
                .build();
    }

    @Nested
    @DisplayName("1. Chứng minh Maker không thể tự làm Checker (Vi phạm nguyên tắc 4 mắt)")
    class MakerCannotBeCheckerTests {

        @Test
        @DisplayName("Maker cố tình tự duyệt lệnh của chính mình qua MakerCheckerRule -> Phải ném MakerCheckerViolationException")
        void shouldThrowExceptionWhenMakerAttemptsToApproveOwnDepositViaRule() {
            // Given: Giao dịch viên A lập lệnh nạp tiền 200,000,000 VND (> 50M -> Chờ duyệt)
            CashDeposit deposit = createPendingDeposit(TELLER_A_ID, 200_000_000L);

            // When & Then: Giao dịch viên A dùng ID của chính mình để phê duyệt lệnh
            assertThatThrownBy(() -> makerCheckerRule.approveDeposit(deposit, TELLER_A_ID))
                    .isInstanceOf(MakerCheckerViolationException.class)
                    .hasMessageContaining("Vi phạm nguyên tắc Maker-Checker")
                    .hasMessageContaining(TELLER_A_ID);

            // Xác minh: Trạng thái lệnh nạp vẫn giữ nguyên PENDING_APPROVAL, checker_id không bị cập nhật
            assertThat(deposit.getStatus()).isEqualTo(CashDeposit.STATUS_PENDING_APPROVAL);
            assertThat(deposit.getCheckerId()).isNull();
            assertThat(deposit.getApprovedAt()).isNull();
        }

        @Test
        @DisplayName("Maker cố tình tự duyệt trực tiếp trên Entity CashDeposit -> Phải ném MakerCheckerViolationException")
        void shouldThrowExceptionWhenMakerAttemptsToApproveDirectlyOnEntity() {
            // Given: Lệnh nạp tiền chờ duyệt do Teller A tạo
            CashDeposit deposit = createPendingDeposit(TELLER_A_ID, 150_000_000L);

            // When & Then: Gọi trực tiếp domain method approve() với checkerId = makerId
            assertThatThrownBy(() -> deposit.approve(TELLER_A_ID))
                    .isInstanceOf(MakerCheckerViolationException.class)
                    .satisfies(ex -> {
                        MakerCheckerViolationException mce = (MakerCheckerViolationException) ex;
                        assertThat(mce.getMakerId()).isEqualTo(TELLER_A_ID);
                        assertThat(mce.getCheckerId()).isEqualTo(TELLER_A_ID);
                    });

            // Xác minh: Lệnh không bị thay đổi trạng thái
            assertThat(deposit.getStatus()).isEqualTo(CashDeposit.STATUS_PENDING_APPROVAL);
            assertThat(deposit.getCheckerId()).isNull();
        }

        @Test
        @DisplayName("Maker cố tình tự từ chối (reject) lệnh của mình đóng vai Checker -> Phải ném MakerCheckerViolationException")
        void shouldThrowExceptionWhenMakerAttemptsToRejectOwnDeposit() {
            // Given: Lệnh nạp tiền của Teller A
            CashDeposit deposit = createPendingDeposit(TELLER_A_ID, 200_000_000L);

            // When & Then: Teller A cố tình đóng vai Checker để Reject lệnh
            assertThatThrownBy(() -> makerCheckerRule.rejectDeposit(deposit, TELLER_A_ID, "Hủy giao dịch tự lập"))
                    .isInstanceOf(MakerCheckerViolationException.class)
                    .hasMessageContaining("Vi phạm nguyên tắc Maker-Checker");

            // Xác minh: Lệnh vẫn ở PENDING_APPROVAL, không chuyển sang REJECTED
            assertThat(deposit.getStatus()).isEqualTo(CashDeposit.STATUS_PENDING_APPROVAL);
            assertThat(deposit.getCheckerId()).isNull();
            assertThat(deposit.getRejectionReason()).isNull();
        }

        @ParameterizedTest(name = "Biến thể bypass: Maker = ''{0}'', Checker = ''{1}''")
        @ValueSource(strings = {
                "  " + TELLER_A_ID + "  ", // Thêm khoảng trắng đầu/cuối
                TELLER_A_ID             // Chính xác
        })
        @DisplayName("Ngăn chặn các thủ thuật bypass chuỗi (khoảng trắng / case-insensitivity)")
        void shouldPreventBypassWithWhitespacesOrCase(String checkerVariant) {
            CashDeposit deposit = createPendingDeposit(TELLER_A_ID, 100_000_000L);

            assertThatThrownBy(() -> makerCheckerRule.approveDeposit(deposit, checkerVariant))
                    .isInstanceOf(MakerCheckerViolationException.class);
            assertThat(deposit.getStatus()).isEqualTo(CashDeposit.STATUS_PENDING_APPROVAL);
        }

        @Test
        @DisplayName("Hàm isViolation trả về true khi makerId trùng checkerId")
        void shouldReturnTrueWhenActorsAreIdentical() {
            assertThat(makerCheckerRule.isViolation(TELLER_A_ID, TELLER_A_ID)).isTrue();
            assertThat(makerCheckerRule.isViolation("user-1", "USER-1")).isTrue();
            assertThat(makerCheckerRule.isViolation(TELLER_A_ID, MANAGER_C_ID)).isFalse();
        }
    }

    @Nested
    @DisplayName("2. Kiểm soát viên độc lập (Checker != Maker) phê duyệt hợp lệ")
    class ValidCheckerApprovalTests {

        @Test
        @DisplayName("Kiểm soát viên độc lập duyệt lệnh -> Thành công, chuyển sang APPROVED và hoàn tất COMPLETED")
        void shouldApproveSuccessfullyWhenCheckerIsDifferent() {
            // Given: Teller A lập lệnh 200 triệu cho Bob Tran
            CashDeposit deposit = createPendingDeposit(TELLER_A_ID, 200_000_000L);

            // When: Manager C (Checker độc lập) thẩm định và phê duyệt
            makerCheckerRule.approveDeposit(deposit, MANAGER_C_ID);

            // Then: Lệnh chuyển trạng thái APPROVED và lưu đúng checker_id
            assertThat(deposit.getStatus()).isEqualTo(CashDeposit.STATUS_APPROVED);
            assertThat(deposit.getCheckerId()).isEqualTo(MANAGER_C_ID);
            assertThat(deposit.getApprovedAt()).isNotNull();

            // Tiếp tục hoàn tất hạch toán vào ví khách hàng
            deposit.complete();
            assertThat(deposit.getStatus()).isEqualTo(CashDeposit.STATUS_COMPLETED);
            assertThat(deposit.getCompletedAt()).isNotNull();
        }

        @Test
        @DisplayName("Kiểm soát viên độc lập từ chối lệnh -> Chuyển sang REJECTED cùng lý do hợp lệ")
        void shouldRejectSuccessfullyWhenCheckerIsDifferent() {
            CashDeposit deposit = createPendingDeposit(TELLER_A_ID, 200_000_000L);

            makerCheckerRule.rejectDeposit(deposit, MANAGER_C_ID, "Số tiền không khớp với bảng kê tiền mặt");

            assertThat(deposit.getStatus()).isEqualTo(CashDeposit.STATUS_REJECTED);
            assertThat(deposit.getCheckerId()).isEqualTo(MANAGER_C_ID);
            assertThat(deposit.getRejectionReason()).isEqualTo("Số tiền không khớp với bảng kê tiền mặt");
        }

        @Test
        @DisplayName("Hai giao dịch viên khác nhau (Teller B kiểm soát lệnh của Teller A) -> Hợp lệ về mặt định danh độc lập")
        void shouldAllowAnotherTellerIfPermittedByPolicy() {
            CashDeposit deposit = createPendingDeposit(TELLER_A_ID, 80_000_000L);

            makerCheckerRule.approveDeposit(deposit, ANOTHER_TELLER_ID);

            assertThat(deposit.getStatus()).isEqualTo(CashDeposit.STATUS_APPROVED);
            assertThat(deposit.getCheckerId()).isEqualTo(ANOTHER_TELLER_ID);
        }
    }

    @Nested
    @DisplayName("3. Kiểm tra hạn mức phê duyệt tự động vs Bắt buộc duyệt 4 mắt (Threshold)")
    class AutoApproveLimitTests {

        @Test
        @DisplayName("Số tiền 5,000,000 VND (<= 50M) -> Không yêu cầu kiểm soát viên (Tự động duyệt)")
        void shouldNotRequireCheckerWhenAmountWithinThreshold() {
            long smallAmount = 5_000_000L; // 5M VND (Kịch bản Alice Nguyen)
            assertThat(makerCheckerRule.requiresCheckerApproval(smallAmount)).isFalse();
        }

        @Test
        @DisplayName("Số tiền đúng bằng hạn mức 50,000,000 VND -> Không yêu cầu kiểm soát viên")
        void shouldNotRequireCheckerWhenAmountExactlyAtThreshold() {
            long exactLimit = 50_000_000L;
            assertThat(makerCheckerRule.requiresCheckerApproval(exactLimit)).isFalse();
        }

        @Test
        @DisplayName("Số tiền 200,000,000 VND (> 50M) -> BẮT BUỘC phê duyệt Maker-Checker")
        void shouldRequireCheckerWhenAmountExceedsThreshold() {
            long largeAmount = 200_000_000L; // 200M VND (Kịch bản Bob Tran)
            assertThat(makerCheckerRule.requiresCheckerApproval(largeAmount)).isTrue();
        }
    }

    @Nested
    @DisplayName("4. Thẩm định tính toàn vẹn dữ liệu và an toàn chuyển trạng thái")
    class ValidationAndStateSafetyTests {

        @Test
        @DisplayName("Checker ID bị null hoặc rỗng -> Ném IllegalArgumentException")
        void shouldThrowExceptionWhenCheckerIdIsBlank() {
            CashDeposit deposit = createPendingDeposit(TELLER_A_ID, 100_000_000L);

            assertThatThrownBy(() -> makerCheckerRule.approveDeposit(deposit, null))
                    .isInstanceOf(IllegalArgumentException.class);

            assertThatThrownBy(() -> makerCheckerRule.approveDeposit(deposit, "   "))
                    .isInstanceOf(IllegalArgumentException.class);
        }

        @Test
        @DisplayName("Không cho phép duyệt lại giao dịch đã hoàn tất COMPLETED hoặc REJECTED")
        void shouldPreventDoubleApprovalOnAlreadyCompletedOrRejectedDeposit() {
            CashDeposit deposit = createPendingDeposit(TELLER_A_ID, 100_000_000L);
            makerCheckerRule.approveDeposit(deposit, MANAGER_C_ID);
            deposit.complete();

            // Cố tình duyệt lần 2
            assertThatThrownBy(() -> makerCheckerRule.approveDeposit(deposit, MANAGER_C_ID))
                    .isInstanceOf(IllegalStateException.class)
                    .hasMessageContaining("PENDING_APPROVAL");
        }
    }
}
