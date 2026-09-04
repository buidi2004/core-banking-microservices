package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.model.FeeEstimate;
import com.fintech.wallet.domain.model.KycStatus;
import com.fintech.wallet.domain.model.Money;
import com.fintech.wallet.domain.model.TransactionType;
import com.fintech.wallet.domain.model.User;
import com.fintech.wallet.domain.port.in.FeeEstimationUseCase;
import com.fintech.wallet.domain.port.out.UserPersistencePort;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;

/**
 * Application Service: FeeEstimationService
 * Calculates transaction fees based on transaction type and user's KYC level.
 *
 * Fee schedule:
 * - P2P Transfer (internal): FREE
 * - Withdrawal to bank: 1.1% (min 3,300 VND) — KYC Verified: 50% discount
 * - Phone topup: 1% — KYC Verified: 50% discount
 * - Bill payment: flat 2,200 VND — KYC Verified: FREE
 * - Deposit: FREE
 */
@Service
public class FeeEstimationService implements FeeEstimationUseCase {

    private static final BigDecimal WITHDRAWAL_RATE = new BigDecimal("0.011");
    private static final BigDecimal WITHDRAWAL_MIN_FEE = new BigDecimal("3300");
    private static final BigDecimal TOPUP_RATE = new BigDecimal("0.01");
    private static final BigDecimal BILL_FLAT_FEE = new BigDecimal("2200");
    private static final BigDecimal KYC_DISCOUNT = new BigDecimal("0.5");

    private final UserPersistencePort userPersistencePort;

    public FeeEstimationService(UserPersistencePort userPersistencePort) {
        this.userPersistencePort = userPersistencePort;
    }

    @Override
    public FeeEstimate estimateFee(String userId, TransactionType type, Money amount) {
        if (type == null) {
            throw new IllegalArgumentException("Transaction type cannot be null");
        }
        if (amount == null) {
            throw new IllegalArgumentException("Amount cannot be null");
        }

        KycStatus kycStatus = resolveKycStatus(userId);

        switch (type) {
            case TRANSFER:
                return FeeEstimate.free(type, amount.getAmount(), amount.getCurrency(),
                        "Chuyển tiền nội bộ P2P miễn phí");

            case DEPOSIT:
                return FeeEstimate.free(type, amount.getAmount(), amount.getCurrency(),
                        "Nạp tiền vào ví miễn phí");

            case WITHDRAWAL:
                return calculateWithdrawalFee(type, amount, kycStatus);

            case BILL_PAYMENT:
                return calculateBillPaymentFee(type, amount, kycStatus);

            default:
                // TOPUP handled as generic fee
                return calculateGenericFee(type, amount, kycStatus);
        }
    }

    private FeeEstimate calculateBillPaymentFee(TransactionType type, Money amount, KycStatus kycStatus) {
        BigDecimal fee = BILL_FLAT_FEE;

        if (kycStatus == KycStatus.VERIFIED) {
            fee = BigDecimal.ZERO;
        }

        return FeeEstimate.withFee(type, amount.getAmount(), fee, amount.getCurrency());
    }

    private FeeEstimate calculateWithdrawalFee(TransactionType type, Money amount, KycStatus kycStatus) {
        BigDecimal fee = amount.getAmount().multiply(WITHDRAWAL_RATE)
                .setScale(0, RoundingMode.CEILING);
        fee = fee.max(WITHDRAWAL_MIN_FEE);

        if (kycStatus == KycStatus.VERIFIED) {
            fee = fee.multiply(KYC_DISCOUNT).setScale(0, RoundingMode.CEILING);
        }

        return FeeEstimate.withFee(type, amount.getAmount(), fee, amount.getCurrency());
    }

    private FeeEstimate calculateGenericFee(TransactionType type, Money amount, KycStatus kycStatus) {
        BigDecimal fee;

        // Use topup rate as default for non-standard types
        fee = amount.getAmount().multiply(TOPUP_RATE).setScale(0, RoundingMode.CEILING);

        if (kycStatus == KycStatus.VERIFIED) {
            fee = fee.multiply(KYC_DISCOUNT).setScale(0, RoundingMode.CEILING);
        }

        return FeeEstimate.withFee(type, amount.getAmount(), fee, amount.getCurrency());
    }

    private KycStatus resolveKycStatus(String userId) {
        if (userId == null || userPersistencePort == null) {
            return KycStatus.UNVERIFIED;
        }
        User user = userPersistencePort.findUserById(userId).orElse(null);
        return (user != null && user.getKycStatus() != null) ? user.getKycStatus() : KycStatus.UNVERIFIED;
    }
}
