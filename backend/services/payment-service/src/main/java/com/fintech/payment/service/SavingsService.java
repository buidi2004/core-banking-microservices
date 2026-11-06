package com.fintech.payment.service;

import com.fintech.payment.domain.entity.SavingsAccount;
import com.fintech.payment.dto.*;
import com.fintech.payment.grpc.WalletGrpcClient;
import com.fintech.payment.repository.SavingsAccountRepository;
import com.fintech.payment.security.PinTokenValidator;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class SavingsService {

    private final SavingsAccountRepository savingsRepository;
    private final WalletGrpcClient walletGrpcClient;
    private final PinTokenValidator pinTokenValidator;

    private static final List<SavingsProductDto.TermRateDto> STANDARD_TERMS = List.of(
            SavingsProductDto.TermRateDto.builder().months(1).rate(new BigDecimal("3.6")).tag("").build(),
            SavingsProductDto.TermRateDto.builder().months(3).rate(new BigDecimal("4.3")).tag("").build(),
            SavingsProductDto.TermRateDto.builder().months(6).rate(new BigDecimal("5.8")).tag("+0.3% online").build(),
            SavingsProductDto.TermRateDto.builder().months(12).rate(new BigDecimal("7.2")).tag("Ưu đãi hot").build(),
            SavingsProductDto.TermRateDto.builder().months(18).rate(new BigDecimal("7.3")).tag("").build(),
            SavingsProductDto.TermRateDto.builder().months(24).rate(new BigDecimal("7.4")).tag("Dài hạn").build()
    );

    public List<SavingsProductDto> getProducts() {
        return List.of(
                SavingsProductDto.builder()
                        .productType("TIET_KIEM_PHAT_LOC")
                        .productName("Tiết Kiệm Phát Lộc")
                        .description("Nhận toàn bộ lãi cuối kỳ với lãi suất sinh lời cao nhất")
                        .badge("Lãi suất cao nhất")
                        .minDeposit(new BigDecimal("1000000"))
                        .baseRate(new BigDecimal("7.2"))
                        .terms(STANDARD_TERMS)
                        .build(),
                SavingsProductDto.builder()
                        .productType("TIET_KIEM_TRA_LAI_THANG")
                        .productName("Tiết Kiệm Trả Lãi Tháng")
                        .description("Nhận tiền lãi đều đặn vào ngày 01 hàng tháng để chi tiêu")
                        .badge("Linh hoạt dòng tiền")
                        .minDeposit(new BigDecimal("5000000"))
                        .baseRate(new BigDecimal("6.5"))
                        .terms(STANDARD_TERMS)
                        .build(),
                SavingsProductDto.builder()
                        .productType("TICH_LUY_GUI_GOP")
                        .productName("Tích Lũy Gửi Góp V-Plus")
                        .description("Gửi thêm bất kỳ lúc nào từ 100.000đ, tích lũy tự động")
                        .badge("Tích lũy linh hoạt")
                        .minDeposit(new BigDecimal("500000"))
                        .baseRate(new BigDecimal("6.0"))
                        .terms(STANDARD_TERMS)
                        .build()
        );
    }

    @Transactional
    public SavingsAccountResponse openSavings(String userId, OpenSavingsRequest request) {
        if (request.getPinToken() != null && !request.getPinToken().isBlank()) {
            pinTokenValidator.validate(userId, request.getPinToken());
        }

        BigDecimal minDeposit = switch (request.getProductType()) {
            case "TIET_KIEM_TRA_LAI_THANG" -> new BigDecimal("5000000");
            case "TICH_LUY_GUI_GOP" -> new BigDecimal("500000");
            default -> new BigDecimal("1000000");
        };

        if (request.getDepositAmount().compareTo(minDeposit) < 0) {
            throw new IllegalArgumentException("Số tiền gửi tối thiểu cho gói này là " + minDeposit.toPlainString() + " VND");
        }

        BigDecimal rate = getRateForMonths(request.getTermMonths());

        String effectiveWalletId = request.getWalletId();
        if (effectiveWalletId == null || effectiveWalletId.isBlank()) {
            var userWallet = walletGrpcClient.getWalletByUserId(userId);
            if (userWallet != null && userWallet.isFound()) {
                effectiveWalletId = userWallet.getWalletId();
            } else {
                throw new IllegalArgumentException("Không tìm thấy ví cho người dùng " + userId);
            }
        }

        // Interest = principal * (rate / 100) * (termMonths / 12)
        BigDecimal expectedInterest = request.getDepositAmount()
                .multiply(rate)
                .divide(BigDecimal.valueOf(100), 4, RoundingMode.HALF_UP)
                .multiply(BigDecimal.valueOf(request.getTermMonths()))
                .divide(BigDecimal.valueOf(12), 0, RoundingMode.HALF_UP);

        // Debit user wallet via gRPC
        String debitTxId = "SAV_OPN_" + UUID.randomUUID().toString().replace("-", "").substring(0, 20);
        String debitIdemKey = "idem:sav:open:" + UUID.randomUUID();
        var debitRes = walletGrpcClient.debit(
                effectiveWalletId,
                request.getDepositAmount().longValue(),
                debitTxId,
                debitIdemKey
        );
        if (debitRes != null && !debitRes.isSuccess()) {
            throw new IllegalStateException("Trừ tiền ví thất bại: " + debitRes.getErrorMessage());
        }

        String prefix = switch (request.getProductType()) {
            case "TIET_KIEM_TRA_LAI_THANG" -> "TKTL-";
            case "TICH_LUY_GUI_GOP" -> "TLGG-";
            default -> "TKPL-";
        };
        String accountNumber = prefix + System.currentTimeMillis();

        LocalDate startDate = LocalDate.now();
        LocalDate maturityDate = startDate.plusMonths(request.getTermMonths());

        SavingsAccount entity = SavingsAccount.builder()
                .userId(userId)
                .walletId(effectiveWalletId)
                .accountNumber(accountNumber)
                .productType(request.getProductType())
                .productName(getProductName(request.getProductType()))
                .principal(request.getDepositAmount())
                .interestRate(rate)
                .termMonths(request.getTermMonths())
                .expectedInterest(expectedInterest)
                .accruedInterest(BigDecimal.ZERO)
                .rolloverType(request.getRolloverType() != null ? request.getRolloverType() : "AUTO_ROLLOVER_ALL")
                .status("ACTIVE")
                .startDate(startDate)
                .maturityDate(maturityDate)
                .build();

        SavingsAccount saved = savingsRepository.save(entity);
        log.info("Opened savings passbook {} for user {}", accountNumber, userId);
        return toResponse(saved);
    }

    public List<SavingsAccountResponse> getUserSavings(String userId) {
        return savingsRepository.findByUserIdOrderByCreatedAtDesc(userId).stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    public List<SavingsAccountResponse> getAllSavingsAccounts() {
        return savingsRepository.findAll().stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    public SavingsAccountResponse getSavingsDetail(String id, String userId) {
        SavingsAccount entity = findSavingsAccount(id, userId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy sổ tiết kiệm: " + id));
        return toResponse(entity);
    }

    @Transactional
    public SettleSavingsResponse settleSavings(String id, String userId, SettleSavingsRequest request) {
        if (request != null && request.getPinToken() != null && !request.getPinToken().isBlank()) {
            pinTokenValidator.validate(userId, request.getPinToken());
        }

        SavingsAccount entity = findSavingsAccount(id, userId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy sổ tiết kiệm: " + id));

        if (!"ACTIVE".equals(entity.getStatus())) {
            throw new IllegalStateException("Sổ tiết kiệm đã tất toán hoặc không ở trạng thái hiệu lực");
        }

        LocalDate today = LocalDate.now();
        boolean isEarly = today.isBefore(entity.getMaturityDate());
        BigDecimal interestEarned;

        if (isEarly) {
            long daysHeld = Math.max(1, ChronoUnit.DAYS.between(entity.getStartDate(), today));
            // In-house core banking SBV non-term demand deposit rate = 0.2% p.a.
            BigDecimal nonTermRate = new BigDecimal("0.2");
            interestEarned = entity.getPrincipal()
                    .multiply(nonTermRate)
                    .divide(BigDecimal.valueOf(100), 6, RoundingMode.HALF_UP)
                    .multiply(BigDecimal.valueOf(daysHeld))
                    .divide(BigDecimal.valueOf(365), 0, RoundingMode.HALF_UP);
        } else {
            interestEarned = entity.getExpectedInterest();
        }

        BigDecimal totalPayout = entity.getPrincipal().add(interestEarned);

        // Credit principal and earned interest back to user wallet
        String settleTxId = "SAV_SET_" + UUID.randomUUID().toString().replace("-", "").substring(0, 20);
        String settleIdemKey = "idem:sav:settle:" + entity.getAccountNumber();
        var creditRes = walletGrpcClient.credit(
                entity.getWalletId(),
                totalPayout.longValue(),
                settleTxId,
                settleIdemKey
        );
        if (creditRes != null && !creditRes.isSuccess()) {
            throw new IllegalStateException("Cộng tiền ví thất bại: " + creditRes.getErrorMessage());
        }

        entity.setStatus("SETTLED");
        entity.setSettledDate(Instant.now());
        entity.setSettledAmount(totalPayout);
        entity.setAccruedInterest(interestEarned);
        savingsRepository.save(entity);

        log.info("Settled savings passbook {} for user {}, total payout {}", entity.getAccountNumber(), userId, totalPayout);

        return SettleSavingsResponse.builder()
                .accountNumber(entity.getAccountNumber())
                .earlySettlement(isEarly)
                .principalReturned(entity.getPrincipal())
                .interestEarned(interestEarned)
                .totalPayout(totalPayout)
                .creditedToWallet(entity.getWalletId())
                .message(isEarly ? "Tất toán trước hạn thành công (áp dụng lãi suất không kỳ hạn 0.2%/năm)"
                        : "Tất toán đúng hạn thành công trọn vẹn tiền gốc và lãi")
                .build();
    }

    /**
     * Rút gốc từng phần sổ tiết kiệm có kỳ hạn theo Thông tư 04/2022/TT-NHNN.
     * Phần rút trước hạn áp dụng lãi không kỳ hạn 0.2%/năm theo số ngày thực gửi.
     * Phần gốc còn lại giữ nguyên kỳ hạn và lãi suất ban đầu cho đến ngày đáo hạn.
     */
    @Transactional
    public SettleSavingsResponse withdrawPartial(String id, String userId, PartialWithdrawSavingsRequest request) {
        if (request != null && request.getPinToken() != null && !request.getPinToken().isBlank()) {
            pinTokenValidator.validate(userId, request.getPinToken());
        }

        SavingsAccount entity = findSavingsAccount(id, userId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy sổ tiết kiệm: " + id));

        if (!"ACTIVE".equals(entity.getStatus())) {
            throw new IllegalStateException("Sổ tiết kiệm không ở trạng thái hiệu lực (ACTIVE)");
        }

        BigDecimal withdrawAmount = request != null ? request.getWithdrawAmount() : null;
        if (withdrawAmount == null || withdrawAmount.compareTo(BigDecimal.ZERO) <= 0) {
            throw new IllegalArgumentException("Số tiền rút phải lớn hơn 0");
        }

        BigDecimal minDeposit = new BigDecimal("500000"); // 500k VND mức tối thiểu duy trì sổ
        BigDecimal remainingPrincipal = entity.getPrincipal().subtract(withdrawAmount);
        if (remainingPrincipal.compareTo(minDeposit) < 0) {
            throw new IllegalArgumentException("Số dư gốc còn lại sau khi rút (" + remainingPrincipal.toPlainString() + " VND) phải tối thiểu " + minDeposit.toPlainString() + " VND. Nếu muốn rút toàn bộ, vui lòng chọn Tất Toán Sổ.");
        }

        LocalDate today = LocalDate.now();
        long daysHeld = Math.max(1, ChronoUnit.DAYS.between(entity.getStartDate(), today));
        // Lãi không kỳ hạn cho phần tiền rút ra
        BigDecimal nonTermRate = new BigDecimal("0.2");
        BigDecimal withdrawInterest = withdrawAmount
                .multiply(nonTermRate)
                .divide(BigDecimal.valueOf(100), 6, RoundingMode.HALF_UP)
                .multiply(BigDecimal.valueOf(daysHeld))
                .divide(BigDecimal.valueOf(365), 0, RoundingMode.HALF_UP);

        BigDecimal totalWithdrawPayout = withdrawAmount.add(withdrawInterest);

        // Credit về ví
        String txId = "SAV_WDP_" + UUID.randomUUID().toString().replace("-", "").substring(0, 20);
        String idemKey = "idem:sav:wdp:" + entity.getAccountNumber() + ":" + System.currentTimeMillis();
        var creditRes = walletGrpcClient.credit(
                entity.getWalletId(),
                totalWithdrawPayout.longValue(),
                txId,
                idemKey
        );
        if (creditRes != null && !creditRes.isSuccess()) {
            throw new IllegalStateException("Cộng tiền ví thất bại: " + creditRes.getErrorMessage());
        }

        // Cập nhật lại số tiền gốc của sổ và tính lại expectedInterest cho phần gốc còn lại
        entity.setPrincipal(remainingPrincipal);
        BigDecimal newExpectedInterest = remainingPrincipal
                .multiply(entity.getInterestRate())
                .divide(BigDecimal.valueOf(100), 6, RoundingMode.HALF_UP)
                .multiply(BigDecimal.valueOf(entity.getTermMonths()))
                .divide(BigDecimal.valueOf(12), 0, RoundingMode.HALF_UP);
        entity.setExpectedInterest(newExpectedInterest);
        savingsRepository.save(entity);

        log.info("Partial withdrawal from savings passbook {}: withdrawn {}, remaining {}, user {}",
                entity.getAccountNumber(), withdrawAmount, remainingPrincipal, userId);

        return SettleSavingsResponse.builder()
                .accountNumber(entity.getAccountNumber())
                .earlySettlement(true)
                .principalReturned(withdrawAmount)
                .interestEarned(withdrawInterest)
                .totalPayout(totalWithdrawPayout)
                .creditedToWallet(entity.getWalletId())
                .message("Rút gốc từng phần thành công theo Thông tư 04/2022/TT-NHNN. Phần gốc còn lại (" + remainingPrincipal.toPlainString() + " VND) giữ nguyên lãi suất " + entity.getInterestRate() + "%/năm đến ngày đáo hạn.")
                .build();
    }

    private BigDecimal getRateForMonths(int months) {
        return STANDARD_TERMS.stream()
                .filter(t -> t.getMonths() == months)
                .map(SavingsProductDto.TermRateDto::getRate)
                .findFirst()
                .orElse(new BigDecimal("6.0"));
    }

    private String getProductName(String productType) {
        return switch (productType) {
            case "TIET_KIEM_TRA_LAI_THANG" -> "Tiết Kiệm Trả Lãi Tháng";
            case "TICH_LUY_GUI_GOP" -> "Tích Lũy Gửi Góp V-Plus";
            default -> "Tiết Kiệm Phát Lộc";
        };
    }

    private Optional<SavingsAccount> findSavingsAccount(String idOrAccountNumber, String userId) {
        if (idOrAccountNumber == null || idOrAccountNumber.isBlank()) return Optional.empty();
        try {
            UUID uuid = UUID.fromString(idOrAccountNumber.trim());
            Optional<SavingsAccount> byId = savingsRepository.findByIdAndUserId(uuid, userId);
            if (byId.isPresent()) return byId;
        } catch (IllegalArgumentException ignored) {}
        return savingsRepository.findByAccountNumber(idOrAccountNumber.trim())
                .filter(acc -> userId.equals(acc.getUserId()));
    }

    private SavingsAccountResponse toResponse(SavingsAccount e) {
        return SavingsAccountResponse.builder()
                .id(e.getId().toString())
                .userId(e.getUserId())
                .walletId(e.getWalletId())
                .accountNumber(e.getAccountNumber())
                .productType(e.getProductType())
                .productName(e.getProductName())
                .principal(e.getPrincipal())
                .interestRate(e.getInterestRate())
                .termMonths(e.getTermMonths())
                .expectedInterest(e.getExpectedInterest())
                .accruedInterest(e.getAccruedInterest())
                .rolloverType(e.getRolloverType())
                .status(e.getStatus())
                .startDate(e.getStartDate())
                .maturityDate(e.getMaturityDate())
                .build();
    }
}

