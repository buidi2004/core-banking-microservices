package com.fintech.notification.service;

import com.fintech.notification.entity.Promotion;
import com.fintech.notification.entity.Voucher;
import com.fintech.notification.repository.PromotionRepository;
import com.fintech.notification.repository.VoucherRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class PromotionService {

    private static final Logger log = LoggerFactory.getLogger(PromotionService.class);

    private final VoucherRepository voucherRepository;
    private final PromotionRepository promotionRepository;

    public PromotionService(VoucherRepository voucherRepository, PromotionRepository promotionRepository) {
        this.voucherRepository = voucherRepository;
        this.promotionRepository = promotionRepository;
        seedVouchersIfEmpty();
    }

    public List<Voucher> getActivePromotions() {
        return voucherRepository.findByActiveTrue().stream()
                .filter(Voucher::isCurrentlyValid)
                .collect(Collectors.toList());
    }

    public List<Voucher> getMyVouchers(String userId) {
        return getActivePromotions();
    }

    public List<Promotion> getActiveCampaigns() {
        return promotionRepository.findByActiveTrue().stream()
                .filter(Promotion::isCurrentlyValid)
                .collect(Collectors.toList());
    }

    @Transactional
    public Voucher redeemVoucher(String userId, String code) {
        Voucher voucher = findVoucher(code);
        voucher.setUsedCount(voucher.getUsedCount() + 1);
        log.info("User {} redeemed voucher {}", userId, code);
        return voucherRepository.save(voucher);
    }

    @Transactional
    public Voucher applyVoucher(String userId, String code, BigDecimal orderAmount) {
        Voucher voucher = findVoucher(code);
        BigDecimal minOrder = BigDecimal.valueOf(voucher.getMinOrderAmount() != null ? voucher.getMinOrderAmount() : 0L);
        if (orderAmount != null && orderAmount.compareTo(minOrder) < 0) {
            throw new IllegalArgumentException("Order amount does not meet minimum requirement: " + minOrder);
        }
        return voucher;
    }

    private Voucher findVoucher(String code) {
        if (code == null || code.isBlank()) {
            throw new IllegalArgumentException("Voucher code is required");
        }
        return voucherRepository.findByCodeIgnoreCase(code)
                .orElseThrow(() -> new IllegalArgumentException("Voucher code invalid: " + code));
    }

    private void seedVouchersIfEmpty() {
        if (voucherRepository.count() > 0) {
            return;
        }
        voucherRepository.save(newVoucher("XINCHAO50", "Giảm 50k cho đơn hàng đầu tiên",
                "FIXED", 50_000L, 100_000L, "PROMOTION", 30));
        voucherRepository.save(newVoucher("FREEGO", "Miễn phí giao dịch nạp tiền",
                "FIXED", 10_000L, 0L, "PROMOTION", 15));
        log.info("Seeded default demo vouchers");
    }

    private Voucher newVoucher(String code, String title, String discountType, long discountValue,
                               long minOrderAmount, String description, int validDays) {
        Voucher v = new Voucher();
        v.setCode(code);
        v.setTitle(title);
        v.setDescription(description);
        v.setDiscountType(discountType);
        v.setDiscountValue(discountValue);
        v.setMinOrderAmount(minOrderAmount);
        v.setMaxDiscountAmount(discountValue);
        v.setValidFrom(Instant.now());
        v.setValidUntil(Instant.now().plus(validDays, ChronoUnit.DAYS));
        v.setUsageLimit(0);
        v.setUsedCount(0);
        v.setActive(true);
        return v;
    }
}
