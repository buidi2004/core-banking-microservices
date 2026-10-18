package com.fintech.wallet.domain.port.in;

import com.fintech.wallet.domain.model.Voucher;

import java.math.BigDecimal;
import java.util.List;

public interface PromotionUseCase {
    List<Voucher> getActivePromotions();
    Voucher redeemVoucher(String userId, String code);
    Voucher applyVoucher(String userId, String code, BigDecimal orderAmount);
    List<Voucher> getMyVouchers(String userId);
}
