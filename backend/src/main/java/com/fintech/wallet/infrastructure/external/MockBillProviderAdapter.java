package com.fintech.wallet.infrastructure.external;

import com.fintech.wallet.domain.model.Bill;
import com.fintech.wallet.domain.model.BillType;
import com.fintech.wallet.domain.model.Money;
import com.fintech.wallet.domain.port.out.BillProviderPort;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;

import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;

@Component
public class MockBillProviderAdapter implements BillProviderPort {

    private static final Logger log = LoggerFactory.getLogger(MockBillProviderAdapter.class);

    @Override
    @CircuitBreaker(name = "billProvider")
    public Bill fetchBill(BillType billType, String customerCode) {
        log.info("Mocking fetch bill for type={} customerCode={}", billType, customerCode);
        return new Bill(
                "BILL_" + System.currentTimeMillis(),
                billType,
                customerCode,
                "EVN_HANOI",
                "NGUYEN VAN A",
                new BigDecimal("250000.00"),
                "07/2026",
                false
        );
    }

    @Override
    @CircuitBreaker(name = "billProvider")
    public boolean processBillPayment(String billId, Money amount, String transactionReference) {
        log.info("Mock Bill Payment: Settled billId={} amount={} txRef={}", billId, amount, transactionReference);
        return true;
    }

    @Override
    @CircuitBreaker(name = "billProvider")
    public boolean processPhoneTopup(String phoneNumber, Money amount, String transactionReference) {
        log.info("Mock Phone Topup: Recharged phoneNumber={} amount={} txRef={}", phoneNumber, amount, transactionReference);
        return true;
    }
}
