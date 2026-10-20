package com.fintech.identity.controller;

import com.fintech.identity.dto.ApiResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/v1/feedback")
@RequiredArgsConstructor
public class FeedbackController {

    @PostMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> submitFeedback(
            @RequestHeader("X-User-Id") String userId,
            @RequestBody Map<String, Object> payload) {
        log.info("Received feedback from user {}: {}", userId, payload);
        return ResponseEntity.ok(ApiResponse.ok(
                Map.of("submitted", true, "thankYouMessage", "Cảm ơn bạn đã đóng góp ý kiến xây dựng Sen Hồng Bank!"),
                "Gửi ý kiến phản hồi thành công"
        ));
    }
}

