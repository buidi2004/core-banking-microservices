package com.fintech.payment.service;

import com.fintech.payment.domain.entity.LotteryDraw;
import com.fintech.payment.domain.entity.LotteryTicket;
import com.fintech.payment.dto.LotteryBuyRequest;
import com.fintech.payment.dto.LotteryBuyResponse;
import com.fintech.payment.dto.LotteryResultDto;
import com.fintech.payment.dto.LotteryTicketDto;
import com.fintech.payment.grpc.WalletGrpcClient;
import com.fintech.payment.grpc.dto.WalletBalanceResult;
import com.fintech.payment.grpc.dto.WalletInfoResult;
import com.fintech.payment.repository.LotteryDrawRepository;
import com.fintech.payment.repository.LotteryTicketRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.ArrayList;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class LotteryServiceTest {

    @Mock private LotteryDrawRepository drawRepository;
    @Mock private LotteryTicketRepository ticketRepository;
    @Mock private WalletGrpcClient walletGrpcClient;

    @InjectMocks private LotteryService lotteryService;

    private static final String USER_ID = "user-lottery-123";

    @Test
    @DisplayName("getLatestResults tự động seed khi chưa có kết quả")
    void getLatestResults_SeedsWhenEmpty() {
        when(drawRepository.findByOrderByCreatedAtDesc()).thenReturn(new ArrayList<>()).thenReturn(List.of(
                LotteryDraw.builder()
                        .gameName("Power 6/55")
                        .drawPeriod("Kỳ #01123")
                        .drawDate("05/09/2026")
                        .winningNumbers("8,15,26,34,47,53")
                        .specialNumber(19)
                        .jackpot1Amount(68_500_000_000L)
                        .jackpot2Amount(4_250_000_000L)
                        .winnersJ1(0)
                        .winnersJ2(1)
                        .build()
        ));

        List<LotteryResultDto> results = lotteryService.getLatestResults();
        assertThat(results).hasSize(1);
        assertThat(results.get(0).getGame()).isEqualTo("Power 6/55");
        assertThat(results.get(0).getNumbers()).containsExactly(8, 15, 26, 34, 47, 53);
    }

    @Test
    @DisplayName("buyTicket thành công và trừ tiền ví qua gRPC")
    void buyTicket_Success() {
        LotteryBuyRequest req = LotteryBuyRequest.builder()
                .gameName("Mega 6/45")
                .numbers(List.of(3, 12, 18, 27, 35, 42))
                .quantity(2)
                .drawPeriod("Kỳ #01124")
                .build();

        when(walletGrpcClient.getWalletByUserId(USER_ID)).thenReturn(
                WalletInfoResult.builder().found(true).walletId("wallet-123").balance(1_000_000L).build());

        when(walletGrpcClient.debit(eq("wallet-123"), eq(20_000L), anyString(), anyString())).thenReturn(
                WalletBalanceResult.builder().success(true).balanceAfter(980_000L).build());

        LotteryBuyResponse res = lotteryService.buyTicket(USER_ID, req);

        assertThat(res.getTicketCode()).startsWith("VTL-");
        assertThat(res.getAmount()).isEqualTo(20_000L);
        assertThat(res.getNumbers()).containsExactly(3, 12, 18, 27, 35, 42);
        verify(ticketRepository).save(any(LotteryTicket.class));
    }

    @Test
    @DisplayName("buyTicket thất bại khi chọn không đủ 6 số hoặc có số trùng")
    void buyTicket_FailsInvalidNumbers() {
        LotteryBuyRequest req = LotteryBuyRequest.builder()
                .gameName("Mega 6/45")
                .numbers(List.of(3, 12, 18, 18, 35, 42)) // 18 trùng
                .quantity(1)
                .build();

        assertThatThrownBy(() -> lotteryService.buyTicket(USER_ID, req))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Các số chọn không được trùng lặp");
    }

    @Test
    @DisplayName("getUserTickets trả về danh sách vé của người dùng")
    void getUserTickets_Success() {
        when(ticketRepository.findByUserIdOrderByCreatedAtDesc(USER_ID)).thenReturn(List.of(
                LotteryTicket.builder()
                        .ticketCode("VTL-8829104")
                        .gameName("Power 6/55")
                        .drawPeriod("Kỳ #01124")
                        .selectedNumbers("7,14,22,33,45,52")
                        .amount(20000L)
                        .quantity(2)
                        .status("CHỜ MỞ THƯỞNG")
                        .build()
        ));

        List<LotteryTicketDto> tickets = lotteryService.getUserTickets(USER_ID);
        assertThat(tickets).hasSize(1);
        assertThat(tickets.get(0).getCode()).isEqualTo("VTL-8829104");
        assertThat(tickets.get(0).isCanCheck()).isTrue();
    }
}

