package com.fintech.wallet.service;

import com.fintech.wallet.domain.entity.Wallet;
import com.fintech.wallet.repository.WalletRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.util.UUID;

/**
 * Business logic gRPC Wallet Service: Debit/Credit/Reserve/Release/CheckLimit/GetWalletByUserId.
 * Sử dụng pessimistic lock (SELECT FOR UPDATE) và Redis idempotency để đảm bảo không trùng xử lý.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class WalletGrpcService {

    private static final String IDEMPOTENCY_PREFIX = "wallet:tx:processed:";
    private static final long IDEMPOTENCY_TTL_SECONDS = 86400;

    private final WalletRepository walletRepository;
    private final StringRedisTemplate redisTemplate;

    /* ======================== DEBIT ======================== */

    @Transactional
    public DebitResult debitWallet(String walletId, Long amount, String transactionId, String idempotencyKey) {
        if (!isIdempotent(transactionId)) {
            return DebitResult.failure("DEBIT_IDEMPOTENT", "Giao dịch đã được xử lý: " + transactionId);
        }

        Wallet wallet = walletRepository.findByIdForUpdate(walletId)
                .orElseThrow(() -> new IllegalArgumentException("Wallet not found: " + walletId));

        if (!wallet.isActive()) {
            return DebitResult.failure("DEBIT_WALLET_FROZEN", "Ví không hoạt động: " + walletId);
        }

        if (wallet.getBalance() == null || wallet.getBalance() < amount) {
            return DebitResult.failure("DEBIT_INSUFFICIENT_BALANCE", "Không đủ số dư");
        }

        wallet.setBalance(wallet.getBalance() - amount);
        walletRepository.save(wallet);

        return DebitResult.success(wallet.getBalance());
    }

    /* ======================== CREDIT ======================== */

    @Transactional
    public CreditResult creditWallet(String walletId, Long amount, String transactionId, String idempotencyKey) {
        if (!isIdempotent(transactionId)) {
            return CreditResult.failure("CREDIT_IDEMPOTENT", "Giao dịch đã được xử lý: " + transactionId);
        }

        Wallet wallet = walletRepository.findByIdForUpdate(walletId)
                .orElseThrow(() -> new IllegalArgumentException("Wallet not found: " + walletId));

        if (!wallet.isActive()) {
            return CreditResult.failure("CREDIT_WALLET_FROZEN", "Ví không hoạt động: " + walletId);
        }

        wallet.setBalance(wallet.getBalance() + amount);
        walletRepository.save(wallet);

        return CreditResult.success(wallet.getBalance());
    }

    /* ======================== RESERVE ======================== */

    @Transactional
    public ReserveResult reserveBalance(String walletId, Long amount, String transactionId, int reserveDurationSeconds) {
        Wallet wallet = walletRepository.findByIdForUpdate(walletId)
                .orElseThrow(() -> new IllegalArgumentException("Wallet not found: " + walletId));

        if (!wallet.isActive()) {
            return ReserveResult.failure("RESERVE_WALLET_FROZEN", "Ví không hoạt động");
        }

        Long available = wallet.availableBalance();
        if (available == null || available < amount) {
            return ReserveResult.failure("RESERVE_INSUFFICIENT", "Không đủ số dư khả dụng");
        }

        wallet.setReservedBalance(wallet.getReservedBalance() + amount);
        String reservationId = UUID.randomUUID().toString();
        walletRepository.save(wallet);

        // Lưu reservation vào Redis để release sau này
        redisTemplate.opsForValue()
                .setIfAbsent("wallet:reservation:" + reservationId, walletId + ":" + amount,
                        Duration.ofSeconds(reserveDurationSeconds > 0 ? reserveDurationSeconds : 3600));

        return ReserveResult.success(amount, reservationId);
    }

    /* ======================== RELEASE ======================== */

    @Transactional
    public ReleaseResult releaseBalance(String reservationId, String transactionId) {
        String raw = redisTemplate.opsForValue().get("wallet:reservation:" + reservationId);
        if (raw == null) {
            return ReleaseResult.failure("RELEASE_NOT_FOUND", "Không tìm thấy reservation: " + reservationId);
        }

        String[] parts = raw.split(":");
        String walletId = parts[0];
        Long amount = Long.valueOf(parts[1]);

        Wallet wallet = walletRepository.findByIdForUpdate(walletId)
                .orElseThrow(() -> new IllegalArgumentException("Wallet not found: " + walletId));

        wallet.setReservedBalance(Math.max(0L, wallet.getReservedBalance() - amount));
        walletRepository.save(wallet);

        redisTemplate.delete("wallet:reservation:" + reservationId);
        return ReleaseResult.success();
    }

    /* ======================== CHECK LIMIT ======================== */

    public LimitCheckResult checkLimit(String walletId, Long amount, String transactionType, String userId) {
        Wallet wallet = walletRepository.findById(walletId)
                .orElseThrow(() -> new IllegalArgumentException("Wallet not found: " + walletId));

        Long available = wallet.availableBalance();
        boolean allowed = wallet.isActive() && available != null && available >= amount;

        Long dailyRemaining = wallet.getDailyLimit() - (wallet.getDailySpent() != null ? wallet.getDailySpent() : 0L);

        return LimitCheckResult.builder()
                .allowed(allowed)
                .availableBalance(available)
                .dailyLimitRemaining(dailyRemaining > 0 ? dailyRemaining : 0L)
                .transactionLimitRemaining(available)
                .errorCode(allowed ? null : "LIMIT_EXCEEDED")
                .errorMessage(allowed ? null : "Vượt hạn mức hoặc không đủ số dư")
                .build();
    }

    /* ======================== GET WALLET BY USER ID ======================== */

    public GetWalletResult getWalletByUserId(String userId) {
        Wallet wallet = walletRepository.findByUserId(userId)
                .orElse(null);
        if (wallet == null) {
            return GetWalletResult.notFound();
        }
        return GetWalletResult.found(wallet.getId(), wallet.getUserId(), wallet.getBalance(),
                wallet.getCurrency(), wallet.getStatus());
    }

    /* ======================== Helpers ======================== */

    private boolean isIdempotent(String transactionId) {
        if (transactionId == null) return true;
        String key = IDEMPOTENCY_PREFIX + transactionId;
        Boolean set = redisTemplate.opsForValue().setIfAbsent(key, "1", Duration.ofSeconds(IDEMPOTENCY_TTL_SECONDS));
        return Boolean.TRUE.equals(set);
    }

    /* ======================== Result types ======================== */

    public static class DebitResult {
        public final boolean success;
        public final Long balanceAfter;
        public final String errorCode;
        public final String errorMessage;

        private DebitResult(boolean success, Long balanceAfter, String errorCode, String errorMessage) {
            this.success = success; this.balanceAfter = balanceAfter;
            this.errorCode = errorCode; this.errorMessage = errorMessage;
        }

        public static DebitResult success(Long balanceAfter) {
            return new DebitResult(true, balanceAfter, null, null);
        }

        public static DebitResult failure(String errorCode, String errorMessage) {
            return new DebitResult(false, null, errorCode, errorMessage);
        }
    }

    public static class CreditResult {
        public final boolean success;
        public final Long balanceAfter;
        public final String errorCode;
        public final String errorMessage;

        private CreditResult(boolean success, Long balanceAfter, String errorCode, String errorMessage) {
            this.success = success; this.balanceAfter = balanceAfter;
            this.errorCode = errorCode; this.errorMessage = errorMessage;
        }

        public static CreditResult success(Long balanceAfter) {
            return new CreditResult(true, balanceAfter, null, null);
        }

        public static CreditResult failure(String errorCode, String errorMessage) {
            return new CreditResult(false, null, errorCode, errorMessage);
        }
    }

    public static class ReserveResult {
        public final boolean success;
        public final Long reservedAmount;
        public final String reservationId;
        public final String errorCode;
        public final String errorMessage;

        private ReserveResult(boolean success, Long reservedAmount, String reservationId, String errorCode, String errorMessage) {
            this.success = success; this.reservedAmount = reservedAmount;
            this.reservationId = reservationId; this.errorCode = errorCode; this.errorMessage = errorMessage;
        }

        public static ReserveResult success(Long reservedAmount, String reservationId) {
            return new ReserveResult(true, reservedAmount, reservationId, null, null);
        }

        public static ReserveResult failure(String errorCode, String errorMessage) {
            return new ReserveResult(false, null, null, errorCode, errorMessage);
        }
    }

    public static class ReleaseResult {
        public final boolean success;
        public final String errorCode;
        public final String errorMessage;

        private ReleaseResult(boolean success, String errorCode, String errorMessage) {
            this.success = success; this.errorCode = errorCode; this.errorMessage = errorMessage;
        }

        public static ReleaseResult success() {
            return new ReleaseResult(true, null, null);
        }

        public static ReleaseResult failure(String errorCode, String errorMessage) {
            return new ReleaseResult(false, errorCode, errorMessage);
        }
    }

    public static class LimitCheckResult {
        public final boolean allowed;
        public final Long availableBalance;
        public final Long dailyLimitRemaining;
        public final Long transactionLimitRemaining;
        public final String errorCode;
        public final String errorMessage;

        private LimitCheckResult(boolean allowed, Long availableBalance, Long dailyLimitRemaining,
                                 Long transactionLimitRemaining, String errorCode, String errorMessage) {
            this.allowed = allowed;
            this.availableBalance = availableBalance;
            this.dailyLimitRemaining = dailyLimitRemaining;
            this.transactionLimitRemaining = transactionLimitRemaining;
            this.errorCode = errorCode;
            this.errorMessage = errorMessage;
        }

        public static Builder builder() {
            return new Builder();
        }

        public static class Builder {
            private boolean allowed;
            private Long availableBalance;
            private Long dailyLimitRemaining;
            private Long transactionLimitRemaining;
            private String errorCode;
            private String errorMessage;

            public Builder allowed(boolean allowed) { this.allowed = allowed; return this; }
            public Builder availableBalance(Long availableBalance) { this.availableBalance = availableBalance; return this; }
            public Builder dailyLimitRemaining(Long dailyLimitRemaining) { this.dailyLimitRemaining = dailyLimitRemaining; return this; }
            public Builder transactionLimitRemaining(Long transactionLimitRemaining) { this.transactionLimitRemaining = transactionLimitRemaining; return this; }
            public Builder errorCode(String errorCode) { this.errorCode = errorCode; return this; }
            public Builder errorMessage(String errorMessage) { this.errorMessage = errorMessage; return this; }
            public LimitCheckResult build() {
                return new LimitCheckResult(allowed, availableBalance, dailyLimitRemaining, transactionLimitRemaining, errorCode, errorMessage);
            }
        }
    }

    public static class GetWalletResult {
        public final boolean found;
        public final String walletId;
        public final String userId;
        public final Long balance;
        public final String currency;
        public final String status;
        public final String errorCode;
        public final String errorMessage;

        private GetWalletResult(boolean found, String walletId, String userId, Long balance, String currency, String status,
                                String errorCode, String errorMessage) {
            this.found = found; this.walletId = walletId; this.userId = userId;
            this.balance = balance; this.currency = currency; this.status = status;
            this.errorCode = errorCode; this.errorMessage = errorMessage;
        }

        public static GetWalletResult found(String walletId, String userId, Long balance, String currency, String status) {
            return new GetWalletResult(true, walletId, userId, balance, currency, status, null, null);
        }

        public static GetWalletResult notFound() {
            return new GetWalletResult(false, null, null, null, null, null, "WALLET_NOT_FOUND", "Không tìm thấy ví");
        }
    }
}
