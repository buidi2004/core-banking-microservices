package com.fintech.wallet.domain.port.in;

import com.fintech.wallet.domain.model.Merchant;
import com.fintech.wallet.domain.model.MerchantOrder;
import com.fintech.wallet.domain.model.Transaction;

import java.math.BigDecimal;

public interface MerchantUseCase {
    Merchant registerMerchant(String merchantName, String bankAccount);
    MerchantOrder createPaymentRequest(String merchantId, String orderRef, BigDecimal amount, String currency, String callbackUrl);
    Transaction confirmMerchantPayment(String userId, String walletId, String orderId);
}
