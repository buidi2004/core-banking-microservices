package com.fintech.payment.controller;

import com.fintech.payment.dto.*;
import com.fintech.payment.service.LotteryService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/lottery")
@RequiredArgsConstructor
@Slf4j
public class LotteryController {

    private final LotteryService lotteryService;

    @GetMapping("/results")
    public ResponseEntity<ApiResponse<List<LotteryResultDto>>> getLatestResults() {
        log.info("Fetching latest lottery draw results");
        List<LotteryResultDto> results = lotteryService.getLatestResults();
        return ResponseEntity.ok(ApiResponse.success("Lấy kết quả xổ số thành công", results));
    }

    @GetMapping("/my-tickets")
    public ResponseEntity<ApiResponse<List<LotteryTicketDto>>> getMyTickets(
            @RequestHeader(value = "X-User-Id", defaultValue = "user-test") String userId) {
        log.info("Fetching lottery tickets for user: {}", userId);
        List<LotteryTicketDto> tickets = lotteryService.getUserTickets(userId);
        return ResponseEntity.ok(ApiResponse.success("Lấy danh sách vé đã mua thành công", tickets));
    }

    @PostMapping("/buy")
    public ResponseEntity<ApiResponse<LotteryBuyResponse>> buyTicket(
            @RequestHeader(value = "X-User-Id", defaultValue = "user-test") String userId,
            @Valid @RequestBody LotteryBuyRequest request) {
        log.info("User {} buying lottery ticket: game={}, quantity={}", userId, request.getGameName(), request.getQuantity());
        LotteryBuyResponse response = lotteryService.buyTicket(userId, request);
        return ResponseEntity.ok(ApiResponse.success("Mua vé số thành công", response));
    }
}
