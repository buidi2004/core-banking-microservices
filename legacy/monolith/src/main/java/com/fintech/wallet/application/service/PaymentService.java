package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.model.Bill;
import com.fintech.wallet.domain.model.BillType;
import com.fintech.wallet.domain.model.Money;
import com.fintech.wallet.domain.model.Transaction;
import com.fintech.wallet.domain.port.in.BillPaymentUseCase;
import com.fintech.wallet.domain.port.in.GetWalletUseCase;
import com.fintech.wallet.domain.port.in.TransactionReversalUseCase;
import com.fintech.wallet.domain.port.out.BillProviderPort;
import org.springframework.stereotype.Service;

@Service
public class PaymentService implements BillPaymentUseCase {

    private final BillProviderPort billProviderPort;
    private final WalletService walletService;
    private final TransactionReversalUseCase transactionReversalUseCase;

    public PaymentService(BillProviderPort billProviderPort, WalletService walletService, TransactionReversalUseCase transactionReversalUseCase) {
        this.billProviderPort = billProviderPort;
        this.walletService = walletService;
        this.transactionReversalUseCase = transactionReversalUseCase;
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
        // Reuse walletService.processPaymentInternal to deduct money safely with Redis Lock + Idempotency
        Transaction transaction = walletService.processPaymentInternal(requestId, userId, walletId, com.fintech.wallet.domain.model.TransactionType.BILL_PAYMENT, amount);
        try {
            billProviderPort.processBillPayment(billId, amount, transaction.getId());
        } catch (Exception e) {
            transactionReversalUseCase.autoReverseFailedWithdrawal(transaction.getId());
            throw new RuntimeException("Thanh toán hóa đơn thất bại, tiền đã được hoàn lại", e);
        }
        return transaction;
    }

    @Override
    public Transaction topupPhone(String requestId, String userId, String walletId, String phoneNumber, Money amount) {
        Transaction transaction = walletService.processPaymentInternal(requestId, userId, walletId, com.fintech.wallet.domain.model.TransactionType.TOPUP, amount);
        try {
            billProviderPort.processPhoneTopup(phoneNumber, amount, transaction.getId());
        } catch (Exception e) {
            transactionReversalUseCase.autoReverseFailedWithdrawal(transaction.getId());
            throw new RuntimeException("Nạp tiền điện thoại thất bại, tiền đã được hoàn lại", e);
        }
        return transaction;
    }
}
