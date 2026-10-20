package com.fintech.payment.service;

import com.fintech.payment.domain.entity.SavingsAccount;
import com.fintech.payment.dto.*;
import com.fintech.payment.grpc.WalletGrpcClient;
import com.fintech.payment.repository.SavingsAccountRepository;
import com.fintech.payment.security.PinTokenValidator;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class SavingsServiceTest {

    @Mock
    private SavingsAccountRepository savingsRepository;

    @Mock
    private WalletGrpcClient walletGrpcClient;

    @Mock
    private PinTokenValidator pinTokenValidator;

    private SavingsService savingsService;

    @BeforeEach
    void setUp() {
        savingsService = new SavingsService(savingsRepository, walletGrpcClient, pinTokenValidator);
    }

    @Test
    @DisplayName("getProducts: Trả về danh sách gói tiết kiệm và bảng kỳ hạn chuẩn Core Banking")
    void getProducts_ReturnsStandardProducts() {
        List<SavingsProductDto> products = savingsService.getProducts();

        assertThat(products).isNotEmpty();
        assertThat(products).anyMatch(p -> p.getProductType().equals("TIET_KIEM_PHAT_LOC"));
        assertThat(products).anyMatch(p -> p.getProductType().equals("TIET_KIEM_TRA_LAI_THANG"));
        assertThat(products).anyMatch(p -> p.getProductType().equals("TICH_LUY_GUI_GOP"));

        SavingsProductDto phatLoc = products.stream()
                .filter(p -> p.getProductType().equals("TIET_KIEM_PHAT_LOC"))
                .findFirst().orElseThrow();
        assertThat(phatLoc.getMinDeposit()).isGreaterThanOrEqualTo(new BigDecimal("1000000"));
        assertThat(phatLoc.getTerms()).isNotEmpty();
    }

    @Test
    @DisplayName("openSavings: Mở sổ tiết kiệm thành công, trừ ví và ghi nhận lãi dự kiến chuẩn xác")
    void openSavings_Success() {
        String userId = "user-abc-123";
        OpenSavingsRequest request = OpenSavingsRequest.builder()
                .walletId("wallet-xyz-999")
                .productType("TIET_KIEM_PHAT_LOC")
                .termMonths(12)
                .depositAmount(new BigDecimal("10000000"))
                .rolloverType("AUTO_ROLLOVER_ALL")
                .pinToken("valid-pin-token")
                .build();

        doNothing().when(pinTokenValidator).validate(eq(userId), eq("valid-pin-token"));
        when(walletGrpcClient.debit(eq("wallet-xyz-999"), eq(10_000_000L), anyString(), anyString()))
                .thenReturn(com.fintech.payment.grpc.dto.WalletBalanceResult.builder().success(true).balanceAfter(50_000_000L).build());

        when(savingsRepository.save(any(SavingsAccount.class))).thenAnswer(invocation -> {
            SavingsAccount sa = invocation.getArgument(0);
            sa.setId(UUID.randomUUID());
            return sa;
        });

        SavingsAccountResponse response = savingsService.openSavings(userId, request);

        assertThat(response).isNotNull();
        assertThat(response.getUserId()).isEqualTo(userId);
        assertThat(response.getPrincipal()).isEqualByComparingTo("10000000");
        assertThat(response.getTermMonths()).isEqualTo(12);
        assertThat(response.getInterestRate()).isEqualByComparingTo("7.2");
        // Expected interest for 12 months at 7.2%: 10,000,000 * 0.072 = 720,000
        assertThat(response.getExpectedInterest()).isEqualByComparingTo("720000");
        assertThat(response.getStatus()).isEqualTo("ACTIVE");
        assertThat(response.getAccountNumber()).startsWith("TKPL-");

        verify(pinTokenValidator).validate(userId, "valid-pin-token");
        verify(walletGrpcClient).debit(eq("wallet-xyz-999"), eq(10_000_000L), anyString(), anyString());
        verify(savingsRepository).save(any(SavingsAccount.class));
    }

    @Test
    @DisplayName("openSavings: Thất bại khi số tiền gửi nhỏ hơn hạn mức tối thiểu")
    void openSavings_FailsWhenBelowMinDeposit() {
        String userId = "user-abc-123";
        OpenSavingsRequest request = OpenSavingsRequest.builder()
                .walletId("wallet-xyz-999")
                .productType("TIET_KIEM_PHAT_LOC")
                .termMonths(6)
                .depositAmount(new BigDecimal("500000")) // < 1,000,000 min
                .pinToken("valid-pin-token")
                .build();

        assertThatThrownBy(() -> savingsService.openSavings(userId, request))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Số tiền gửi tối thiểu");

        verifyNoInteractions(walletGrpcClient);
    }

    @Test
    @DisplayName("openSavings: Thất bại khi PIN token không hợp lệ")
    void openSavings_FailsWhenPinInvalid() {
        String userId = "user-abc-123";
        OpenSavingsRequest request = OpenSavingsRequest.builder()
                .walletId("wallet-xyz-999")
                .productType("TIET_KIEM_PHAT_LOC")
                .termMonths(6)
                .depositAmount(new BigDecimal("2000000"))
                .pinToken("invalid-pin-token")
                .build();

        doThrow(new IllegalArgumentException("Mã PIN không hợp lệ"))
                .when(pinTokenValidator).validate(eq(userId), eq("invalid-pin-token"));

        assertThatThrownBy(() -> savingsService.openSavings(userId, request))
                .isInstanceOf(IllegalArgumentException.class);

        verifyNoInteractions(walletGrpcClient);
    }

    @Test
    @DisplayName("listUserSavings: Liệt kê đúng danh sách sổ tiết kiệm của người dùng")
    void listUserSavings_Success() {
        String userId = "user-123";
        SavingsAccount sa = SavingsAccount.builder()
                .id(UUID.randomUUID())
                .userId(userId)
                .walletId("wallet-123")
                .accountNumber("TKPL-8888")
                .productType("TIET_KIEM_PHAT_LOC")
                .productName("Tiết Kiệm Phát Lộc")
                .principal(new BigDecimal("5000000"))
                .interestRate(new BigDecimal("7.2"))
                .termMonths(12)
                .expectedInterest(new BigDecimal("360000"))
                .startDate(LocalDate.now())
                .maturityDate(LocalDate.now().plusMonths(12))
                .status("ACTIVE")
                .build();

        when(savingsRepository.findByUserIdOrderByCreatedAtDesc(userId)).thenReturn(List.of(sa));

        List<SavingsAccountResponse> list = savingsService.getUserSavings(userId);

        assertThat(list).hasSize(1);
        assertThat(list.get(0).getAccountNumber()).isEqualTo("TKPL-8888");
        assertThat(list.get(0).getPrincipal()).isEqualByComparingTo("5000000");
    }

    @Test
    @DisplayName("settleSavings: Tất toán sổ trước hạn hưởng lãi không kỳ hạn và hoàn tiền về ví")
    void settleSavings_EarlySettlement_AppliesNonTermRate() {
        String userId = "user-123";
        UUID accountId = UUID.randomUUID();

        SavingsAccount sa = SavingsAccount.builder()
                .id(accountId)
                .userId(userId)
                .walletId("wallet-123")
                .accountNumber("TKPL-1234")
                .principal(new BigDecimal("10000000"))
                .interestRate(new BigDecimal("7.2"))
                .termMonths(12)
                .expectedInterest(new BigDecimal("720000"))
                .startDate(LocalDate.now().minusDays(30))
                .maturityDate(LocalDate.now().plusMonths(11))
                .status("ACTIVE")
                .build();

        when(savingsRepository.findByIdAndUserId(accountId, userId)).thenReturn(Optional.of(sa));
        doNothing().when(pinTokenValidator).validate(eq(userId), eq("valid-pin-token"));
        when(walletGrpcClient.credit(eq("wallet-123"), anyLong(), anyString(), anyString()))
                .thenReturn(com.fintech.payment.grpc.dto.WalletBalanceResult.builder().success(true).balanceAfter(20_000_000L).build());

        SettleSavingsRequest request = SettleSavingsRequest.builder()
                .pinToken("valid-pin-token")
                .build();

        SettleSavingsResponse response = savingsService.settleSavings(accountId.toString(), userId, request);

        assertThat(response).isNotNull();
        assertThat(response.isEarlySettlement()).isTrue();
        assertThat(response.getPrincipalReturned()).isEqualByComparingTo("10000000");
        assertThat(response.getInterestEarned()).isGreaterThan(BigDecimal.ZERO);
        assertThat(response.getTotalPayout()).isGreaterThan(new BigDecimal("10000000"));

        assertThat(sa.getStatus()).isEqualTo("SETTLED");
        verify(walletGrpcClient).credit(eq("wallet-123"), anyLong(), anyString(), anyString());
        verify(savingsRepository).save(sa);
    }
}

