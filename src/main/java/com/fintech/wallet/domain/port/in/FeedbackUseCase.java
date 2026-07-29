package com.fintech.wallet.domain.port.in;

import com.fintech.wallet.domain.model.AppFeedback;

public interface FeedbackUseCase {
    AppFeedback submitFeedback(String userId, int rating, String comment);
}
