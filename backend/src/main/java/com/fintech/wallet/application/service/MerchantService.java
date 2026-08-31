package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.model.Merchant;
import com.fintech.wallet.domain.model.MerchantOrder;
import com.fintech.wallet.domain.model.Money;
import com.fintech.wallet.domain.model.Transaction;
import com.fintech.wallet.domain.port.in.MerchantUseCase;
import com.fintech.wallet.domain.port.in.TransferMoneyUseCase;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

@Service
public class MerchantService implements MerchantUseCase {

    private static final Logger log = LoggerFactory.getLogger(MerchantService.class);

    private final TransferMoneyUseCase transferMoneyUseCase;
    private final List<Merchant> merchants = new ArrayList<>();
    private final List<MerchantOrder> orders = new ArrayList<>();

    public MerchantService(TransferMoneyUseCase transferMoneyUseCase) {
        this.transferMoneyUseCase = transferMoneyUseCase;
    }

    @Override
    public Merchant registerMerchant(String merchantName, String bankAccount) {
        Merchant merchant = Merchant.createNew(merchantName, bankAccount);
        merchants.add(merchant);
        log.info("Registered merchant: {}", merchantName);
        return merchant;
    }

    @Override
    public MerchantOrder createPaymentRequest(String merchantId, String orderRef, BigDecimal amount, String currency, String callbackUrl) {
        MerchantOrder order = MerchantOrder.createNew(merchantId, orderRef, amount, currency, callbackUrl);
        orders.add(order);
        log.info("Created merchant payment orderId={}, amount={}", order.getId(), amount);
        return order;
    }

    @Override
    public Transaction confirmMerchantPayment(String userId, String walletId, String orderId) {
        MerchantOrder order = orders.stream()
                .filter(o -> o.getId().equals(orderId))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Merchant order not found: " + orderId));

        Transaction tx = transferMoneyUseCase.transfer("TX_MERCHANT_" + orderId, walletId, "W_MERCHANT_" + order.getMerchantId(), Money.of(order.getAmount(), order.getCurrency()), "Payment for order " + orderId);
        order.markPaid();
        log.info("Confirmed merchant payment orderId={}, txId={}", orderId, tx.getId());
        return tx;
    }
}
