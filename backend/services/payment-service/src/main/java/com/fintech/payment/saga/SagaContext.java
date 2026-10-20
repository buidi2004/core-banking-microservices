package com.fintech.payment.saga;

import lombok.Getter;
import lombok.Setter;

/**
 * Bối cảnh Saga P2P Transfer - truyền trạng thái giữa các bước điều phối.
 */
@Getter
@Setter
public class SagaContext {
    private String transactionId;
    private String transactionCode;
    private String idempotencyKey;
    private String sourceWalletId;
    private String targetWalletId;
    private String sourceUserId;
    private String targetUserId;
    private Long amount;
    private Long fee;
    private String currency;
    private String note;

    private String sourceBalanceAfter;
    private String targetBalanceAfter;

    private String currentStep;
    private String status; // INITIATED, DEBITED, CREDITED, SUCCESS, FAILED, REVERSED
    private String failureReason;

    private String reservationId;
    private boolean reversed = false;

    public SagaContext sourceDebited(String balanceAfter) {
        this.status = "DEBITED";
        this.sourceBalanceAfter = balanceAfter;
        this.currentStep = "DEBITED";
        return this;
    }

    public SagaContext targetCredited(String balanceAfter) {
        this.status = "CREDITED";
        this.targetBalanceAfter = balanceAfter;
        this.currentStep = "CREDITED";
        return this;
    }

    public SagaContext succeeded() {
        this.status = "SUCCESS";
        this.currentStep = "SUCCESS";
        return this;
    }

    public SagaContext failed(String reason) {
        this.status = "FAILED";
        this.failureReason = reason;
        this.currentStep = "FAILED";
        return this;
    }

    public SagaContext reversed() {
        this.status = "REVERSED";
        this.reversed = true;
        this.currentStep = "REVERSED";
        return this;
    }
}
