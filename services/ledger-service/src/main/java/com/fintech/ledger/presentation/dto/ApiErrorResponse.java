package com.fintech.ledger.presentation.dto;

import com.fasterxml.jackson.annotation.JsonInclude;

@JsonInclude(JsonInclude.Include.NON_NULL)
public class ApiErrorResponse {

    private int code;
    private String message;
    private String timestamp;

    public ApiErrorResponse(int code, String message, String timestamp) {
        this.code = code;
        this.message = message;
        this.timestamp = timestamp;
    }

    public int getCode() { return code; }
    public String getMessage() { return message; }
    public String getTimestamp() { return timestamp; }
}
