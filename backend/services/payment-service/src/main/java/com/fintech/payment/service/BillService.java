package com.fintech.payment.service;

import com.fintech.payment.domain.entity.Bill;
import com.fintech.payment.domain.entity.TelcoTopup;
import com.fintech.payment.dto.*;
import com.fintech.payment.grpc.WalletGrpcClient;
import com.fintech.payment.repository.BillRepository;
import com.fintech.payment.repository.TelcoTopupRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.Optional;
import java.util.UUID;

@Slf4j
@Service
public class BillService {

    private final BillRepository billRepository;
    private final TelcoTopupRepository telcoTopupRepository;
    private final WalletGrpcClient walletGrpcClient;

    public BillService(BillRepository billRepository,
                       TelcoTopupRepository telcoTopupRepository,
                       WalletGrpcClient walletGrpcClient) {
        this.billRepository = billRepository;
        this.telcoTopupRepository = telcoTopupRepository;
        this.walletGrpcClient = walletGrpcClient;
    }

    @Transactional
    public BillLookupResponse lookupBill(String type, String customerCode) {
        String cleanCode = (customerCode != null) ? customerCode.trim().toUpperCase() : "PE01000123456";
        String cleanType = (type != null) ? type.trim().toUpperCase() : "ELECTRICITY";

        Optional<Bill> existing = billRepository.findByCustomerCodeAndStatus(cleanCode, "UNPAID");
        if (existing.isPresent()) {
            return toLookupResponse(existing.get());
        }

        // Tạo hóa đơn chuẩn deterministic Core Banking
        Bill bill = generateDeterministicBill(cleanType, cleanCode);
        bill = billRepository.save(bill);
        log.info("Generated new utility bill {} for customer {}", bill.getBillId(), cleanCode);
        return toLookupResponse(bill);
    }

    @Transactional
    public BillPaymentResponse payBill(String userId, BillPaymentRequest request) {
        Bill bill = billRepository.findByBillId(request.getBillId())
                .orElseThrow(() -> new IllegalArgumentException("Hóa đơn không tồn tại: " + request.getBillId()));

        if ("PAID".equalsIgnoreCase(bill.getStatus())) {
            throw new IllegalStateException("Hóa đơn đã được thanh toán trước đó: " + request.getBillId());
        }

        String transactionId = UUID.randomUUID().toString();

        // Trừ tiền trong ví qua gRPC
        var debitRes = walletGrpcClient.debit(
                request.getWalletId(),
                request.getAmount().longValue(),
                transactionId,
                "BILL_PAY_" + bill.getBillId()
        );
        if (debitRes == null || !debitRes.isSuccess()) {
            throw new IllegalStateException("Giao dịch không thành công: Số dư ví không đủ hoặc ví đang bị khóa");
        }

        bill.setStatus("PAID");
        bill.setPaidAt(Instant.now());
        bill.setPaidByUserId(userId);
        bill.setTransactionId(transactionId);
        billRepository.save(bill);

        log.info("Bill {} paid successfully by user {}, tx={}", bill.getBillId(), userId, transactionId);

        return BillPaymentResponse.builder()
                .transactionId(transactionId)
                .billId(bill.getBillId())
                .status("SUCCESS")
                .amount(bill.getAmount())
                .message("Thanh toán hóa đơn thành công")
                .build();
    }

    @Transactional
    public PhoneTopupResponse topupPhone(String userId, PhoneTopupRequest request) {
        // Chiết khấu 3% độc quyền Sen Hồng Bank
        BigDecimal discountRate = new BigDecimal("0.03");
        BigDecimal discountAmount = request.getAmount().multiply(discountRate).setScale(2, RoundingMode.HALF_UP);
        BigDecimal netAmount = request.getAmount().subtract(discountAmount);

        String transactionId = UUID.randomUUID().toString();

        var debitRes = walletGrpcClient.debit(
                request.getWalletId(),
                netAmount.longValue(),
                transactionId,
                "TOPUP_" + request.getPhoneNumber()
        );
        if (debitRes == null || !debitRes.isSuccess()) {
            throw new IllegalStateException("Giao dịch không thành công: Số dư ví không đủ để nạp điện thoại");
        }

        String telcoCode = detectTelco(request.getPhoneNumber());
        String serialNumber = "SEN-TOPUP-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();

        TelcoTopup topup = TelcoTopup.builder()
                .userId(userId)
                .phoneNumber(request.getPhoneNumber())
                .telcoCode(telcoCode)
                .topupAmount(request.getAmount())
                .discountAmount(discountAmount)
                .netAmount(netAmount)
                .status("SUCCESS")
                .transactionId(transactionId)
                .serialNumber(serialNumber)
                .build();

        telcoTopupRepository.save(topup);
        log.info("Phone topup of {} for {} completed with 3% discount (net={}), tx={}",
                request.getAmount(), request.getPhoneNumber(), netAmount, transactionId);

        return PhoneTopupResponse.builder()
                .transactionId(transactionId)
                .phoneNumber(request.getPhoneNumber())
                .amount(request.getAmount())
                .discountAmount(discountAmount)
                .netAmount(netAmount)
                .status("SUCCESS")
                .message("Nạp tiền điện thoại thành công")
                .build();
    }

    private String detectTelco(String phone) {
        if (phone == null) return "VIETTEL";
        String p = phone.replaceAll("\\D", "");
        if (p.startsWith("84")) p = "0" + p.substring(2);

        if (p.startsWith("098") || p.startsWith("097") || p.startsWith("086") || p.startsWith("03")) {
            return "VIETTEL";
        } else if (p.startsWith("091") || p.startsWith("094") || p.startsWith("088") || p.startsWith("08")) {
            return "VINAPHONE";
        } else if (p.startsWith("090") || p.startsWith("093") || p.startsWith("089") || p.startsWith("07")) {
            return "MOBIFONE";
        } else if (p.startsWith("056") || p.startsWith("058") || p.startsWith("052")) {
            return "VIETNAMOBILE";
        }
        return "VIETTEL";
    }

    private Bill generateDeterministicBill(String type, String code) {
        String billId = "BILL-" + type.substring(0, Math.min(3, type.length())) + "-" + Math.abs(code.hashCode() % 1000000);
        String providerCode;
        String providerName;
        BigDecimal amount;
        String period = "Kỳ " + LocalDate.now().format(DateTimeFormatter.ofPattern("MM/yyyy"));
        LocalDate dueDate = LocalDate.now().plusDays(7);

        switch (type) {
            case "WATER" -> {
                providerCode = "SAWACO";
                providerName = "Tổng Công ty Cấp nước Sài Gòn (SAWACO)";
                amount = new BigDecimal("245000");
            }
            case "INTERNET" -> {
                providerCode = "VNPT";
                providerName = "Tập đoàn Bưu chính Viễn thông Việt Nam (VNPT)";
                amount = new BigDecimal("330000");
            }
            default -> { // ELECTRICITY
                providerCode = "EVN_HANOI";
                providerName = "Tổng Công ty Điện lực TP. Hà Nội (EVN HANOI)";
                amount = new BigDecimal("485000");
            }
        }

        return Bill.builder()
                .billId(billId)
                .serviceType(type)
                .providerCode(providerCode)
                .customerCode(code)
                .customerName("NGUYỄN VĂN AN")
                .customerAddress("Số 123 Đường Điện Biên Phủ, Phường Đa Kao, Quận 1, TP. Hồ Chí Minh")
                .period(period)
                .amount(amount)
                .fee(BigDecimal.ZERO)
                .dueDate(dueDate)
                .status("UNPAID")
                .build();
    }

    private BillLookupResponse toLookupResponse(Bill bill) {
        String providerName = switch (bill.getProviderCode()) {
            case "SAWACO" -> "Tổng Công ty Cấp nước Sài Gòn (SAWACO)";
            case "VNPT" -> "Tập đoàn Bưu chính Viễn thông Việt Nam (VNPT)";
            default -> "Tổng Công ty Điện lực TP. Hà Nội (EVN HANOI)";
        };

        return BillLookupResponse.builder()
                .billId(bill.getBillId())
                .serviceType(bill.getServiceType())
                .providerCode(bill.getProviderCode())
                .providerName(providerName)
                .customerCode(bill.getCustomerCode())
                .customerName(bill.getCustomerName())
                .customerAddress(bill.getCustomerAddress())
                .period(bill.getPeriod())
                .amount(bill.getAmount())
                .fee(bill.getFee())
                .dueDate(bill.getDueDate())
                .status(bill.getStatus())
                .build();
    }
}
