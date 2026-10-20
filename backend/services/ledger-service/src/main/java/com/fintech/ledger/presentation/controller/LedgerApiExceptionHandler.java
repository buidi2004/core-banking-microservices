package com.fintech.ledger.presentation.controller;

import com.fintech.ledger.domain.exception.LedgerUnbalancedException;
import com.fintech.ledger.presentation.dto.ApiErrorResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.time.Instant;
import java.util.NoSuchElementException;

@RestControllerAdvice
public class LedgerApiExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(LedgerApiExceptionHandler.class);

    @ExceptionHandler(LedgerUnbalancedException.class)
    public ResponseEntity<ApiErrorResponse> handleUnbalanced(LedgerUnbalancedException e) {
        log.warn("Ledger invariant violated: {}", e.getMessage());
        return ResponseEntity.status(HttpStatus.UNPROCESSABLE_ENTITY)
                .body(new ApiErrorResponse(422, e.getMessage(), Instant.now().toString()));
    }

    @ExceptionHandler(NoSuchElementException.class)
    public ResponseEntity<ApiErrorResponse> handleNotFound(NoSuchElementException e) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(new ApiErrorResponse(404, e.getMessage() != null ? e.getMessage() : "Resource not found",
                        Instant.now().toString()));
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<ApiErrorResponse> handleBadRequest(IllegalArgumentException e) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(new ApiErrorResponse(400, e.getMessage(), Instant.now().toString()));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiErrorResponse> handleGeneric(Exception e) {
        log.error("Unhandled error on ledger API", e);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(new ApiErrorResponse(500, "Internal ledger service error",
                        Instant.now().toString()));
    }
}
