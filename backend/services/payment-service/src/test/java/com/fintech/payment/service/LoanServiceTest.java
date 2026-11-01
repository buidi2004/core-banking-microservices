package com.fintech.payment.service;

import com.fintech.payment.domain.entity.LoanContract;
import com.fintech.payment.domain.entity.LoanScheduleItem;
import com.fintech.payment.dto.*;
import com.fintech.payment.grpc.WalletGrpcClient;
import com.fintech.payment.repository.LoanContractRepository;
import com.fintech.payment.repository.LoanScheduleItemRepository;
import com.fintech.payment.security.PinTokenValidator;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class LoanServiceTest {

    @Mock
    private LoanContractRepository loanContractRepository;

    @Mock
    private LoanScheduleItemRepository loanScheduleItemRepository;

    @Mock
    private WalletGrpcClient walletGrpcClient;

    @Mock
    private PinTokenValidator pinTokenValidator;

    private LoanService loanService;

    @BeforeEach
    void setUp() {
        loanService = new LoanService(
                loanContractRepository,
                loanScheduleItemRepository,
                walletGrpcClient,
                pinTokenValidator
        );
    }

    @Test
    @DisplayName("getProducts: Trả về các gói vay tiêu dùng nhanh chuẩn Core Banking")
    void getProducts_ReturnsStandardLoanProducts() {
        List<LoanProductDto> products = loanService.getProducts();

        assertThat(products).isNotEmpty();
        LoanProductDto quickLoan = products.stream()
                .filter(p -> p.getProductType().equals("VAY_TIEU_DUNG_NHANH"))
                .findFirst().orElseThrow();

        assertThat(quickLoan.getMinAmount()).isEqualByComparingTo("5000000");
        assertThat(quickLoan.getMaxAmount()).isEqualByComparingTo("50000000");
        assertThat(quickLoan.getAnnualRate()).isEqualByComparingTo("14.4");
        assertThat(quickLoan.getAvailableTerms()).contains(3, 6, 12, 24);
    }

    @Test
    @DisplayName("applyLoan: Nộp hồ sơ vay thành công, trạng thái PENDING_APPROVAL chờ cán bộ duyệt")
    void applyLoan_Success_PendingApproval() {
        String userId = "user-123";
        LoanApplicationRequest request = LoanApplicationRequest.builder()
                .walletId("wallet-123")
                .productType("VAY_TIEU_DUNG_NHANH")
                .amount(new BigDecimal("15000000"))
                .termMonths(6)
                .purpose("Tieu dung ca nhan")
                .pinToken("valid-pin-token")
                .build();

        doNothing().when(pinTokenValidator).validate(eq(userId), eq("valid-pin-token"));

        when(loanContractRepository.save(any(LoanContract.class))).thenAnswer(invocation -> {
            LoanContract lc = invocation.getArgument(0);
            lc.setId(UUID.randomUUID());
            return lc;
        });

        LoanApplicationResponse response = loanService.applyLoan(userId, request);

        assertThat(response).isNotNull();
        assertThat(response.getUserId()).isEqualTo(userId);
        assertThat(response.getPrincipalAmount()).isEqualByComparingTo("15000000");
        assertThat(response.getTermMonths()).isEqualTo(6);
        assertThat(response.getStatus()).isEqualTo("PENDING_APPROVAL");
        assertThat(response.getContractNumber()).startsWith("LN-");

        verify(pinTokenValidator).validate(userId, "valid-pin-token");
        verify(loanContractRepository).save(any(LoanContract.class));
        // Tiền chưa được giải ngân khi chỉ mới nộp đơn
        verifyNoInteractions(walletGrpcClient);
    }

    @Test
    @DisplayName("applyLoan: Nộp hồ sơ vay bằng OTP token thành công")
    void applyLoan_Success_WithOtpToken() {
        String userId = "user-123";
        LoanApplicationRequest request = LoanApplicationRequest.builder()
                .walletId("wallet-123")
                .productType("VAY_TIEU_DUNG_NHANH")
                .amount(new BigDecimal("10000000"))
                .termMonths(6)
                .purpose("Tieu dung ca nhan")
                .otpToken("valid-otp-token")
                .build();

        doNothing().when(pinTokenValidator).validateOtp(eq("valid-otp-token"), eq("LOAN_APPLY"));

        when(loanContractRepository.save(any(LoanContract.class))).thenAnswer(invocation -> {
            LoanContract lc = invocation.getArgument(0);
            lc.setId(UUID.randomUUID());
            return lc;
        });

        LoanApplicationResponse response = loanService.applyLoan(userId, request);

        assertThat(response).isNotNull();
        assertThat(response.getStatus()).isEqualTo("PENDING_APPROVAL");
        verify(pinTokenValidator).validateOtp("valid-otp-token", "LOAN_APPLY");
    }

    @Test
    @DisplayName("applyLoan: Thất bại khi không cung cấp cả OTP lẫn PIN token")
    void applyLoan_FailsWhenNoTokenProvided() {
        String userId = "user-123";
        LoanApplicationRequest request = LoanApplicationRequest.builder()
                .walletId("wallet-123")
                .productType("VAY_TIEU_DUNG_NHANH")
                .amount(new BigDecimal("10000000"))
                .termMonths(6)
                .build();

        assertThatThrownBy(() -> loanService.applyLoan(userId, request))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Vui lòng nhập và xác thực mã OTP");
    }

    @Test
    @DisplayName("approveLoan: Cán bộ quầy duyệt thành công -> Giải ngân vào ví và sinh lịch trả nợ")
    void approveLoan_Success() {
        UUID loanId = UUID.randomUUID();
        LoanContract contract = LoanContract.builder()
                .id(loanId)
                .userId("user-123")
                .walletId("wallet-123")
                .contractNumber("LN-123456")
                .productType("VAY_TIEU_DUNG_NHANH")
                .productName("Vay Tiêu Dùng Sen Hồng")
                .principalAmount(new BigDecimal("15000000"))
                .annualInterestRate(new BigDecimal("14.4"))
                .termMonths(6)
                .status("PENDING_APPROVAL")
                .build();

        when(loanContractRepository.findById(loanId)).thenReturn(Optional.of(contract));
        when(walletGrpcClient.credit(eq("wallet-123"), eq(15_000_000L), anyString(), anyString()))
                .thenReturn(com.fintech.payment.grpc.dto.WalletBalanceResult.builder().success(true).balanceAfter(25_000_000L).build());
        when(loanContractRepository.save(any(LoanContract.class))).thenAnswer(invocation -> invocation.getArgument(0));

        LoanApplicationResponse res = loanService.approveLoan(loanId.toString(), "teller1", "ROLE_TELLER");

        assertThat(res.getStatus()).isEqualTo("DISBURSED");
        assertThat(res.getApprovedBy()).isEqualTo("teller1");
        verify(walletGrpcClient).credit(eq("wallet-123"), eq(15_000_000L), anyString(), anyString());
        verify(loanScheduleItemRepository).saveAll(anyList());
    }

    @Test
    @DisplayName("rejectLoan: Cán bộ quầy từ chối hồ sơ vay -> Chuyển trạng thái REJECTED")
    void rejectLoan_Success() {
        UUID loanId = UUID.randomUUID();
        LoanContract contract = LoanContract.builder()
                .id(loanId)
                .userId("user-123")
                .walletId("wallet-123")
                .contractNumber("LN-123456")
                .termMonths(6)
                .status("PENDING_APPROVAL")
                .build();

        when(loanContractRepository.findById(loanId)).thenReturn(Optional.of(contract));
        when(loanContractRepository.save(any(LoanContract.class))).thenAnswer(invocation -> invocation.getArgument(0));

        LoanApplicationResponse res = loanService.rejectLoan(loanId.toString(), "manager1", "ROLE_MANAGER", "Điểm tín dụng không đạt");

        assertThat(res.getStatus()).isEqualTo("REJECTED");
        assertThat(res.getApprovedBy()).isEqualTo("manager1");
        assertThat(res.getRejectReason()).isEqualTo("Điểm tín dụng không đạt");
        verifyNoInteractions(walletGrpcClient);
    }

    @Test
    @DisplayName("applyLoan: Thất bại khi số tiền vượt hạn mức tối đa")
    void applyLoan_FailsWhenExceedsMaxLimit() {
        String userId = "user-123";
        LoanApplicationRequest request = LoanApplicationRequest.builder()
                .walletId("wallet-123")
                .productType("VAY_TIEU_DUNG_NHANH")
                .amount(new BigDecimal("100000000")) // 100M > 50M limit
                .termMonths(6)
                .pinToken("valid-pin-token")
                .build();

        assertThatThrownBy(() -> loanService.applyLoan(userId, request))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Hạn mức vay");

        verifyNoInteractions(walletGrpcClient);
    }

    @Test
    @DisplayName("getLoanSchedule: Trả về lịch trả nợ chuẩn xác từng kỳ hạn")
    void getLoanSchedule_Success() {
        String userId = "user-123";
        UUID loanId = UUID.randomUUID();

        LoanContract contract = LoanContract.builder()
                .id(loanId)
                .userId(userId)
                .walletId("wallet-123")
                .contractNumber("LN-999")
                .principalAmount(new BigDecimal("15000000"))
                .termMonths(6)
                .annualInterestRate(new BigDecimal("14.4"))
                .remainingPrincipal(new BigDecimal("15000000"))
                .status("DISBURSED")
                .build();

        List<LoanScheduleItem> items = new ArrayList<>();
        for (int i = 1; i <= 6; i++) {
            items.add(LoanScheduleItem.builder()
                    .id(UUID.randomUUID())
                    .loanContractId(loanId)
                    .termNumber(i)
                    .dueDate(LocalDate.now().plusMonths(i))
                    .principalAmount(new BigDecimal("2500000"))
                    .interestAmount(new BigDecimal("180000"))
                    .totalAmount(new BigDecimal("2680000"))
                    .remainingBalance(new BigDecimal("15000000").subtract(new BigDecimal("2500000").multiply(BigDecimal.valueOf(i))))
                    .status(i == 1 ? "DUE" : "UPCOMING")
                    .build());
        }

        when(loanContractRepository.findByIdAndUserId(loanId, userId)).thenReturn(Optional.of(contract));
        when(loanScheduleItemRepository.findByLoanContractIdOrderByTermNumberAsc(loanId)).thenReturn(items);

        LoanScheduleResponse response = loanService.getLoanSchedule(loanId.toString(), userId);

        assertThat(response).isNotNull();
        assertThat(response.getContractNumber()).isEqualTo("LN-999");
        assertThat(response.getSchedule()).hasSize(6);
        assertThat(response.getSchedule().get(0).getStatus()).isEqualTo("DUE");
        assertThat(response.getSchedule().get(1).getStatus()).isEqualTo("UPCOMING");
    }

    @Test
    @DisplayName("repayTerm: Trích nợ từ ví thanh toán kỳ đến hạn thành công")
    void repayTerm_Success() {
        String userId = "user-123";
        UUID loanId = UUID.randomUUID();

        LoanContract contract = LoanContract.builder()
                .id(loanId)
                .userId(userId)
                .walletId("wallet-123")
                .contractNumber("LN-999")
                .principalAmount(new BigDecimal("15000000"))
                .remainingPrincipal(new BigDecimal("15000000"))
                .termMonths(6)
                .status("DISBURSED")
                .build();

        LoanScheduleItem dueItem = LoanScheduleItem.builder()
                .id(UUID.randomUUID())
                .loanContractId(loanId)
                .termNumber(1)
                .dueDate(LocalDate.now())
                .principalAmount(new BigDecimal("2500000"))
                .interestAmount(new BigDecimal("180000"))
                .totalAmount(new BigDecimal("2680000"))
                .remainingBalance(new BigDecimal("12500000"))
                .status("DUE")
                .build();

        when(loanContractRepository.findByIdAndUserId(loanId, userId)).thenReturn(Optional.of(contract));
        when(loanScheduleItemRepository.findByLoanContractIdAndTermNumber(loanId, 1)).thenReturn(Optional.of(dueItem));
        doNothing().when(pinTokenValidator).validate(eq(userId), eq("valid-pin-token"));
        when(walletGrpcClient.debit(eq("wallet-123"), eq(2_680_000L), anyString(), anyString()))
                .thenReturn(com.fintech.payment.grpc.dto.WalletBalanceResult.builder().success(true).balanceAfter(10_000_000L).build());

        LoanRepaymentRequest request = LoanRepaymentRequest.builder()
                .termNumber(1)
                .pinToken("valid-pin-token")
                .build();

        LoanRepaymentResponse response = loanService.repayTerm(loanId.toString(), userId, request);

        assertThat(response).isNotNull();
        assertThat(response.getTermNumber()).isEqualTo(1);
        assertThat(response.getPaidAmount()).isEqualByComparingTo("2680000");
        assertThat(dueItem.getStatus()).isEqualTo("PAID");
        assertThat(dueItem.getPaidDate()).isNotNull();

        verify(walletGrpcClient).debit(eq("wallet-123"), eq(2_680_000L), anyString(), anyString());
        verify(loanScheduleItemRepository).save(dueItem);
        verify(loanContractRepository).save(contract);
    }
}

