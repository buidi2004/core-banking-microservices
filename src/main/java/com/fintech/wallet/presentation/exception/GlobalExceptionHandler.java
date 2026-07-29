package com.fintech.wallet.presentation.exception;

import com.fintech.wallet.domain.exception.InsufficientBalanceException;
import com.fintech.wallet.domain.exception.InvalidMoneyException;
import com.fintech.wallet.domain.exception.InvalidPinException;
import com.fintech.wallet.domain.exception.KycRequiredException;
import com.fintech.wallet.domain.exception.LedgerUnbalancedException;
import com.fintech.wallet.domain.exception.LockAcquisitionException;
import com.fintech.wallet.domain.exception.TransactionLimitExceededException;
import com.fintech.wallet.domain.exception.WalletNotFoundException;
import com.fintech.wallet.presentation.response.ApiResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.orm.ObjectOptimisticLockingFailureException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.stream.Collectors;

@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    @ExceptionHandler(WalletNotFoundException.class)
    public ResponseEntity<ApiResponse<Void>> handleWalletNotFound(WalletNotFoundException ex) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(ApiResponse.error(ex.getMessage()));
    }

    @ExceptionHandler(InsufficientBalanceException.class)
    public ResponseEntity<ApiResponse<Void>> handleInsufficientBalance(InsufficientBalanceException ex) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ApiResponse.error(ex.getMessage()));
    }

    @ExceptionHandler(InvalidMoneyException.class)
    public ResponseEntity<ApiResponse<Void>> handleInvalidMoney(InvalidMoneyException ex) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ApiResponse.error(ex.getMessage()));
    }

    @ExceptionHandler(InvalidPinException.class)
    public ResponseEntity<ApiResponse<Void>> handleInvalidPin(InvalidPinException ex) {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(ApiResponse.error(ex.getMessage()));
    }

    @ExceptionHandler(KycRequiredException.class)
    public ResponseEntity<ApiResponse<Void>> handleKycRequired(KycRequiredException ex) {
        return ResponseEntity.status(HttpStatus.FORBIDDEN)
                .body(ApiResponse.error(ex.getMessage()));
    }

    @ExceptionHandler(LedgerUnbalancedException.class)
    public ResponseEntity<ApiResponse<Void>> handleLedgerUnbalanced(LedgerUnbalancedException ex) {
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiResponse.error(ex.getMessage()));
    }

    @ExceptionHandler(TransactionLimitExceededException.class)
    public ResponseEntity<ApiResponse<Void>> handleTransactionLimitExceeded(TransactionLimitExceededException ex) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ApiResponse.error(ex.getMessage()));
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<ApiResponse<Void>> handleIllegalArgument(IllegalArgumentException ex) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ApiResponse.error(ex.getMessage()));
    }

    @ExceptionHandler(LockAcquisitionException.class)
    public ResponseEntity<ApiResponse<Void>> handleLockAcquisition(LockAcquisitionException ex) {
        return ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS)
                .body(ApiResponse.error("System is busy processing this transaction. Please retry."));
    }

    // Bug #5 companion: Optimistic locking conflict → tell client to retry
    @ExceptionHandler(ObjectOptimisticLockingFailureException.class)
    public ResponseEntity<ApiResponse<Void>> handleOptimisticLock(ObjectOptimisticLockingFailureException ex) {
        log.warn("Optimistic locking conflict: {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.CONFLICT)
                .body(ApiResponse.error("Concurrent modification detected. Please retry your transaction."));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResponse<Void>> handleValidationErrors(MethodArgumentNotValidException ex) {
        String errorMessage = ex.getBindingResult().getFieldErrors().stream()
                .map(error -> error.getField() + ": " + error.getDefaultMessage())
                .collect(Collectors.joining(", "));
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ApiResponse.error("Validation failed: " + errorMessage));
    }

    // Bug #7 fix: never expose internal exception details to external clients
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<Void>> handleGenericException(Exception ex) {
        log.error("Unexpected internal error", ex);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiResponse.error("An unexpected error occurred. Please contact support."));
    }
}
