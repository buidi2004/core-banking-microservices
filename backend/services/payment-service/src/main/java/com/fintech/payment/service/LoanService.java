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
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class LoanService {

    private final LoanContractRepository loanContractRepository;
    private final LoanScheduleItemRepository loanScheduleItemRepository;
    private final WalletGrpcClient walletGrpcClient;
    private final PinTokenValidator pinTokenValidator;

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
        if (request.getPinToken() != null && !request.getPinToken().isBlank()) {
            pinTokenValidator.validate(userId, request.getPinToken());
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

        // Core banking in-house auto-disbursement: credit to user wallet immediately
        var creditRes = walletGrpcClient.credit(
                request.getWalletId(),
                request.getAmount().longValue(),
                "LOAN_DISBURSEMENT",
                "Giải ngân khoản vay " + contractNumber
        );
        if (creditRes != null && !creditRes.isSuccess()) {
            throw new IllegalStateException("Giải ngân vào ví thất bại: " + creditRes.getErrorMessage());
        }

        LoanContract contract = LoanContract.builder()
                .userId(userId)
                .walletId(request.getWalletId())
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
                .status("DISBURSED")
                .disbursedAt(Instant.now())
                .firstDueDate(firstDueDate)
                .build();

        LoanContract savedContract = loanContractRepository.save(contract);

        for (LoanScheduleItem item : scheduleItems) {
            item.setLoanContractId(savedContract.getId());
        }
        loanScheduleItemRepository.saveAll(scheduleItems);

        log.info("Disbursed loan {} of {} VND to wallet {} for user {}",
                contractNumber, request.getAmount(), request.getWalletId(), userId);

        return toResponse(savedContract);
    }

    public List<LoanApplicationResponse> getUserLoans(String userId) {
        return loanContractRepository.findByUserIdOrderByCreatedAtDesc(userId).stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    public LoanApplicationResponse getLoanDetail(String loanId, String userId) {
        UUID uuid = UUID.fromString(loanId);
        LoanContract contract = loanContractRepository.findByIdAndUserId(uuid, userId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy hợp đồng vay"));
        return toResponse(contract);
    }

    public LoanScheduleResponse getLoanSchedule(String loanId, String userId) {
        UUID uuid = UUID.fromString(loanId);
        LoanContract contract = loanContractRepository.findByIdAndUserId(uuid, userId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy hợp đồng vay"));

        List<LoanScheduleItem> items = loanScheduleItemRepository.findByLoanContractIdOrderByTermNumberAsc(uuid);

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

        UUID uuid = UUID.fromString(loanId);
        LoanContract contract = loanContractRepository.findByIdAndUserId(uuid, userId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy hợp đồng vay"));

        LoanScheduleItem item = loanScheduleItemRepository.findByLoanContractIdAndTermNumber(uuid, request.getTermNumber())
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy kỳ hạn thanh toán " + request.getTermNumber()));

        if ("PAID".equals(item.getStatus())) {
            throw new IllegalStateException("Kỳ hạn số " + request.getTermNumber() + " đã được thanh toán trước đó");
        }

        BigDecimal payAmount = request.getAmount() != null ? request.getAmount() : item.getTotalAmount();

        // Debit repayment from user wallet
        var debitRes = walletGrpcClient.debit(
                contract.getWalletId(),
                payAmount.longValue(),
                "LOAN_REPAYMENT",
                "Thanh toán kỳ " + request.getTermNumber() + " hợp đồng " + contract.getContractNumber()
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
        List<LoanScheduleItem> allTerms = loanScheduleItemRepository.findByLoanContractIdOrderByTermNumberAsc(uuid);
        boolean allPaid = allTerms.stream().allMatch(t -> "PAID".equals(t.getStatus()));
        if (allPaid) {
            contract.setStatus("SETTLED");
        }
        loanContractRepository.save(contract);

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
                .termMonths(c.getTermMonths())
                .totalInterest(c.getTotalInterest())
                .totalRepayment(c.getTotalRepayment())
                .monthlyPayment(c.getMonthlyPayment())
                .status(c.getStatus())
                .disbursedAt(c.getDisbursedAt() != null ? c.getDisbursedAt().toString() : null)
                .firstDueDate(c.getFirstDueDate() != null ? c.getFirstDueDate().toString() : null)
                .build();
    }
}

