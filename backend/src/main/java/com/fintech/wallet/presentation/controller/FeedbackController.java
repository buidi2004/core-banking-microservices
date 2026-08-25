package com.fintech.wallet.presentation.controller;

import com.fintech.wallet.domain.model.AppFeedback;
import com.fintech.wallet.domain.port.in.FeedbackUseCase;
import com.fintech.wallet.presentation.response.ApiResponse;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/feedback")
public class FeedbackController {

    private final FeedbackUseCase feedbackUseCase;

    public FeedbackController(FeedbackUseCase feedbackUseCase) {
        this.feedbackUseCase = feedbackUseCase;
    }

    @PostMapping
    public ResponseEntity<ApiResponse<AppFeedback>> submitFeedback(
            Authentication auth,
            @RequestParam int rating,
            @RequestParam(required = false) String comment) {
        String userId = auth.getName();
        AppFeedback feedback = feedbackUseCase.submitFeedback(userId, rating, comment);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("App feedback submitted successfully", feedback));
    }
}
