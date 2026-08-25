package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.model.KycStatus;
import com.fintech.wallet.domain.model.LegalConsent;
import com.fintech.wallet.domain.model.User;
import com.fintech.wallet.domain.model.UserLimitStatus;
import com.fintech.wallet.domain.model.Wallet;
import com.fintech.wallet.domain.port.in.LegalConfigUseCase;
import com.fintech.wallet.domain.port.out.TransactionPersistencePort;
import com.fintech.wallet.domain.port.out.UserPersistencePort;
import com.fintech.wallet.domain.port.out.WalletPersistencePort;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class LegalConfigService implements LegalConfigUseCase {

    private static final Logger log = LoggerFactory.getLogger(LegalConfigService.class);

    private final UserPersistencePort userPersistencePort;
    private final TransactionPersistencePort transactionPersistencePort;
    private final WalletPersistencePort walletPersistencePort;
    private final List<LegalConsent> consentStore = new ArrayList<>();

    public LegalConfigService(UserPersistencePort userPersistencePort,
                              TransactionPersistencePort transactionPersistencePort,
                              WalletPersistencePort walletPersistencePort) {
        this.userPersistencePort = userPersistencePort;
        this.transactionPersistencePort = transactionPersistencePort;
        this.walletPersistencePort = walletPersistencePort;
    }

    @Override
    public Map<String, Object> getUserLimits(String userId) {
        User user = userPersistencePort != null ? userPersistencePort.findUserById(userId).orElse(null) : null;
        KycStatus status = user != null && user.getKycStatus() != null ? user.getKycStatus() : KycStatus.UNVERIFIED;

        Map<String, Object> limits = new HashMap<>();
        limits.put("kycStatus", status.name());
        limits.put("dailyLimit", status == KycStatus.VERIFIED ? "100000000" : "5000000");
        limits.put("monthlyLimit", status == KycStatus.VERIFIED ? "500000000" : "20000000");
        limits.put("currency", "VND");
        return limits;
    }

    @Override
    public String getTermsOfService() {
        return "Điều khoản dịch vụ Ví điện tử Fintech v1.0. Tất cả giao dịch tuân thủ quy định NHNN.";
    }

    @Override
    public LegalConsent recordConsent(String userId, String termsVersion, String ipAddress, String userAgent) {
        LegalConsent consent = LegalConsent.createNew(userId, termsVersion, ipAddress, userAgent);
        consentStore.add(consent);
        log.info("Recorded legal consent for user={}, version={}", userId, termsVersion);
        return consent;
    }

    @Override
    public UserLimitStatus getUserLimitStatus(String userId) {
        if (userId == null || userId.isBlank()) {
            throw new IllegalArgumentException("User ID cannot be null or empty");
        }

        User user = userPersistencePort != null ? userPersistencePort.findUserById(userId).orElse(null) : null;
        KycStatus status = user != null && user.getKycStatus() != null ? user.getKycStatus() : KycStatus.UNVERIFIED;

        BigDecimal dailyLimit = (status == KycStatus.VERIFIED)
                ? new BigDecimal("100000000")
                : new BigDecimal("5000000");

        BigDecimal monthlyLimit = (status == KycStatus.VERIFIED)
                ? new BigDecimal("500000000")
                : new BigDecimal("20000000");

        // Calculate actual spent amounts
        BigDecimal dailySpent = BigDecimal.ZERO;
        BigDecimal monthlySpent = BigDecimal.ZERO;

        if (walletPersistencePort != null && transactionPersistencePort != null) {
            Wallet wallet = walletPersistencePort.findWalletByOwnerId(userId).orElse(null);
            if (wallet != null) {
                Instant startOfDay = LocalDate.now(ZoneOffset.UTC).atStartOfDay(ZoneOffset.UTC).toInstant();
                Instant startOfMonth = LocalDate.now(ZoneOffset.UTC).withDayOfMonth(1)
                        .atStartOfDay(ZoneOffset.UTC).toInstant();

                dailySpent = transactionPersistencePort.calculateDailySpentByWalletId(wallet.getId(), startOfDay);
                monthlySpent = transactionPersistencePort.calculateMonthlySpentByWalletId(wallet.getId(), startOfMonth);
            }
        }

        return new UserLimitStatus(status, dailyLimit, dailySpent, monthlyLimit, monthlySpent, "VND");
    }
}

