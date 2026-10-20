package com.fintech.payment.service;

import com.fintech.payment.domain.entity.LotteryDraw;
import com.fintech.payment.domain.entity.LotteryTicket;
import com.fintech.payment.dto.*;
import com.fintech.payment.grpc.WalletGrpcClient;
import com.fintech.payment.grpc.dto.WalletBalanceResult;
import com.fintech.payment.grpc.dto.WalletInfoResult;
import com.fintech.payment.repository.LotteryDrawRepository;
import com.fintech.payment.repository.LotteryTicketRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.text.DecimalFormat;
import java.time.Instant;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class LotteryService {

    private final LotteryDrawRepository drawRepository;
    private final LotteryTicketRepository ticketRepository;
    private final WalletGrpcClient walletGrpcClient;

    private static final long TICKET_UNIT_PRICE = 10_000L;

    @Transactional
    public List<LotteryResultDto> getLatestResults() {
        List<LotteryDraw> draws = drawRepository.findByOrderByCreatedAtDesc();
        if (draws.isEmpty()) {
            seedInitialDraws();
            draws = drawRepository.findByOrderByCreatedAtDesc();
        }
        return draws.stream().map(this::toResultDto).collect(Collectors.toList());
    }

    private void seedInitialDraws() {
        LotteryDraw power = LotteryDraw.builder()
                .id(UUID.randomUUID().toString())
                .gameName("Power 6/55")
                .drawPeriod("Kỳ #01123")
                .drawDate("05/09/2026")
                .winningNumbers("8,15,26,34,47,53")
                .specialNumber(19)
                .jackpot1Amount(68_500_000_000L)
                .jackpot2Amount(4_250_000_000L)
                .winnersJ1(0)
                .winnersJ2(1)
                .build();

        LotteryDraw mega = LotteryDraw.builder()
                .id(UUID.randomUUID().toString())
                .gameName("Mega 6/45")
                .drawPeriod("Kỳ #01289")
                .drawDate("04/09/2026")
                .winningNumbers("5,12,18,29,36,44")
                .specialNumber(null)
                .jackpot1Amount(24_180_000_000L)
                .jackpot2Amount(null)
                .winnersJ1(0)
                .winnersJ2(0)
                .build();

        drawRepository.saveAll(List.of(power, mega));
    }

    private LotteryResultDto toResultDto(LotteryDraw d) {
        DecimalFormat df = new DecimalFormat("#,###");
        List<Integer> nums = Arrays.stream(d.getWinningNumbers().split(","))
                .map(String::trim)
                .map(Integer::parseInt)
                .collect(Collectors.toList());

        String j1 = df.format(d.getJackpot1Amount()).replace(',', '.') + " đ";
        String j2 = d.getJackpot2Amount() != null
                ? df.format(d.getJackpot2Amount()).replace(',', '.') + " đ"
                : null;

        return LotteryResultDto.builder()
                .game(d.getGameName())
                .period(d.getDrawPeriod() + " • " + d.getDrawDate())
                .drawDate(d.getDrawDate())
                .jackpot1(j1)
                .jackpot2(j2)
                .numbers(nums)
                .special(d.getSpecialNumber())
                .winnersJ1(d.getWinnersJ1())
                .winnersJ2(d.getWinnersJ2())
                .build();
    }

    @Transactional
    public LotteryBuyResponse buyTicket(String userId, LotteryBuyRequest req) {
        if (req.getNumbers() == null || req.getNumbers().size() != 6) {
            throw new IllegalArgumentException("Vui lòng chọn đủ 6 chữ số hợp lệ");
        }

        int maxNum = "Power 6/55".equalsIgnoreCase(req.getGameName()) ? 55
                : ("Keno".equalsIgnoreCase(req.getGameName()) ? 80 : 45);

        Set<Integer> uniqueNums = new TreeSet<>(req.getNumbers());
        if (uniqueNums.size() != 6) {
            throw new IllegalArgumentException("Các số chọn không được trùng lặp");
        }
        for (int n : uniqueNums) {
            if (n < 1 || n > maxNum) {
                throw new IllegalArgumentException("Số đã chọn phải nằm trong khoảng từ 01 đến " + maxNum);
            }
        }

        int qty = req.getQuantity() != null && req.getQuantity() > 0 ? req.getQuantity() : 1;
        long totalCost = TICKET_UNIT_PRICE * qty;

        // Trừ tiền ví qua gRPC
        WalletInfoResult wallet = walletGrpcClient.getWalletByUserId(userId);
        if (!wallet.isFound()) {
            throw new IllegalStateException("Không tìm thấy thông tin ví của người dùng");
        }

        String txId = "TXN_LOTTERY_" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
        String idemKey = "idem_lottery_" + UUID.randomUUID();
        WalletBalanceResult debitRes = walletGrpcClient.debit(wallet.getWalletId(), totalCost, txId, idemKey);
        if (!debitRes.isSuccess()) {
            throw new IllegalStateException("Số dư ví không đủ hoặc giao dịch bị từ chối: " + debitRes.getErrorMessage());
        }

        String ticketCode = "VTL-" + (1_000_000 + new Random().nextInt(9_000_000));
        String numbersStr = uniqueNums.stream().map(String::valueOf).collect(Collectors.joining(","));
        String period = req.getDrawPeriod() != null ? req.getDrawPeriod() : "Kỳ #01124";

        LotteryTicket ticket = LotteryTicket.builder()
                .id(UUID.randomUUID().toString())
                .userId(userId)
                .ticketCode(ticketCode)
                .gameName(req.getGameName() != null ? req.getGameName() : "Mega 6/45")
                .drawPeriod(period)
                .selectedNumbers(numbersStr)
                .amount(totalCost)
                .quantity(qty)
                .status("CHỜ MỞ THƯỞNG")
                .winningAmount(0L)
                .createdAt(Instant.now())
                .build();

        ticketRepository.save(ticket);
        log.info("Lottery ticket purchased successfully: user={}, ticket={}, amount={}", userId, ticketCode, totalCost);

        return LotteryBuyResponse.builder()
                .ticketCode(ticketCode)
                .gameName(ticket.getGameName())
                .drawPeriod(period)
                .numbers(new ArrayList<>(uniqueNums))
                .amount(totalCost)
                .quantity(qty)
                .status("CHỜ MỞ THƯỞNG")
                .message("Mua vé số Vietlott thành công")
                .build();
    }

    @Transactional(readOnly = true)
    public List<LotteryTicketDto> getUserTickets(String userId) {
        List<LotteryTicket> tickets = ticketRepository.findByUserIdOrderByCreatedAtDesc(userId);
        return tickets.stream().map(t -> {
            List<Integer> nums = Arrays.stream(t.getSelectedNumbers().split(","))
                    .map(String::trim)
                    .map(Integer::parseInt)
                    .collect(Collectors.toList());

            return LotteryTicketDto.builder()
                    .code(t.getTicketCode())
                    .game(t.getGameName())
                    .drawDate("18:00 - Hôm nay")
                    .drawPeriod(t.getDrawPeriod())
                    .numbers(nums)
                    .specialNum(null)
                    .amount(t.getAmount())
                    .quantity(t.getQuantity())
                    .status(t.getStatus())
                    .canCheck("CHỜ MỞ THƯỞNG".equalsIgnoreCase(t.getStatus()))
                    .build();
        }).collect(Collectors.toList());
    }
}

