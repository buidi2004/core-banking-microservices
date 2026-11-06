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
    private final com.fintech.payment.repository.BillSubscriptionRepository billSubscriptionRepository;

    public BillService(BillRepository billRepository,
                       TelcoTopupRepository telcoTopupRepository,
                       WalletGrpcClient walletGrpcClient) {
        this(billRepository, telcoTopupRepository, walletGrpcClient, null);
    }

    @org.springframework.beans.factory.annotation.Autowired
    public BillService(BillRepository billRepository,
                       TelcoTopupRepository telcoTopupRepository,
                       WalletGrpcClient walletGrpcClient,
                       @org.springframework.beans.factory.annotation.Autowired(required = false) com.fintech.payment.repository.BillSubscriptionRepository billSubscriptionRepository) {
        this.billRepository = billRepository;
        this.telcoTopupRepository = telcoTopupRepository;
        this.walletGrpcClient = walletGrpcClient;
        this.billSubscriptionRepository = billSubscriptionRepository;
    }

    @Transactional
    public BillLookupResponse lookupBill(String type, String customerCode) {
        String cleanCode = (customerCode != null) ? customerCode.trim().toUpperCase() : "PE01000123456";
        String cleanType = normalizeBillType(type);

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

    private String normalizeBillType(String raw) {
        if (raw == null || raw.isBlank()) return "ELECTRICITY";
        String upper = raw.trim().toUpperCase();
        if (upper.contains("WATER") || upper.contains("NUOC") || upper.contains("NƯỚC")) {
            return "WATER";
        }
        if (upper.contains("INTERNET") || upper.contains("WIFI") || upper.contains("MẠNG") || upper.contains("CAP") || upper.contains("CÁP")) {
            return "INTERNET";
        }
        return "ELECTRICITY";
    }

    @Transactional
    public BillPaymentResponse payBill(String userId, BillPaymentRequest request) {
        Bill bill = billRepository.findByBillId(request.getBillId())
                .orElseThrow(() -> new IllegalArgumentException("Hóa đơn không tồn tại: " + request.getBillId()));

        if ("PAID".equalsIgnoreCase(bill.getStatus())) {
            throw new IllegalStateException("Hóa đơn đã được thanh toán trước đó: " + request.getBillId());
        }

        String transactionId = UUID.randomUUID().toString();
        String idempKey = (request.getRequestId() != null && !request.getRequestId().isBlank())
                ? request.getRequestId().trim()
                : ("BILL_PAY_" + bill.getBillId() + "_" + transactionId);

        // Trừ tiền trong ví qua gRPC
        var debitRes = walletGrpcClient.debit(
                request.getWalletId(),
                request.getAmount().longValue(),
                transactionId,
                idempKey
        );
        if (debitRes == null || !debitRes.isSuccess()) {
            String errMsg = debitRes != null && debitRes.getErrorMessage() != null
                    ? debitRes.getErrorMessage()
                    : "Số dư ví không đủ hoặc ví đang bị khóa";
            throw new IllegalStateException("Giao dịch không thành công: " + errMsg);
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
        String topupIdemKey = "TOPUP_" + transactionId;

        var debitRes = walletGrpcClient.debit(
                request.getWalletId(),
                netAmount.longValue(),
                transactionId,
                topupIdemKey
        );
        if (debitRes == null || !debitRes.isSuccess()) {
            String err = (debitRes != null && debitRes.getErrorMessage() != null)
                    ? debitRes.getErrorMessage()
                    : "Số dư ví không đủ để nạp điện thoại";
            throw new IllegalStateException("Giao dịch không thành công: " + err);
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
        String periodSuffix = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMM"));
        String baseId = "BILL-" + type.substring(0, Math.min(3, type.length())) + "-" + periodSuffix + "-" + Math.abs(code.hashCode() % 100000);
        String billId = baseId;
        int counter = 1;
        while (billRepository.findByBillId(billId).isPresent()) {
            billId = baseId + "-" + counter++;
        }
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

    @Transactional
    public BillSubscriptionResponse createSubscription(String userId, CreateBillSubscriptionRequest request) {
        String walletId = request.getWalletId();
        if (walletId == null || walletId.isBlank()) {
            var userWallet = walletGrpcClient.getWalletByUserId(userId);
            if (userWallet != null && userWallet.isFound()) {
                walletId = userWallet.getWalletId();
            } else {
                throw new IllegalArgumentException("Không tìm thấy ví cho người dùng: " + userId);
            }
        }

        com.fintech.payment.domain.entity.BillSubscription sub = com.fintech.payment.domain.entity.BillSubscription.builder()
                .userId(userId)
                .walletId(walletId)
                .billType(normalizeBillType(request.getBillType()))
                .customerCode(request.getCustomerCode().trim().toUpperCase())
                .providerCode(request.getProviderCode().trim().toUpperCase())
                .autoDebitDay(request.getAutoDebitDay() != null ? request.getAutoDebitDay() : 5)
                .status("ACTIVE")
                .build();

        sub = billSubscriptionRepository.save(sub);
        log.info("Đã đăng ký trích nợ tự động hóa đơn cho user {}: billType={} code={}", userId, sub.getBillType(), sub.getCustomerCode());
        return BillSubscriptionResponse.from(sub);
    }

    public java.util.List<BillSubscriptionResponse> getUserSubscriptions(String userId) {
        return billSubscriptionRepository.findByUserIdOrderByCreatedAtDesc(userId).stream()
                .map(BillSubscriptionResponse::from)
                .toList();
    }

    @Transactional
    public BillSubscriptionResponse cancelSubscription(UUID id, String userId) {
        var sub = billSubscriptionRepository.findByIdAndUserId(id, userId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy ủy thác trích nợ tự động: " + id));
        sub.setStatus("CANCELLED");
        sub = billSubscriptionRepository.save(sub);
        return BillSubscriptionResponse.from(sub);
    }

    @Transactional
    public java.util.Map<String, Object> executeDueSubscriptions() {
        int todayDay = LocalDate.now().getDayOfMonth();
        java.util.List<com.fintech.payment.domain.entity.BillSubscription> dueSubs =
                billSubscriptionRepository.findByStatusAndAutoDebitDay("ACTIVE", todayDay);

        int total = dueSubs.size();
        int success = 0;
        int failed = 0;

        for (var sub : dueSubs) {
            try {
                BillLookupResponse bill = lookupBill(sub.getBillType(), sub.getCustomerCode());
                if ("UNPAID".equalsIgnoreCase(bill.getStatus())) {
                    BillPaymentRequest payReq = BillPaymentRequest.builder()
                            .billId(bill.getBillId())
                            .walletId(sub.getWalletId())
                            .amount(bill.getAmount())
                            .currency("VND")
                            .requestId("auto_bill_" + sub.getId() + "_" + System.currentTimeMillis())
                            .build();
                    payBill(sub.getUserId(), payReq);
                    sub.setLastDeductedAt(Instant.now());
                    billSubscriptionRepository.save(sub);
                    success++;
                }
            } catch (Exception e) {
                log.error("Lỗi trích nợ tự động hóa đơn cho subId={}: {}", sub.getId(), e.getMessage());
                failed++;
            }
        }

        return java.util.Map.of(
                "todayDay", todayDay,
                "totalSubscriptions", total,
                "successCount", success,
                "failedCount", failed
        );
    }
}
