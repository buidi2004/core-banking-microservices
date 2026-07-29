package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.model.Voucher;
import com.fintech.wallet.domain.port.in.PromotionUseCase;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class PromotionService implements PromotionUseCase {

    private final List<Voucher> vouchers = new ArrayList<>();
    private final List<String> redeemedVouchers = new ArrayList<>();

    public PromotionService() {
        vouchers.add(Voucher.createNew("XINCHAO50", "Giảm 50k cho đơn hàng đầu tiên", new BigDecimal("50000"), new BigDecimal("100000"), Instant.now().plus(30, ChronoUnit.DAYS)));
        vouchers.add(Voucher.createNew("FREEGO", "Miễn phí giao dịch nạp tiền", new BigDecimal("10000"), BigDecimal.ZERO, Instant.now().plus(15, ChronoUnit.DAYS)));
    }

    @Override
    public List<Voucher> getActivePromotions() {
        return vouchers.stream().filter(v -> "ACTIVE".equals(v.getStatus())).collect(Collectors.toList());
    }

    @Override
    public Voucher redeemVoucher(String userId, String code) {
        Voucher voucher = vouchers.stream()
                .filter(v -> v.getCode().equalsIgnoreCase(code))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Voucher code invalid: " + code));

        redeemedVouchers.add(userId + ":" + voucher.getId());
        return voucher;
    }

    @Override
    public Voucher applyVoucher(String userId, String code, BigDecimal orderAmount) {
        Voucher voucher = vouchers.stream()
                .filter(v -> v.getCode().equalsIgnoreCase(code))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Voucher code invalid: " + code));

        if (orderAmount.compareTo(voucher.getMinOrderAmount()) < 0) {
            throw new IllegalArgumentException("Order amount does not meet minimum order requirement: " + voucher.getMinOrderAmount());
        }
        return voucher;
    }

    @Override
    public List<Voucher> getMyVouchers(String userId) {
        return getActivePromotions();
    }
}
