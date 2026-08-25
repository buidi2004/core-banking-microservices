package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.model.AppFeedback;
import com.fintech.wallet.domain.port.in.FeedbackUseCase;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
public class FeedbackService implements FeedbackUseCase {

    private static final Logger log = LoggerFactory.getLogger(FeedbackService.class);

    private final List<AppFeedback> feedbackStore = new ArrayList<>();

    @Override
    public AppFeedback submitFeedback(String userId, int rating, String comment) {
        if (rating < 1 || rating > 5) {
            throw new IllegalArgumentException("Rating must be between 1 and 5");
        }
        AppFeedback feedback = AppFeedback.createNew(userId, rating, comment);
        feedbackStore.add(feedback);
        log.info("Received app feedback from user={}, rating={}", userId, rating);
        return feedback;
    }
}
