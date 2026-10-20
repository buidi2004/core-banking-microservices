package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.exception.InsufficientBalanceException;
import com.fintech.wallet.domain.exception.LockAcquisitionException;
import com.fintech.wallet.domain.exception.WalletNotFoundException;
import com.fintech.wallet.domain.model.Money;
import com.fintech.wallet.domain.model.Wallet;
import com.fintech.wallet.domain.port.out.DistributedLockPort;
import com.fintech.wallet.domain.port.out.WalletPersistencePort;
import com.fintech.wallet.infrastructure.kafka.WalletBalanceChangedKafkaProducer;
import com.fintech.wallet.kafka.WalletBalanceChangedPayload;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.Duration;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Application Service cho WalletInternalService gRPC.
 * Cung cấp các nghiệp vụ nội bộ: Debit, Credit, Reserve, Release, CheckLimit, GetWalletByUserId.
 * Sử dụng Pessimistic Lock (SELECT ... FOR UPDATE) kết hợp Redis Lock để đảm bảo concurrency an toàn.
 *
 * Mỗi lần số dư thay đổi (Debit/Credit/Reserve/Release) → tự động publish event
 * vào Kafka topic {@code banking.wallet.balance-changed.v1} với Partition Key = walletId.
 */
@Service
public class WalletInternalApplicationService {

    private static final Logger log = LoggerFactory.getLogger(WalletInternalApplicationService.class);

    private static final long LOCK_TIMEOUT_SECONDS = 30;
    private static final long RESERVE_DEFAULT_DURATION_SECONDS = 3600L;

    private final WalletPersistencePort walletPersistencePort;
    private final DistributedLockPort distributedLockPort;
    private final WalletBalanceChangedKafkaProducer kafkaProducer;
    private final Map<String, Reservation> reservations = new ConcurrentHashMap<>();

    public WalletInternalApplicationService(WalletPersistencePort walletPersistencePort,
                                            DistributedLockPort distributedLockPort,
                                            WalletBalanceChangedKafkaProducer kafkaProducer) {
        this.walletPersistencePort = walletPersistencePort;
        this.distributedLockPort = distributedLockPort;
        this.kafkaProducer = kafkaProducer;
    }

    // ======================== DEBIT ========================

    public DebitResult debitWallet(String walletId, long amount, String transactionId, String idempotencyKey) {
        if (walletId == null || walletId.isBlank()) {
            return DebitResult.failure("WALLET_ID_REQUIRED", "wallet_id cannot be empty");
        }
        if (amount <= 0) {
            return DebitResult.failure("INVALID_AMOUNT", "amount must be positive");
        }
        if (transactionId == null || transactionId.isBlank()) {
            return DebitResult.failure("TRANSACTION_ID_REQUIRED", "transaction_id cannot be empty");
        }

        Wallet wallet = walletPersistencePort.findWalletByIdForUpdate(walletId)
                .orElseThrow(() -> new WalletNotFoundException("Wallet not found: " + walletId));

        if (!wallet.isActive()) {
            return DebitResult.failure("WALLET_NOT_ACTIVE", "Wallet is " + wallet.getStatus() + ", cannot debit");
        }

        String lockKey = "grpc:debit:" + walletId;
        try {
            return distributedLockPort.executeWithLock(lockKey, LOCK_TIMEOUT_SECONDS, () -> {
                Wallet locked = walletPersistencePort.findWalletByIdForUpdate(walletId)
                        .orElseThrow(() -> new WalletNotFoundException("Wallet not found: " + walletId));

                Money moneyAmount = Money.of(new BigDecimal(amount), locked.getBalance().getCurrency());

                if (!locked.getBalance().isGreaterThanOrEqual(moneyAmount)) {
                    return DebitResult.failure("DEBIT_INSUFFICIENT_BALANCE",
                            "Balance " + locked.getBalance() + " < " + moneyAmount);
                }

                BigDecimal previousBalance = locked.getBalance().getAmount();
                locked.withdraw(moneyAmount);
                walletPersistencePort.saveWallet(locked);

                // Publish Kafka event — Partition Key = walletId (Strict Ordering)
                publishBalanceChange(locked.getId(), previousBalance, amount,
                        locked.getBalance().getAmount(), locked.getBalance().getCurrency(),
                        transactionId, WalletBalanceChangedPayload.ChangeType.WITHDRAWAL);

                log.info("Debit success: walletId={}, amount={}, balanceAfter={}", walletId, amount, locked.getBalance());
                return DebitResult.success(locked.getBalance().getAmount().longValue(), null, null);
            });
        } catch (WalletNotFoundException e) {
            return DebitResult.failure("WALLET_NOT_FOUND", e.getMessage());
        } catch (InsufficientBalanceException e) {
            return DebitResult.failure("DEBIT_INSUFFICIENT_BALANCE", e.getMessage());
        } catch (LockAcquisitionException e) {
            return DebitResult.failure("LOCK_BUSY", "Could not acquire lock for wallet: " + walletId);
        } catch (Exception e) {
            log.error("Debit failed for walletId={}", walletId, e);
            return DebitResult.failure("DEBIT_ERROR", e.getMessage());
        }
    }

    // ======================== CREDIT ========================

    public CreditResult creditWallet(String walletId, long amount, String transactionId, String idempotencyKey) {
        if (walletId == null || walletId.isBlank()) {
            return CreditResult.failure("WALLET_ID_REQUIRED", "wallet_id cannot be empty");
        }
        if (amount <= 0) {
            return CreditResult.failure("INVALID_AMOUNT", "amount must be positive");
        }

        Wallet wallet = walletPersistencePort.findWalletByIdForUpdate(walletId)
                .orElseThrow(() -> new WalletNotFoundException("Wallet not found: " + walletId));

        if (!wallet.isActive()) {
            return CreditResult.failure("WALLET_NOT_ACTIVE", "Wallet is " + wallet.getStatus() + ", cannot credit");
        }

        String lockKey = "grpc:credit:" + walletId;
        try {
            return distributedLockPort.executeWithLock(lockKey, LOCK_TIMEOUT_SECONDS, () -> {
                Wallet locked = walletPersistencePort.findWalletByIdForUpdate(walletId)
                        .orElseThrow(() -> new WalletNotFoundException("Wallet not found: " + walletId));

                Money moneyAmount = Money.of(new BigDecimal(amount), locked.getBalance().getCurrency());
                BigDecimal previousBalance = locked.getBalance().getAmount();
                locked.deposit(moneyAmount);
                walletPersistencePort.saveWallet(locked);

                // Publish Kafka event
                publishBalanceChange(locked.getId(), previousBalance, amount,
                        locked.getBalance().getAmount(), locked.getBalance().getCurrency(),
                        transactionId, WalletBalanceChangedPayload.ChangeType.DEPOSIT);

                log.info("Credit success: walletId={}, amount={}, balanceAfter={}", walletId, amount, locked.getBalance());
                return CreditResult.success(locked.getBalance().getAmount().longValue(), null, null);
            });
        } catch (WalletNotFoundException e) {
            return CreditResult.failure("WALLET_NOT_FOUND", e.getMessage());
        } catch (LockAcquisitionException e) {
            return CreditResult.failure("LOCK_BUSY", "Could not acquire lock for wallet: " + walletId);
        } catch (Exception e) {
            log.error("Credit failed for walletId={}", walletId, e);
            return CreditResult.failure("CREDIT_ERROR", e.getMessage());
        }
    }

    // ======================== RESERVE ========================

    public ReserveResult reserveBalance(String walletId, long amount, String transactionId, long reserveDurationSeconds) {
        if (walletId == null || walletId.isBlank()) {
            return ReserveResult.failure("WALLET_ID_REQUIRED", "wallet_id cannot be empty");
        }
        if (amount <= 0) {
            return ReserveResult.failure("INVALID_AMOUNT", "amount must be positive");
        }

        Wallet wallet = walletPersistencePort.findWalletByIdForUpdate(walletId)
                .orElseThrow(() -> new WalletNotFoundException("Wallet not found: " + walletId));

        if (!wallet.isActive()) {
            return ReserveResult.failure("WALLET_NOT_ACTIVE", "Wallet is " + wallet.getStatus());
        }

        String lockKey = "grpc:reserve:" + walletId;
        try {
            return distributedLockPort.executeWithLock(lockKey, LOCK_TIMEOUT_SECONDS, () -> {
                Wallet locked = walletPersistencePort.findWalletByIdForUpdate(walletId)
                        .orElseThrow(() -> new WalletNotFoundException("Wallet not found: " + walletId));

                Money moneyAmount = Money.of(new BigDecimal(amount), locked.getBalance().getCurrency());
                BigDecimal available = locked.getBalance().getAmount().subtract(
                        locked.getReservedBalance() != null ? locked.getReservedBalance() : BigDecimal.ZERO);

                if (available.compareTo(moneyAmount.getAmount()) < 0) {
                    return ReserveResult.failure("RESERVE_INSUFFICIENT",
                            "Available " + available + " < " + moneyAmount.getAmount());
                }

                BigDecimal previousReserved = locked.getReservedBalance() != null ? locked.getReservedBalance() : BigDecimal.ZERO;
                BigDecimal newReserved = previousReserved.add(moneyAmount.getAmount());
                locked.setReservedBalance(newReserved);
                walletPersistencePort.saveWallet(locked);

                String reservationId = UUID.randomUUID().toString();
                Reservation reservation = new Reservation(reservationId, walletId, amount,
                        transactionId, Duration.ofSeconds(reserveDurationSeconds > 0 ? reserveDurationSeconds : RESERVE_DEFAULT_DURATION_SECONDS));
                reservations.put(reservationId, reservation);

                // Publish Kafka event — reserve không làm thay đổi balance thực
                publishBalanceChange(locked.getId(), locked.getBalance().getAmount(), 0L,
                        locked.getBalance().getAmount(), locked.getBalance().getCurrency(),
                        reservationId, WalletBalanceChangedPayload.ChangeType.RESERVE);

                log.info("Reserve success: reservationId={}, walletId={}, amount={}", reservationId, walletId, amount);
                return ReserveResult.success(amount, reservationId, null, null);
            });
        } catch (WalletNotFoundException e) {
            return ReserveResult.failure("WALLET_NOT_FOUND", e.getMessage());
        } catch (LockAcquisitionException e) {
            return ReserveResult.failure("LOCK_BUSY", "Could not acquire lock for wallet: " + walletId);
        } catch (Exception e) {
            log.error("Reserve failed for walletId={}", walletId, e);
            return ReserveResult.failure("RESERVE_ERROR", e.getMessage());
        }
    }

    // ======================== RELEASE ========================

    public ReleaseResult releaseBalance(String reservationId, String transactionId) {
        if (reservationId == null || reservationId.isBlank()) {
            return ReleaseResult.failure("RESERVATION_ID_REQUIRED", "reservation_id cannot be empty");
        }

        Reservation reservation = reservations.remove(reservationId);
        if (reservation == null) {
            return ReleaseResult.failure("RELEASE_NOT_FOUND", "Reservation not found: " + reservationId);
        }

        Wallet wallet = walletPersistencePort.findWalletByIdForUpdate(reservation.walletId())
                .orElseThrow(() -> new WalletNotFoundException("Wallet not found: " + reservation.walletId()));

        String lockKey = "grpc:release:" + reservation.walletId();
        try {
            return distributedLockPort.executeWithLock(lockKey, LOCK_TIMEOUT_SECONDS, () -> {
                Wallet locked = walletPersistencePort.findWalletByIdForUpdate(reservation.walletId())
                        .orElseThrow(() -> new WalletNotFoundException("Wallet not found: " + reservation.walletId()));

                BigDecimal currentReserved = locked.getReservedBalance() != null ? locked.getReservedBalance() : BigDecimal.ZERO;
                BigDecimal newReserved = currentReserved.subtract(new BigDecimal(reservation.amount()));
                if (newReserved.compareTo(BigDecimal.ZERO) < 0) {
                    newReserved = BigDecimal.ZERO;
                }
                locked.setReservedBalance(newReserved);
                walletPersistencePort.saveWallet(locked);

                // Publish Kafka event — release không làm thay đổi balance thực
                publishBalanceChange(locked.getId(), locked.getBalance().getAmount(), 0L,
                        locked.getBalance().getAmount(), locked.getBalance().getCurrency(),
                        reservationId, WalletBalanceChangedPayload.ChangeType.RELEASE);

                log.info("Release success: reservationId={}, walletId={}, released={}", reservationId, reservation.walletId(), reservation.amount());
                return ReleaseResult.success(null, null);
            });
        } catch (WalletNotFoundException e) {
            return ReleaseResult.failure("WALLET_NOT_FOUND", e.getMessage());
        } catch (LockAcquisitionException e) {
            return ReleaseResult.failure("LOCK_BUSY", "Could not acquire lock for wallet: " + reservation.walletId());
        } catch (Exception e) {
            log.error("Release failed for reservationId={}", reservationId, e);
            return ReleaseResult.failure("RELEASE_ERROR", e.getMessage());
        }
    }

    // ======================== CHECK LIMIT ========================

    public LimitCheckResult checkLimit(String walletId, long amount, String transactionType, String userId) {
        if (walletId == null || walletId.isBlank()) {
            return LimitCheckResult.failure("WALLET_ID_REQUIRED", "wallet_id cannot be empty");
        }
        if (amount <= 0) {
            return LimitCheckResult.failure("INVALID_AMOUNT", "amount must be positive");
        }

        Wallet wallet = walletPersistencePort.findWalletById(walletId)
                .orElseThrow(() -> new WalletNotFoundException("Wallet not found: " + walletId));

        BigDecimal requestAmount = new BigDecimal(amount);
        BigDecimal availableBalance = wallet.getBalance().getAmount();
        BigDecimal reserved = wallet.getReservedBalance() != null ? wallet.getReservedBalance() : BigDecimal.ZERO;
        BigDecimal effectiveAvailable = availableBalance.subtract(reserved);

        boolean allowed = effectiveAvailable.compareTo(requestAmount) >= 0;

        Long dailyLimit = wallet.getDailyLimit() != null ? wallet.getDailyLimit() : 50000000L;
        Long dailySpent = wallet.getDailySpent() != null ? wallet.getDailySpent() : 0L;
        BigDecimal dailyRemaining = new BigDecimal(dailyLimit - dailySpent);

        if (!allowed) {
            return LimitCheckResult.success(false, availableBalance.longValue(), dailyRemaining.longValue(),
                    dailyRemaining.longValue(), "LIMIT_EXCEEDED", "Insufficient available balance");
        }

        log.debug("Limit check passed: walletId={}, amount={}", walletId, amount);
        return LimitCheckResult.success(true, effectiveAvailable.longValue(), dailyRemaining.longValue(),
                dailyRemaining.longValue(), null, null);
    }

    // ======================== GET WALLET ========================

    public GetWalletResult getWalletByUserId(String userId) {
        if (userId == null || userId.isBlank()) {
            return GetWalletResult.failure("USER_ID_REQUIRED", "user_id cannot be empty");
        }

        return walletPersistencePort.findWalletByOwnerId(userId)
                .map(wallet -> GetWalletResult.success(
                        wallet.getId(), wallet.getOwnerId(), wallet.getBalance().getAmount().longValue(),
                        wallet.getBalance().getCurrency(), wallet.getStatus().name()))
                .orElse(GetWalletResult.notFound());
    }

    // ======================== KAFKA HELPERS ========================

    /**
     * Publish balance change event vào Kafka topic.
     * Partition Key = walletId → Strict Chronological Ordering per wallet.
     */
    private void publishBalanceChange(String walletId, BigDecimal previousBalance,
                                       long changeAmount, BigDecimal newBalance,
                                       String currency, String transactionId,
                                       WalletBalanceChangedPayload.ChangeType changeType) {
        try {
            WalletBalanceChangedPayload payload = new WalletBalanceChangedPayload(
                    walletId,
                    previousBalance,
                    new BigDecimal(changeAmount),
                    newBalance,
                    currency,
                    transactionId,
                    changeType.name()
            );
            kafkaProducer.publishBalanceChanged(payload);
        } catch (Exception e) {
            // Không ảnh hưởng giao dịch chính — log và tiếp tục
            log.warn("Kafka publish failed (non-fatal): walletId={}, txId={}, error={}",
                    walletId, transactionId, e.getMessage());
        }
    }

    // ======================== INNER CLASSES ========================

    public record DebitResult(boolean success, Long balanceAfter, String errorCode, String errorMessage) {
        static DebitResult success(Long balanceAfter, String errorCode, String errorMessage) {
            return new DebitResult(true, balanceAfter, errorCode, errorMessage);
        }
        static DebitResult failure(String code, String message) {
            return new DebitResult(false, null, code, message);
        }
    }

    public record CreditResult(boolean success, Long balanceAfter, String errorCode, String errorMessage) {
        static CreditResult success(Long balanceAfter, String errorCode, String errorMessage) {
            return new CreditResult(true, balanceAfter, errorCode, errorMessage);
        }
        static CreditResult failure(String code, String message) {
            return new CreditResult(false, null, code, message);
        }
    }

    public record ReserveResult(boolean success, Long reservedAmount, String reservationId, String errorCode, String errorMessage) {
        static ReserveResult success(Long reservedAmount, String reservationId, String errorCode, String errorMessage) {
            return new ReserveResult(true, reservedAmount, reservationId, errorCode, errorMessage);
        }
        static ReserveResult failure(String code, String message) {
            return new ReserveResult(false, null, null, code, message);
        }
    }

    public record ReleaseResult(boolean success, String errorCode, String errorMessage) {
        static ReleaseResult success(String errorCode, String errorMessage) {
            return new ReleaseResult(true, errorCode, errorMessage);
        }
        static ReleaseResult failure(String code, String message) {
            return new ReleaseResult(false, code, message);
        }
    }

    public record LimitCheckResult(boolean allowed, Long availableBalance, Long dailyLimitRemaining,
                                    Long transactionLimitRemaining, String errorCode, String errorMessage) {
        static LimitCheckResult success(boolean allowed, Long availableBalance, Long dailyLimitRemaining,
                                         Long transactionLimitRemaining, String errorCode, String errorMessage) {
            return new LimitCheckResult(allowed, availableBalance, dailyLimitRemaining, transactionLimitRemaining, errorCode, errorMessage);
        }
        static LimitCheckResult failure(String code, String message) {
            return new LimitCheckResult(false, null, null, null, code, message);
        }
    }

    public record GetWalletResult(boolean found, String walletId, String userId, Long balance,
                                   String currency, String status, String errorCode, String errorMessage) {
        static GetWalletResult success(String walletId, String userId, Long balance, String currency, String status) {
            return new GetWalletResult(true, walletId, userId, balance, currency, status, null, null);
        }
        static GetWalletResult notFound() {
            return new GetWalletResult(false, null, null, null, null, null, "WALLET_NOT_FOUND", "No wallet found for user");
        }
        static GetWalletResult failure(String code, String message) {
            return new GetWalletResult(false, null, null, null, null, null, code, message);
        }
    }

    private record Reservation(String id, String walletId, long amount, String transactionId, Duration ttl) {
        Reservation(String id, String walletId, long amount, String transactionId, Duration ttl) {
            this.id = id;
            this.walletId = walletId;
            this.amount = amount;
            this.transactionId = transactionId;
            this.ttl = ttl != null ? ttl : Duration.ofSeconds(RESERVE_DEFAULT_DURATION_SECONDS);
        }
    }
}
