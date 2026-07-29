package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.model.Bill;
import com.fintech.wallet.domain.model.BillType;
import com.fintech.wallet.domain.model.Money;
import com.fintech.wallet.domain.model.Transaction;
import com.fintech.wallet.domain.port.in.BillPaymentUseCase;
import com.fintech.wallet.domain.port.in.GetWalletUseCase;
import com.fintech.wallet.domain.port.out.BillProviderPort;
import org.springframework.stereotype.Service;

@Service
public class PaymentService implements BillPaymentUseCase {

    private final BillProviderPort billProviderPort;
    private final WalletService walletService;

    public PaymentService(BillProviderPort billProviderPort, WalletService walletService) {
        this.billProviderPort = billProviderPort;
        this.walletService = walletService;
    }

    @Override
    public Bill queryBill(BillType billType, String customerCode) {
        if (customerCode == null || customerCode.isBlank()) {
            throw new IllegalArgumentException("Customer code is required");
        }
        return billProviderPort.fetchBill(billType, customerCode);
    }

    @Override
    public Transaction payBill(String requestId, String userId, String walletId, String billId, Money amount) {
        // Reuse walletService.withdraw to deduct money safely with Redis Lock + Idempotency
        Transaction transaction = walletService.withdraw(requestId, userId, walletId, "BILL_PROVIDER", amount);
        billProviderPort.processBillPayment(billId, amount, transaction.getId());
        return transaction;
    }

    @Override
    public Transaction topupPhone(String requestId, String userId, String walletId, String phoneNumber, Money amount) {
        Transaction transaction = walletService.withdraw(requestId, userId, walletId, "TELCO_PROVIDER", amount);
        billProviderPort.processPhoneTopup(phoneNumber, amount, transaction.getId());
        return transaction;
    }
}
