package com.fintech.ledger.presentation.dto;

public class ApiResponse<T> {

    private int code;
    private String message;
    private T data;
    private String timestamp;

    public ApiResponse(int code, String message, T data, String timestamp) {
        this.code = code;
        this.message = message;
        this.data = data;
        this.timestamp = timestamp;
    }

    public static <T> ApiResponse<T> ok(String message, T data) {
        return new ApiResponse(200, message, data, java.time.Instant.now().toString());
    }

    public static <T> ApiResponse<T> created(String message, T data) {
        return new ApiResponse(201, message, data, java.time.Instant.now().toString());
    }

    public int getCode() { return code; }
    public String getMessage() { return message; }
    public T getData() { return data; }
    public String getTimestamp() { return timestamp; }
}
