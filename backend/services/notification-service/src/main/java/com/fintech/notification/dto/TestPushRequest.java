package com.fintech.notification.dto;

import jakarta.validation.constraints.NotBlank;

public record TestPushRequest(
        @NotBlank(message = "userId is required")
        String userId,

        @NotBlank(message = "title is required")
        String title,

        @NotBlank(message = "body is required")
        String body,

        String channel
) {}
