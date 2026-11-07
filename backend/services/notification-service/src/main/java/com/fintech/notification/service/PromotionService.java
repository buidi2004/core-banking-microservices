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
        seedCampaignsIfEmpty();
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
                "FIXED", 50_000L, 100_000L,
                "Áp dụng cho giao dịch đầu tiên qua ví Sen Hồng Bank, giảm 50.000 VND cho đơn từ 100.000 VND.", 30));
        voucherRepository.save(newVoucher("FREEGO", "Miễn phí giao dịch nạp tiền",
                "FIXED", 10_000L, 0L,
                "Hoàn 10.000 VND phí giao dịch nạp tiền vào ví Sen Hồng Bank.", 15));
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

    /**
     * Seed chiến dịch khuyến mãi mặc định gắn với tính năng thật của Sen Hồng Bank
     * (nạp tiền, tiết kiệm, giới thiệu bạn bè, hóa đơn, chuyển tiền P2P).
     * rulesJson chứa gợi ý hiển thị phía mobile: category, badge, buttonText, route.
     */
    private void seedCampaignsIfEmpty() {
        if (promotionRepository.count() > 0) {
            return;
        }
        Instant now = Instant.now();
        Instant end = now.plus(60, ChronoUnit.DAYS);

        newCampaign("Chào Bạn Mới — Nạp Tiền Đầu Tiên",
                "Nạp tiền lần đầu từ 500.000 VND nhận ưu đãi 50.000 VND vào ví",
                "DEPOSIT", 500_000L, 50_000L, 1, 50_000_000L, now, end,
                "{\"category\":\"deposit\",\"badge\":\"CHÀO BẠN MỚI\",\"buttonText\":\"Nạp tiền ngay\",\"route\":\"/deposit\"}");
        newCampaign("Giới Thiệu Bạn Bè — Nhận 100K",
                "Mời bạn bè mở ví thành công, cả hai cùng nhận 100.000 VND",
                "REFERRAL", 1L, 100_000L, 5, 100_000_000L, now, end,
                "{\"category\":\"referral\",\"badge\":\"MỜI BẠN NHẬN QUÀ\",\"buttonText\":\"Mời bạn bè\",\"route\":\"/referral\"}");
        newCampaign("Gửi Tiết Kiệm Nhận Thưởng",
                "Mở sổ tiết kiệm từ 1.000.000 VND kỳ hạn 3 tháng nhận thưởng 200.000 VND",
                "SAVINGS", 1_000_000L, 200_000L, 1, 200_000_000L, now, end,
                "{\"category\":\"savings\",\"badge\":\"TIẾT KIỆM\",\"buttonText\":\"Mở sổ ngay\",\"route\":\"/savings\"}");
        newCampaign("Thanh Toán Hóa Đơn Hoàn 20K",
                "Thanh toán hóa đơn điện nước từ 200.000 VND, hoàn ngay 20.000 VND",
                "BILL", 200_000L, 20_000L, 3, 80_000_000L, now, end,
                "{\"category\":\"bills\",\"badge\":\"HOÀN TIỀN\",\"buttonText\":\"Thanh toán\",\"route\":\"/bills\"}");
        newCampaign("Chuyển Tiền Miễn Phí Qua 5 Giao Dịch",
                "Thực hiện 5 giao dịch chuyển tiền P2P thành công, nhận thưởng 30.000 VND",
                "TRANSACTION_COUNT", 5L, 30_000L, 1, 60_000_000L, now, end,
                "{\"category\":\"p2p\",\"badge\":\"MIỄN PHÍ\",\"buttonText\":\"Chuyển tiền\",\"route\":\"/transfer\"}");

        log.info("Seeded default promotional campaigns");
    }

    private void newCampaign(String name, String description, String type, long targetAmount,
                             long rewardAmount, int participantLimit, long totalBudget,
                             Instant start, Instant end, String rulesJson) {
        Promotion p = new Promotion();
        p.setName(name);
        p.setDescription(description);
        p.setType(type);
        p.setTargetAmount(targetAmount);
        p.setRewardAmount(rewardAmount);
        p.setMaxRewardPerUser(rewardAmount);
        p.setTotalRewardBudget(totalBudget);
        p.setRewardClaimed(0L);
        p.setParticipantLimit(participantLimit);
        p.setParticipantsCount(0);
        p.setStartDate(start);
        p.setEndDate(end);
        p.setActive(true);
        p.setRulesJson(rulesJson);
        promotionRepository.save(p);
    }
}
