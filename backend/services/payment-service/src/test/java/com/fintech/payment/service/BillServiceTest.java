package com.fintech.payment.service;

import com.fintech.payment.domain.entity.Bill;
import com.fintech.payment.domain.entity.TelcoTopup;
import com.fintech.payment.dto.*;
import com.fintech.payment.grpc.WalletGrpcClient;
import com.fintech.payment.grpc.dto.WalletBalanceResult;
import com.fintech.payment.repository.BillRepository;
import com.fintech.payment.repository.TelcoTopupRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class BillServiceTest {

    @Mock
    private BillRepository billRepository;

    @Mock
    private TelcoTopupRepository telcoTopupRepository;

    @Mock
    private WalletGrpcClient walletGrpcClient;

    private BillService billService;

    private final String userId = UUID.randomUUID().toString();
    private final String walletId = UUID.randomUUID().toString();

    @BeforeEach
    void setUp() {
        billService = new BillService(billRepository, telcoTopupRepository, walletGrpcClient);
    }

    @Test
    @DisplayName("lookupBill: Tra cứu thông tin hóa đơn điện/nước/internet xác định")
    void lookupBill_DeterministicLookup_ReturnsBill() {
        String customerCode = "PE01000123456";
        String type = "ELECTRICITY";

        when(billRepository.findByCustomerCodeAndStatus(customerCode, "UNPAID")).thenReturn(Optional.empty());
        when(billRepository.save(any(Bill.class))).thenAnswer(invocation -> invocation.getArgument(0));

        BillLookupResponse res = billService.lookupBill(type, customerCode);

        assertThat(res).isNotNull();
        assertThat(res.getCustomerCode()).isEqualTo(customerCode);
        assertThat(res.getCustomerName()).isNotEmpty();
        assertThat(res.getAmount()).isGreaterThan(BigDecimal.ZERO);
        assertThat(res.getStatus()).isEqualTo("UNPAID");

        verify(billRepository).save(any(Bill.class));
    }

    @Test
    @DisplayName("payBill: Thanh toán hóa đơn thành công và trừ tiền ví qua gRPC")
    void payBill_Success() {
        String billId = "BILL-EVN-001";
        Bill bill = Bill.builder()
                .id(UUID.randomUUID().toString())
                .billId(billId)
                .serviceType("ELECTRICITY")
                .providerCode("EVN_HANOI")
                .customerCode("PE01000123456")
                .customerName("NGUYEN VAN A")
                .amount(new BigDecimal("485000"))
                .status("UNPAID")
                .build();

        BillPaymentRequest req = BillPaymentRequest.builder()
                .requestId("REQ-001")
                .walletId(walletId)
                .billId(billId)
                .amount(new BigDecimal("485000"))
                .currency("VND")
                .build();

        when(billRepository.findByBillId(billId)).thenReturn(Optional.of(bill));
        when(walletGrpcClient.debit(eq(walletId), eq(485000L), anyString(), anyString()))
                .thenReturn(WalletBalanceResult.builder().success(true).build());
        when(billRepository.save(any(Bill.class))).thenAnswer(invocation -> invocation.getArgument(0));

        BillPaymentResponse res = billService.payBill(userId, req);

        assertThat(res).isNotNull();
        assertThat(res.getStatus()).isEqualTo("SUCCESS");
        assertThat(res.getBillId()).isEqualTo(billId);
        assertThat(bill.getStatus()).isEqualTo("PAID");

        verify(walletGrpcClient).debit(eq(walletId), eq(485000L), anyString(), anyString());
        verify(billRepository).save(bill);
    }

    @Test
    @DisplayName("payBill: Báo lỗi nếu hóa đơn đã được thanh toán")
    void payBill_AlreadyPaid_ThrowsException() {
        String billId = "BILL-PAID-001";
        Bill bill = Bill.builder()
                .billId(billId)
                .amount(new BigDecimal("200000"))
                .status("PAID")
                .build();

        when(billRepository.findByBillId(billId)).thenReturn(Optional.of(bill));

        BillPaymentRequest req = BillPaymentRequest.builder()
                .walletId(walletId)
                .billId(billId)
                .amount(new BigDecimal("200000"))
                .build();

        assertThatThrownBy(() -> billService.payBill(userId, req))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("Hóa đơn đã được thanh toán");

        verifyNoInteractions(walletGrpcClient);
    }

    @Test
    @DisplayName("topupPhone: Nạp tiền điện thoại có chiết khấu 3% và trừ tiền ví")
    void topupPhone_Success() {
        PhoneTopupRequest req = PhoneTopupRequest.builder()
                .requestId("TOPUP-001")
                .walletId(walletId)
                .phoneNumber("0988123456")
                .amount(new BigDecimal("100000"))
                .currency("VND")
                .build();

        when(walletGrpcClient.debit(eq(walletId), eq(97000L), anyString(), anyString()))
                .thenReturn(WalletBalanceResult.builder().success(true).build());
        when(telcoTopupRepository.save(any(TelcoTopup.class))).thenAnswer(invocation -> invocation.getArgument(0));

        PhoneTopupResponse res = billService.topupPhone(userId, req);

        assertThat(res).isNotNull();
        assertThat(res.getStatus()).isEqualTo("SUCCESS");
        assertThat(res.getPhoneNumber()).isEqualTo("0988123456");
        assertThat(res.getAmount()).isEqualByComparingTo(new BigDecimal("100000"));
        assertThat(res.getDiscountAmount()).isEqualByComparingTo(new BigDecimal("3000.00"));
        assertThat(res.getNetAmount()).isEqualByComparingTo(new BigDecimal("97000.00"));

        verify(walletGrpcClient).debit(eq(walletId), eq(97000L), anyString(), anyString());
        verify(telcoTopupRepository).save(any(TelcoTopup.class));
    }
}
