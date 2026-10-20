package com.fintech.payment.controller;

import com.fintech.payment.dto.*;
import com.fintech.payment.service.CardService;
import jakarta.validation.Valid;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Slf4j
@RestController
@RequestMapping("/api/v1/cards")
public class CardController {

    private final CardService cardService;

    public CardController(CardService cardService) {
        this.cardService = cardService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<CardDto>>> getCards(
            @RequestHeader(value = "X-User-Id", defaultValue = "test-user") String userId,
            @RequestHeader(value = "X-User-Name", required = false) String userName) {
        List<CardDto> cards = cardService.getUserCards(userId, userName);
        return ResponseEntity.ok(ApiResponse.success("Danh sách thẻ thanh toán", cards));
    }

    @PostMapping("/issue")
    public ResponseEntity<ApiResponse<CardDto>> issueCard(
            @RequestHeader(value = "X-User-Id", defaultValue = "test-user") String userId,
            @RequestHeader(value = "X-User-Name", required = false) String userName,
            @Valid @RequestBody CardIssueRequest request) {
        CardDto card = cardService.issueCard(userId, userName, request);
        return ResponseEntity.ok(ApiResponse.success("Phát hành thẻ thành công", card));
    }

    @PatchMapping("/{id}/status")
    public ResponseEntity<ApiResponse<CardDto>> updateCardStatus(
            @RequestHeader(value = "X-User-Id", defaultValue = "test-user") String userId,
            @PathVariable("id") String cardId,
            @Valid @RequestBody CardStatusRequest request) {
        CardDto card = cardService.updateCardStatus(userId, cardId, request);
        return ResponseEntity.ok(ApiResponse.success("Cập nhật trạng thái thẻ thành công", card));
    }

    @PutMapping("/{id}/settings")
    public ResponseEntity<ApiResponse<CardDto>> updateCardSettings(
            @RequestHeader(value = "X-User-Id", defaultValue = "test-user") String userId,
            @PathVariable("id") String cardId,
            @RequestBody CardSettingsRequest request) {
        CardDto card = cardService.updateCardSettings(userId, cardId, request);
        return ResponseEntity.ok(ApiResponse.success("Cập nhật tính năng thẻ thành công", card));
    }
}

