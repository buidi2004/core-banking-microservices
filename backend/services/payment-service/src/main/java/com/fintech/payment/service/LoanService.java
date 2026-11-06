package com.fintech.payment.service;

import com.fintech.payment.domain.entity.LoanContract;
import com.fintech.payment.domain.entity.LoanScheduleItem;
import com.fintech.payment.dto.*;
import com.fintech.payment.grpc.WalletGrpcClient;
import com.fintech.payment.repository.LoanContractRepository;
import com.fintech.payment.repository.LoanScheduleItemRepository;
import com.fintech.payment.security.PinTokenValidator;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.lang.Nullable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Slf4j
@Service
public class LoanService {

    private final LoanContractRepository loanContractRepository;
    private final LoanScheduleItemRepository loanScheduleItemRepository;
    private final WalletGrpcClient walletGrpcClient;
    private final PinTokenValidator pinTokenValidator;
    private final com.fintech.payment.repository.TransactionRepository transactionRepository;

    public LoanService(LoanContractRepository loanContractRepository,
                       LoanScheduleItemRepository loanScheduleItemRepository,
                       WalletGrpcClient walletGrpcClient,
                       PinTokenValidator pinTokenValidator) {
        this(loanContractRepository, loanScheduleItemRepository, walletGrpcClient, pinTokenValidator, null);
    }

    @Autowired
    public LoanService(LoanContractRepository loanContractRepository,
                       LoanScheduleItemRepository loanScheduleItemRepository,
                       WalletGrpcClient walletGrpcClient,
                       PinTokenValidator pinTokenValidator,
                       @Nullable com.fintech.payment.repository.TransactionRepository transactionRepository) {
        this.loanContractRepository = loanContractRepository;
        this.loanScheduleItemRepository = loanScheduleItemRepository;
        this.walletGrpcClient = walletGrpcClient;
        this.pinTokenValidator = pinTokenValidator;
        this.transactionRepository = transactionRepository;
    }

    public List<LoanProductDto> getProducts() {
        return List.of(
                LoanProductDto.builder()
                        .productType("VAY_TIEU_DUNG_NHANH")
                        .productName("Vay Tiêu Dùng Sen Hồng")
                        .description("Duyệt tự động 15 phút, giải ngân trực tiếp vào ví Sen Hồng")
                        .minAmount(new BigDecimal("5000000"))
                        .maxAmount(new BigDecimal("50000000"))
                        .annualRate(new BigDecimal("14.4"))
                        .availableTerms(List.of(3, 6, 12, 24))
                        .build(),
                LoanProductDto.builder()
                        .productType("VAY_THAU_CHI")
                        .productName("Vay Thấu Chi Tiêu Dùng")
                        .description("Chi tiêu trước trả tiền sau, miễn lãi tối đa 45 ngày")
                        .minAmount(new BigDecimal("5000000"))
                        .maxAmount(new BigDecimal("30000000"))
                        .annualRate(new BigDecimal("13.5"))
                        .availableTerms(List.of(3, 6, 12))
                        .build()
        );
    }

    @Transactional
    public LoanApplicationResponse applyLoan(String userId, LoanApplicationRequest request) {
        String effectiveWalletId = request.getWalletId();
        if (effectiveWalletId == null || effectiveWalletId.isBlank()) {
            var userWallet = walletGrpcClient.getWalletByUserId(userId);
            if (userWallet != null && userWallet.isFound()) {
                effectiveWalletId = userWallet.getWalletId();
            } else {
                throw new IllegalArgumentException("Không tìm thấy ví cho người dùng " + userId);
            }
        }

        if (request.getOtpToken() != null && !request.getOtpToken().isBlank()) {
            pinTokenValidator.validateOtp(request.getOtpToken(), "LOAN_APPLY");
        } else if (request.getPinToken() != null && !request.getPinToken().isBlank()) {
            pinTokenValidator.validate(userId, request.getPinToken());
        } else {
            throw new IllegalArgumentException("Vui lòng nhập và xác thực mã OTP hoặc mã PIN trước khi nộp hồ sơ vay vốn");
        }

        BigDecimal minAmount = new BigDecimal("5000000");
        BigDecimal maxAmount = new BigDecimal("50000000");

        if (request.getAmount().compareTo(minAmount) < 0 || request.getAmount().compareTo(maxAmount) > 0) {
            throw new IllegalArgumentException("Hạn mức vay từ " + minAmount.toPlainString() + " đến " + maxAmount.toPlainString() + " VND");
        }

        BigDecimal annualRate = new BigDecimal("14.4");
        BigDecimal monthlyRate = annualRate.divide(BigDecimal.valueOf(100), 6, RoundingMode.HALF_UP)
                .divide(BigDecimal.valueOf(12), 6, RoundingMode.HALF_UP);

        int termMonths = request.getTermMonths();
        BigDecimal monthlyPrincipal = request.getAmount().divide(BigDecimal.valueOf(termMonths), 0, RoundingMode.HALF_UP);

        String contractNumber = "LN-" + System.currentTimeMillis();
        LocalDate startDate = LocalDate.now();
        LocalDate firstDueDate = startDate.plusMonths(1);

        BigDecimal currentRemaining = request.getAmount();
        BigDecimal totalInterest = BigDecimal.ZERO;
        BigDecimal firstMonthlyPayment = BigDecimal.ZERO;

        List<LoanScheduleItem> scheduleItems = new ArrayList<>();

        for (int i = 1; i <= termMonths; i++) {
            BigDecimal termPrincipal = (i == termMonths) ? currentRemaining : monthlyPrincipal;
            BigDecimal termInterest = currentRemaining.multiply(monthlyRate).setScale(0, RoundingMode.HALF_UP);
            BigDecimal termTotal = termPrincipal.add(termInterest);
            BigDecimal balanceAfter = currentRemaining.subtract(termPrincipal);

            totalInterest = totalInterest.add(termInterest);
            if (i == 1) {
                firstMonthlyPayment = termTotal;
            }

            LoanScheduleItem item = LoanScheduleItem.builder()
                    .termNumber(i)
                    .dueDate(startDate.plusMonths(i))
                    .principalAmount(termPrincipal)
                    .interestAmount(termInterest)
                    .totalAmount(termTotal)
                    .remainingBalance(balanceAfter)
                    .status(i == 1 ? "DUE" : "UPCOMING")
                    .build();

            scheduleItems.add(item);
            currentRemaining = balanceAfter;
        }

        BigDecimal totalRepayment = request.getAmount().add(totalInterest);

        // Chuyển sang trạng thái PENDING_APPROVAL chờ cán bộ duyệt
        LoanContract contract = LoanContract.builder()
                .userId(userId)
                .walletId(effectiveWalletId)
                .contractNumber(contractNumber)
                .productType(request.getProductType())
                .productName("Vay Tiêu Dùng Sen Hồng")
                .principalAmount(request.getAmount())
                .annualInterestRate(annualRate)
                .termMonths(termMonths)
                .totalInterest(totalInterest)
                .totalRepayment(totalRepayment)
                .remainingPrincipal(request.getAmount())
                .monthlyPayment(firstMonthlyPayment)
                .purpose(request.getPurpose())
                .status("PENDING_APPROVAL")
                .build();

        LoanContract savedContract = loanContractRepository.save(contract);
        log.info("Received loan application {} of {} VND for user {}, pending staff approval",
                contractNumber, request.getAmount(), userId);

        return toResponse(savedContract);
    }

    public List<LoanApplicationResponse> getPendingLoans() {
        return loanContractRepository.findByStatusOrderByCreatedAtDesc("PENDING_APPROVAL").stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    @Transactional
    public LoanApplicationResponse approveLoan(String loanId, String staffUsername, String staffRole) {
        if (staffRole == null || (!staffRole.contains("TELLER") && !staffRole.contains("MANAGER"))) {
            throw new SecurityException("Chỉ cán bộ giao dịch viên (TELLER) hoặc kiểm soát viên (MANAGER) mới có quyền duyệt khoản vay");
        }

        LoanContract contract = findContract(loanId, null);

        if (!"PENDING_APPROVAL".equals(contract.getStatus())) {
            throw new IllegalStateException("Khoản vay không ở trạng thái chờ duyệt. Trạng thái hiện tại: " + contract.getStatus());
        }

        // Giải ngân vào ví người dùng qua gRPC
        String disbTxId = "LN_DISB_" + contract.getContractNumber();
        String disbIdemKey = "idem:loan:disb:" + contract.getContractNumber();
        var creditRes = walletGrpcClient.credit(
                contract.getWalletId(),
                contract.getPrincipalAmount().longValue(),
                disbTxId,
                disbIdemKey
        );
        if (creditRes != null && !creditRes.isSuccess()) {
            throw new IllegalStateException("Giải ngân vào ví thất bại: " + creditRes.getErrorMessage());
        }

        // Tạo lịch trả nợ
        LocalDate startDate = LocalDate.now();
        LocalDate firstDueDate = startDate.plusMonths(1);
        int termMonths = contract.getTermMonths();
        BigDecimal monthlyRate = contract.getAnnualInterestRate()
                .divide(BigDecimal.valueOf(100), 6, RoundingMode.HALF_UP)
                .divide(BigDecimal.valueOf(12), 6, RoundingMode.HALF_UP);
        BigDecimal monthlyPrincipal = contract.getPrincipalAmount().divide(BigDecimal.valueOf(termMonths), 0, RoundingMode.HALF_UP);
        BigDecimal currentRemaining = contract.getPrincipalAmount();

        List<LoanScheduleItem> scheduleItems = new ArrayList<>();
        for (int i = 1; i <= termMonths; i++) {
            BigDecimal termPrincipal = (i == termMonths) ? currentRemaining : monthlyPrincipal;
            BigDecimal termInterest = currentRemaining.multiply(monthlyRate).setScale(0, RoundingMode.HALF_UP);
            BigDecimal termTotal = termPrincipal.add(termInterest);
            BigDecimal balanceAfter = currentRemaining.subtract(termPrincipal);

            LoanScheduleItem item = LoanScheduleItem.builder()
                    .loanContractId(contract.getId())
                    .termNumber(i)
                    .dueDate(startDate.plusMonths(i))
                    .principalAmount(termPrincipal)
                    .interestAmount(termInterest)
                    .totalAmount(termTotal)
                    .remainingBalance(balanceAfter)
                    .status(i == 1 ? "DUE" : "UPCOMING")
                    .build();

            scheduleItems.add(item);
            currentRemaining = balanceAfter;
        }
        loanScheduleItemRepository.saveAll(scheduleItems);

        contract.setStatus("DISBURSED");
        contract.setDisbursedAt(Instant.now());
        contract.setFirstDueDate(firstDueDate);
        contract.setApprovedBy(staffUsername);
        contract.setApprovedAt(Instant.now());

        // Ghi nhận biến động số dư giải ngân trong bảng transactions
        if (transactionRepository != null) {
            try {
                com.fintech.payment.domain.entity.Transaction tx = com.fintech.payment.domain.entity.Transaction.builder()
                        .transactionCode("TXN_" + UUID.randomUUID().toString().substring(0, 12).toUpperCase())
                        .targetWalletId(contract.getWalletId())
                        .receiverId(contract.getUserId())
                        .amount(contract.getPrincipalAmount().longValue())
                        .fee(0L)
                        .currency("VND")
                        .type("LOAN_DISBURSEMENT")
                        .status("SUCCESS")
                        .targetBalanceAfter(creditRes != null ? creditRes.getBalanceAfter() : null)
                        .idempotencyKey(disbIdemKey)
                        .note("Giải ngân khoản vay " + contract.getContractNumber())
                        .build();
                transactionRepository.save(tx);
            } catch (Exception e) {
                log.warn("Lưu transaction giải ngân thất bại: {}", e.getMessage());
            }
        }

        LoanContract updated = loanContractRepository.save(contract);
        log.info("Staff {} ({}) approved and disbursed loan {} of {} VND",
                staffUsername, staffRole, contract.getContractNumber(), contract.getPrincipalAmount());

        return toResponse(updated);
    }

    @Transactional
    public LoanApplicationResponse rejectLoan(String loanId, String staffUsername, String staffRole, String reason) {
        if (staffRole == null || (!staffRole.contains("TELLER") && !staffRole.contains("MANAGER"))) {
            throw new SecurityException("Chỉ cán bộ giao dịch viên (TELLER) hoặc kiểm soát viên (MANAGER) mới có quyền từ chối khoản vay");
        }

        LoanContract contract = findContract(loanId, null);

        if (!"PENDING_APPROVAL".equals(contract.getStatus())) {
            throw new IllegalStateException("Khoản vay không ở trạng thái chờ duyệt. Trạng thái hiện tại: " + contract.getStatus());
        }

        contract.setStatus("REJECTED");
        contract.setApprovedBy(staffUsername);
        contract.setApprovedAt(Instant.now());
        contract.setRejectReason((reason != null && !reason.isBlank()) ? reason : "Không đủ điều kiện cấp tín dụng");

        LoanContract updated = loanContractRepository.save(contract);
        log.info("Staff {} ({}) rejected loan {}: reason={}",
                staffUsername, staffRole, contract.getContractNumber(), contract.getRejectReason());

        return toResponse(updated);
    }

    public List<LoanApplicationResponse> getUserLoans(String userId) {
        return loanContractRepository.findByUserIdOrderByCreatedAtDesc(userId).stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    public LoanApplicationResponse getLoanDetail(String loanId, String userId) {
        LoanContract contract = findContract(loanId, userId);
        return toResponse(contract);
    }

    public LoanScheduleResponse getLoanSchedule(String loanId, String userId) {
        LoanContract contract = findContract(loanId, userId);

        List<LoanScheduleItem> items = loanScheduleItemRepository.findByLoanContractIdOrderByTermNumberAsc(contract.getId());

        List<LoanScheduleResponse.ScheduleItemDto> dtoList = items.stream()
                .map(item -> LoanScheduleResponse.ScheduleItemDto.builder()
                        .termNumber(item.getTermNumber())
                        .dueDate(item.getDueDate().toString())
                        .principalAmount(item.getPrincipalAmount())
                        .interestAmount(item.getInterestAmount())
                        .totalAmount(item.getTotalAmount())
                        .remainingBalance(item.getRemainingBalance())
                        .status(item.getStatus())
                        .paidDate(item.getPaidDate() != null ? item.getPaidDate().toString() : null)
                        .build())
                .collect(Collectors.toList());

        return LoanScheduleResponse.builder()
                .contractNumber(contract.getContractNumber())
                .principalAmount(contract.getPrincipalAmount())
                .termMonths(contract.getTermMonths())
                .schedule(dtoList)
                .build();
    }

    @Transactional
    public LoanRepaymentResponse repayTerm(String loanId, String userId, LoanRepaymentRequest request) {
        if (request.getPinToken() != null && !request.getPinToken().isBlank()) {
            pinTokenValidator.validate(userId, request.getPinToken());
        }

        LoanContract contract = findContract(loanId, userId);

        LoanScheduleItem item = loanScheduleItemRepository.findByLoanContractIdAndTermNumber(contract.getId(), request.getTermNumber())
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy kỳ hạn thanh toán " + request.getTermNumber()));

        if ("PAID".equals(item.getStatus())) {
            throw new IllegalStateException("Kỳ hạn số " + request.getTermNumber() + " đã được thanh toán trước đó");
        }

        BigDecimal payAmount = request.getAmount() != null ? request.getAmount() : item.getTotalAmount();

        // Debit repayment from user wallet
        String repayTxId = "LN_RPAY_" + contract.getContractNumber() + "_T" + request.getTermNumber();
        String repayIdemKey = "idem:loan:repay:" + contract.getContractNumber() + "_T" + request.getTermNumber();
        var debitRes = walletGrpcClient.debit(
                contract.getWalletId(),
                payAmount.longValue(),
                repayTxId,
                repayIdemKey
        );
        if (debitRes != null && !debitRes.isSuccess()) {
            throw new IllegalStateException("Trừ tiền ví trả nợ thất bại: " + debitRes.getErrorMessage());
        }

        item.setStatus("PAID");
        item.setPaidDate(LocalDate.now());
        loanScheduleItemRepository.save(item);

        BigDecimal newRemaining = contract.getRemainingPrincipal().subtract(item.getPrincipalAmount());
        if (newRemaining.compareTo(BigDecimal.ZERO) < 0) {
            newRemaining = BigDecimal.ZERO;
        }
        contract.setRemainingPrincipal(newRemaining);

        // Check if all terms are paid
        List<LoanScheduleItem> allTerms = loanScheduleItemRepository.findByLoanContractIdOrderByTermNumberAsc(contract.getId());
        boolean allPaid = allTerms.stream().allMatch(t -> "PAID".equals(t.getStatus()));
        if (allPaid) {
            contract.setStatus("SETTLED");
        }
        loanContractRepository.save(contract);

        // Ghi nhận biến động số dư trả nợ trong bảng transactions
        if (transactionRepository != null) {
            try {
                com.fintech.payment.domain.entity.Transaction tx = com.fintech.payment.domain.entity.Transaction.builder()
                        .transactionCode("TXN_" + UUID.randomUUID().toString().substring(0, 12).toUpperCase())
                        .sourceWalletId(contract.getWalletId())
                        .senderId(contract.getUserId())
                        .amount(payAmount.longValue())
                        .fee(0L)
                        .currency("VND")
                        .type("LOAN_REPAYMENT")
                        .status("SUCCESS")
                        .sourceBalanceAfter(debitRes != null ? debitRes.getBalanceAfter() : null)
                        .idempotencyKey(repayIdemKey)
                        .note("Thanh toán kỳ nợ số " + request.getTermNumber() + " hợp đồng " + contract.getContractNumber())
                        .build();
                transactionRepository.save(tx);
            } catch (Exception e) {
                log.warn("Lưu transaction trả nợ thất bại: {}", e.getMessage());
            }
        }

        log.info("Repaid term {} for loan {}, remaining: {}", request.getTermNumber(), contract.getContractNumber(), newRemaining);

        return LoanRepaymentResponse.builder()
                .contractNumber(contract.getContractNumber())
                .termNumber(request.getTermNumber())
                .paidAmount(payAmount)
                .remainingPrincipal(newRemaining)
                .status("PAID")
                .isFullyRepaid(allPaid)
                .message("Thanh toán kỳ hạn " + request.getTermNumber() + " thành công")
                .build();
    }

    @Transactional
    public LoanRepaymentResponse settleLoanEarly(String loanId, String userId, String pinToken) {
        if (pinToken != null && !pinToken.isBlank()) {
            pinTokenValidator.validate(userId, pinToken);
        }

        LoanContract contract = findContract(loanId, userId);
        if (!"DISBURSED".equals(contract.getStatus())) {
            throw new IllegalStateException("Khoản vay không ở trạng thái đang giải ngân (DISBURSED). Trạng thái hiện tại: " + contract.getStatus());
        }

        List<LoanScheduleItem> allTerms = loanScheduleItemRepository.findByLoanContractIdOrderByTermNumberAsc(contract.getId());
        List<LoanScheduleItem> unpaidTerms = allTerms.stream()
                .filter(t -> !"PAID".equals(t.getStatus()))
                .collect(Collectors.toList());

        if (unpaidTerms.isEmpty()) {
            contract.setStatus("SETTLED");
            contract.setRemainingPrincipal(BigDecimal.ZERO);
            loanContractRepository.save(contract);
            throw new IllegalStateException("Khoản vay đã được thanh toán toàn bộ tất cả các kỳ");
        }

        // Tính tổng dư nợ gốc còn lại của các kỳ chưa trả
        BigDecimal remainingPrincipal = unpaidTerms.stream()
                .map(LoanScheduleItem::getPrincipalAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        // Phí tất toán trước hạn (1% theo thông lệ ngân hàng Việt Nam, làm tròn)
        BigDecimal penaltyFee = remainingPrincipal.multiply(new BigDecimal("0.01")).setScale(0, RoundingMode.HALF_UP);
        BigDecimal totalSettleAmount = remainingPrincipal.add(penaltyFee);

        // Trừ tiền ví khách hàng
        String settleTxId = "LN_SETTLE_" + contract.getContractNumber();
        String settleIdemKey = "idem:loan:settle:" + contract.getContractNumber();
        var debitRes = walletGrpcClient.debit(
                contract.getWalletId(),
                totalSettleAmount.longValue(),
                settleTxId,
                settleIdemKey
        );
        if (debitRes != null && !debitRes.isSuccess()) {
            throw new IllegalStateException("Trừ tiền ví để tất toán trước hạn thất bại: " + debitRes.getErrorMessage());
        }

        // Đánh dấu tất cả kỳ nợ thành PAID
        LocalDate today = LocalDate.now();
        for (LoanScheduleItem item : unpaidTerms) {
            item.setStatus("PAID");
            item.setPaidDate(today);
            item.setRemainingBalance(BigDecimal.ZERO);
        }
        loanScheduleItemRepository.saveAll(unpaidTerms);

        // Cập nhật hợp đồng
        contract.setStatus("SETTLED");
        contract.setRemainingPrincipal(BigDecimal.ZERO);
        loanContractRepository.save(contract);

        // Ghi transaction
        if (transactionRepository != null) {
            try {
                com.fintech.payment.domain.entity.Transaction tx = com.fintech.payment.domain.entity.Transaction.builder()
                        .transactionCode("TXN_" + UUID.randomUUID().toString().substring(0, 12).toUpperCase())
                        .sourceWalletId(contract.getWalletId())
                        .senderId(contract.getUserId())
                        .amount(totalSettleAmount.longValue())
                        .fee(penaltyFee.longValue())
                        .currency("VND")
                        .type("LOAN_EARLY_SETTLEMENT")
                        .status("SUCCESS")
                        .sourceBalanceAfter(debitRes != null ? debitRes.getBalanceAfter() : null)
                        .idempotencyKey(settleIdemKey)
                        .note("Tất toán trước hạn hợp đồng vay " + contract.getContractNumber() + " (Phí tất toán sớm 1%)")
                        .build();
                transactionRepository.save(tx);
            } catch (Exception e) {
                log.warn("Lưu transaction tất toán trước hạn thất bại: {}", e.getMessage());
            }
        }

        log.info("Khách hàng {} đã tất toán trước hạn hợp đồng {}. Tổng tiền: {} VND (Gốc: {}, Phí 1%: {})",
                userId, contract.getContractNumber(), totalSettleAmount, remainingPrincipal, penaltyFee);

        return LoanRepaymentResponse.builder()
                .contractNumber(contract.getContractNumber())
                .termNumber(0)
                .paidAmount(totalSettleAmount)
                .remainingPrincipal(BigDecimal.ZERO)
                .status("SETTLED")
                .isFullyRepaid(true)
                .message("Tất toán trước hạn thành công hợp đồng vay " + contract.getContractNumber())
                .build();
    }

    private LoanContract findContract(String loanIdOrContractNumber, String userId) {
        if (loanIdOrContractNumber == null || loanIdOrContractNumber.isBlank()) {
            throw new IllegalArgumentException("Mã hợp đồng vay không được để trống");
        }
        try {
            UUID uuid = UUID.fromString(loanIdOrContractNumber.trim());
            java.util.Optional<LoanContract> byId = userId != null
                    ? loanContractRepository.findByIdAndUserId(uuid, userId)
                    : loanContractRepository.findById(uuid);
            if (byId.isPresent()) return byId.get();
        } catch (IllegalArgumentException ignored) {}

        java.util.Optional<LoanContract> byContractNo = loanContractRepository.findByContractNumber(loanIdOrContractNumber.trim());
        if (byContractNo.isPresent()) {
            LoanContract c = byContractNo.get();
            if (userId == null || userId.equals(c.getUserId())) {
                return c;
            }
        }
        throw new IllegalArgumentException("Không tìm thấy hợp đồng vay: " + loanIdOrContractNumber);
    }

    @Transactional
    public CicDebtReportResponse classifyCicDebtGroups() {
        List<LoanContract> contracts = loanContractRepository.findAll();
        LocalDate today = LocalDate.now();

        long g1Count = 0, g2Count = 0, g3Count = 0, g4Count = 0, g5Count = 0;
        BigDecimal g1Amount = BigDecimal.ZERO, g2Amount = BigDecimal.ZERO;
        BigDecimal g3Amount = BigDecimal.ZERO, g4Amount = BigDecimal.ZERO, g5Amount = BigDecimal.ZERO;
        BigDecimal totalPrincipal = BigDecimal.ZERO;
        BigDecimal totalProvision = BigDecimal.ZERO;

        List<LoanApplicationResponse> responses = new ArrayList<>();

        for (LoanContract c : contracts) {
            if ("SETTLED".equalsIgnoreCase(c.getStatus()) || "REJECTED".equalsIgnoreCase(c.getStatus())) {
                continue;
            }

            BigDecimal remaining = c.getRemainingPrincipal() != null ? c.getRemainingPrincipal() : BigDecimal.ZERO;
            totalPrincipal = totalPrincipal.add(remaining);

            List<LoanScheduleItem> schedules = loanScheduleItemRepository.findByLoanContractIdOrderByTermNumberAsc(c.getId());
            int overdueDays = 0;
            for (LoanScheduleItem item : schedules) {
                if (!"PAID".equalsIgnoreCase(item.getStatus()) && item.getDueDate() != null && item.getDueDate().isBefore(today)) {
                    int days = (int) ChronoUnit.DAYS.between(item.getDueDate(), today);
                    if (days > overdueDays) {
                        overdueDays = days;
                    }
                }
            }

            int group;
            String groupName;
            BigDecimal rate;

            if (overdueDays <= 10) {
                group = 1;
                groupName = "Nhóm 1 - Nợ đủ tiêu chuẩn";
                rate = BigDecimal.ZERO;
                g1Count++;
                g1Amount = g1Amount.add(remaining);
            } else if (overdueDays <= 90) {
                group = 2;
                groupName = "Nhóm 2 - Nợ cần chú ý";
                rate = new BigDecimal("0.05");
                g2Count++;
                g2Amount = g2Amount.add(remaining);
            } else if (overdueDays <= 180) {
                group = 3;
                groupName = "Nhóm 3 - Nợ dưới tiêu chuẩn";
                rate = new BigDecimal("0.20");
                g3Count++;
                g3Amount = g3Amount.add(remaining);
            } else if (overdueDays <= 360) {
                group = 4;
                groupName = "Nhóm 4 - Nợ nghi ngờ";
                rate = new BigDecimal("0.50");
                g4Count++;
                g4Amount = g4Amount.add(remaining);
            } else {
                group = 5;
                groupName = "Nhóm 5 - Nợ có khả năng mất vốn";
                rate = new BigDecimal("1.00");
                g5Count++;
                g5Amount = g5Amount.add(remaining);
            }

            BigDecimal provision = remaining.multiply(rate).setScale(2, RoundingMode.HALF_UP);
            totalProvision = totalProvision.add(provision);

            c.setCicGroup(group);
            c.setCicGroupName(groupName);
            c.setOverdueDays(overdueDays);
            c.setRiskProvisionAmount(provision);
            loanContractRepository.save(c);

            responses.add(toResponse(c));
        }

        return CicDebtReportResponse.builder()
                .totalLoans(responses.size())
                .totalPrincipalOutstanding(totalPrincipal)
                .totalRiskProvision(totalProvision)
                .group1Count(g1Count)
                .group1Amount(g1Amount)
                .group2Count(g2Count)
                .group2Amount(g2Amount)
                .group3Count(g3Count)
                .group3Amount(g3Amount)
                .group4Count(g4Count)
                .group4Amount(g4Amount)
                .group5Count(g5Count)
                .group5Amount(g5Amount)
                .contracts(responses)
                .build();
    }

    private LoanApplicationResponse toResponse(LoanContract c) {
        return LoanApplicationResponse.builder()
                .id(c.getId() != null ? c.getId().toString() : null)
                .contractNumber(c.getContractNumber())
                .userId(c.getUserId())
                .walletId(c.getWalletId())
                .productType(c.getProductType())
                .productName(c.getProductName())
                .principalAmount(c.getPrincipalAmount())
                .annualInterestRate(c.getAnnualInterestRate())
                .termMonths(c.getTermMonths() != null ? c.getTermMonths() : 0)
                .totalInterest(c.getTotalInterest())
                .totalRepayment(c.getTotalRepayment())
                .monthlyPayment(c.getMonthlyPayment())
                .status(c.getStatus())
                .disbursedAt(c.getDisbursedAt() != null ? c.getDisbursedAt().toString() : null)
                .firstDueDate(c.getFirstDueDate() != null ? c.getFirstDueDate().toString() : null)
                .approvedBy(c.getApprovedBy())
                .approvedAt(c.getApprovedAt() != null ? c.getApprovedAt().toString() : null)
                .rejectReason(c.getRejectReason())
                .cicGroup(c.getCicGroup() != null ? c.getCicGroup() : 1)
                .cicGroupName(c.getCicGroupName() != null ? c.getCicGroupName() : "Nhóm 1 - Nợ đủ tiêu chuẩn")
                .overdueDays(c.getOverdueDays() != null ? c.getOverdueDays() : 0)
                .riskProvisionAmount(c.getRiskProvisionAmount() != null ? c.getRiskProvisionAmount() : BigDecimal.ZERO)
                .build();
    }
}

