package com.fintech.wallet.presentation.controller;

import com.fintech.wallet.domain.model.FeeEstimate;
import com.fintech.wallet.domain.model.Money;
import com.fintech.wallet.domain.model.Transaction;
import com.fintech.wallet.domain.model.TransactionType;
import com.fintech.wallet.domain.model.Wallet;
import com.fintech.wallet.domain.port.in.DepositMoneyUseCase;
import com.fintech.wallet.domain.port.in.FeeEstimationUseCase;
import com.fintech.wallet.domain.port.in.GetWalletUseCase;
import com.fintech.wallet.domain.port.in.TransferMoneyUseCase;
import com.fintech.wallet.domain.port.in.TransactionQueryUseCase;
import com.fintech.wallet.domain.port.in.TransactionReversalUseCase;
import com.fintech.wallet.domain.exception.InvalidPinException;
import com.fintech.wallet.domain.port.in.PinUseCase;
import com.fintech.wallet.domain.port.in.WithdrawMoneyUseCase;
import com.fintech.wallet.application.service.OtpService;
import com.fintech.wallet.application.service.UserService;
import com.fintech.wallet.domain.port.in.VietQrUseCase;
import com.fintech.wallet.domain.model.VietQrPayload;
import com.fintech.wallet.presentation.request.TransferQrRequest;
import com.fintech.wallet.presentation.request.CreateWalletRequest;
import com.fintech.wallet.presentation.request.DepositRequest;
import com.fintech.wallet.presentation.request.TransferRequest;
import com.fintech.wallet.presentation.request.WithdrawRequest;
import com.fintech.wallet.presentation.response.ApiResponse;
import com.fintech.wallet.presentation.response.FeeEstimateResponse;
import com.fintech.wallet.presentation.response.RecipientInfoResponse;
import com.fintech.wallet.presentation.response.TransferResponse;
import com.fintech.wallet.presentation.response.WalletResponse;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.math.BigDecimal;

/**
 * Controller REST API: WalletController
 * Handles requests from frontend clients (e.g. React Native).
 * Interacts only with Input Ports (GetWalletUseCase, DepositMoneyUseCase, TransferMoneyUseCase, WithdrawMoneyUseCase).
 */
@RestController
@RequestMapping("/api/v1/wallets")
public class WalletController {

    private final GetWalletUseCase getWalletUseCase;
    private final DepositMoneyUseCase depositMoneyUseCase;
    private final TransferMoneyUseCase transferMoneyUseCase;
    private final WithdrawMoneyUseCase withdrawMoneyUseCase;
    private final PinUseCase pinUseCase;
    private final FeeEstimationUseCase feeEstimationUseCase;
    private final TransactionReversalUseCase transactionReversalUseCase;
    private final OtpService otpService;
    private final UserService userService;
    private final VietQrUseCase vietQrUseCase;
    private final TransactionQueryUseCase transactionQueryUseCase;

    public WalletController(GetWalletUseCase getWalletUseCase,
                            DepositMoneyUseCase depositMoneyUseCase,
                            TransferMoneyUseCase transferMoneyUseCase,
                            WithdrawMoneyUseCase withdrawMoneyUseCase,
                            PinUseCase pinUseCase,
                            FeeEstimationUseCase feeEstimationUseCase,
                            TransactionReversalUseCase transactionReversalUseCase,
                            OtpService otpService,
                            UserService userService,
                            VietQrUseCase vietQrUseCase,
                            TransactionQueryUseCase transactionQueryUseCase) {
        this.getWalletUseCase = getWalletUseCase;
        this.depositMoneyUseCase = depositMoneyUseCase;
        this.transferMoneyUseCase = transferMoneyUseCase;
        this.withdrawMoneyUseCase = withdrawMoneyUseCase;
        this.pinUseCase = pinUseCase;
        this.feeEstimationUseCase = feeEstimationUseCase;
        this.transactionReversalUseCase = transactionReversalUseCase;
        this.otpService = otpService;
        this.userService = userService;
        this.vietQrUseCase = vietQrUseCase;
        this.transactionQueryUseCase = transactionQueryUseCase;
    }

    @PostMapping
    public ResponseEntity<ApiResponse<WalletResponse>> createWallet(@Valid @RequestBody CreateWalletRequest request) {
        Wallet wallet = getWalletUseCase.createWallet(request.getOwnerId(), request.getCurrency());
        WalletResponse response = WalletResponse.fromDomain(wallet);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Wallet created successfully", response));
    }

    @GetMapping("/{walletId}")
    public ResponseEntity<ApiResponse<WalletResponse>> getWallet(Authentication auth, @PathVariable String walletId) {
        String userId = auth.getName();
        Wallet wallet = getWalletUseCase.getWalletById(walletId);
        // SEC-1 fix: ownership check — only owner can view their wallet
        if (!wallet.getOwnerId().equals(userId)) {
            throw new org.springframework.security.access.AccessDeniedException("Not authorized to access this wallet");
        }
        WalletResponse response = WalletResponse.fromDomain(wallet);
        return ResponseEntity.ok(ApiResponse.success("Wallet retrieved successfully", response));
    }

    @GetMapping("/recipient-info")
    public ResponseEntity<ApiResponse<RecipientInfoResponse>> getRecipientInfo(
            @RequestParam(required = false) String walletId,
            @RequestParam(required = false) String phoneNumber) {
        RecipientInfoResponse response = getWalletUseCase.getRecipientInfo(walletId, phoneNumber);
        return ResponseEntity.ok(ApiResponse.success("Recipient information retrieved successfully", response));
    }

    @PostMapping("/deposit")
    public ResponseEntity<ApiResponse<TransferResponse>> deposit(Authentication auth, @Valid @RequestBody DepositRequest request) {
        String userId = auth.getName();
        // BUG-6 fix: verify user owns the target wallet
        Wallet wallet = getWalletUseCase.getWalletById(request.getWalletId());
        if (!wallet.getOwnerId().equals(userId)) {
            throw new org.springframework.security.access.AccessDeniedException("Not authorized to deposit into this wallet");
        }
        Money money = Money.of(request.getAmount(), request.getCurrency());
        Transaction transaction = depositMoneyUseCase.deposit(request.getRequestId(), request.getWalletId(), money);
        TransferResponse response = TransferResponse.fromDomain(transaction);
        return ResponseEntity.ok(ApiResponse.success("Deposit successful", response));
    }

    @PostMapping("/transfer/init")
    public ResponseEntity<ApiResponse<TransferResponse>> initTransfer(Authentication auth, @Valid @RequestBody TransferRequest request) {
        String userId = auth.getName();
        // BUG-5 fix: verify user owns the source wallet before initiating transfer
        Wallet sourceWallet = getWalletUseCase.getWalletById(request.getSourceWalletId());
        if (!sourceWallet.getOwnerId().equals(userId)) {
            throw new org.springframework.security.access.AccessDeniedException("Not authorized to transfer from this wallet");
        }
        Money money = Money.of(request.getAmount(), request.getCurrency());
        Transaction transaction = transferMoneyUseCase.initTransfer(request.getRequestId(), request.getSourceWalletId(), request.getTargetWalletId(), money, request.getNote());
        
        // Generate OTP
        otpService.generateAndStoreOtp(transaction.getId());
        
        TransferResponse response = TransferResponse.fromDomain(transaction);
        return ResponseEntity.ok(ApiResponse.success("Transfer initiated. Please confirm with OTP/PIN.", response));
    }

    @PostMapping("/transfer/qr/init")
    public ResponseEntity<ApiResponse<TransferResponse>> initTransferQr(Authentication auth, @Valid @RequestBody TransferQrRequest request) {
        String userId = auth.getName();
        // BUG-5 fix: verify user owns the source wallet
        Wallet sourceWallet = getWalletUseCase.getWalletById(request.getSourceWalletId());
        if (!sourceWallet.getOwnerId().equals(userId)) {
            throw new org.springframework.security.access.AccessDeniedException("Not authorized to transfer from this wallet");
        }
        VietQrPayload payload = vietQrUseCase.decodeQr(request.getQrCode());
        
        BigDecimal finalAmount = request.getAmount();
        if (finalAmount == null && payload.getAmount() != null && payload.getAmount().compareTo(BigDecimal.ZERO) > 0) {
            finalAmount = payload.getAmount();
        }
        if (finalAmount == null || finalAmount.compareTo(BigDecimal.ZERO) <= 0) {
            throw new IllegalArgumentException("Amount must be specified either in QR or request payload");
        }

        Money money = Money.of(finalAmount, request.getCurrency());
        
        // Resolve account number (phone) to target wallet ID
        String phoneNumber = payload.getAccountNumber();
        RecipientInfoResponse recipientInfo = getWalletUseCase.getRecipientInfo(null, phoneNumber);
        String targetWalletId = recipientInfo.getWalletId();
        
        String note = payload.getPurpose() != null ? payload.getPurpose() : "VietQR Transfer";
        Transaction transaction = transferMoneyUseCase.initTransfer(request.getRequestId(), request.getSourceWalletId(), targetWalletId, money, note);
        
        // Generate OTP
        otpService.generateAndStoreOtp(transaction.getId());
        
        TransferResponse response = TransferResponse.fromDomain(transaction);
        return ResponseEntity.ok(ApiResponse.success("QR Transfer initiated. Please confirm with OTP/PIN.", response));
    }

    @PostMapping("/transfer/{transactionId}/confirm")
    public ResponseEntity<ApiResponse<TransferResponse>> confirmTransfer(
            Authentication auth,
            @PathVariable String transactionId,
            @RequestParam(required = false) String otp,
            @RequestParam(required = false) String pin) {
        String userId = auth.getName();
        
        // BUG-4 fix: verify user owns the source wallet of the pending transaction (IDOR prevention)
        Transaction pending = transactionQueryUseCase.getTransactionById(transactionId);
        Wallet sourceWallet = getWalletUseCase.getWalletById(pending.getSourceWalletId());
        if (!sourceWallet.getOwnerId().equals(userId)) {
            throw new org.springframework.security.access.AccessDeniedException("Not authorized to confirm this transfer");
        }
        
        otpService.verifyOtpOrPin(userId, transactionId, otp, pin, userService::verifyPin);
        
        Transaction transaction = transferMoneyUseCase.confirmTransfer(transactionId);
        TransferResponse response = TransferResponse.fromDomain(transaction);
        return ResponseEntity.ok(ApiResponse.success("Transfer successful", response));
    }

    @PostMapping("/withdraw")
    public ResponseEntity<ApiResponse<TransferResponse>> withdraw(Authentication auth, @Valid @RequestBody WithdrawRequest request) {
        String userId = auth.getName();
        if (!pinUseCase.validatePinToken(userId, request.getPinToken())) {
            throw new InvalidPinException("Invalid or expired transaction PIN verification token");
        }
        Money money = Money.of(request.getAmount(), request.getCurrency());
        Transaction transaction = withdrawMoneyUseCase.withdraw(
                request.getRequestId(),
                userId,
                request.getWalletId(),
                request.getBankAccountId(),
                money
        );
        TransferResponse response = TransferResponse.fromDomain(transaction);
        return ResponseEntity.ok(ApiResponse.success("Withdrawal successful", response));
    }

    // ─── Fee Estimation ──────────────────────────────────────────────────────

    /**
     * Estimate transaction fee before the user confirms.
     * GET /api/v1/wallets/fees/estimate?type=WITHDRAWAL&amount=500000&currency=VND
     */
    @GetMapping("/fees/estimate")
    public ResponseEntity<ApiResponse<FeeEstimateResponse>> estimateFee(
            Authentication auth,
            @RequestParam TransactionType type,
            @RequestParam BigDecimal amount,
            @RequestParam(defaultValue = "VND") String currency) {
        String userId = auth.getName();
        Money money = Money.of(amount, currency);
        FeeEstimate estimate = feeEstimationUseCase.estimateFee(userId, type, money);
        FeeEstimateResponse response = FeeEstimateResponse.fromDomain(estimate);
        return ResponseEntity.ok(ApiResponse.success("Fee estimated successfully", response));
    }

    // ─── Transaction Reversal ────────────────────────────────────────────────

    /**
     * Reverse a completed transaction (manual reversal by support/admin).
     * POST /api/v1/wallets/transactions/{transactionId}/reverse
     */
    @PostMapping("/transactions/{transactionId}/reverse")
    public ResponseEntity<ApiResponse<TransferResponse>> reverseTransaction(
            @PathVariable String transactionId,
            @RequestParam(required = false, defaultValue = "Manual reversal") String reason) {
        Transaction reversalTx = transactionReversalUseCase.reverseTransaction(transactionId, reason);
        TransferResponse response = TransferResponse.fromDomain(reversalTx);
        return ResponseEntity.ok(ApiResponse.success("Transaction reversed successfully", response));
    }
}

