package com.fintech.payment.grpc;

import com.fintech.payment.grpc.dto.WalletBalanceResult;
import com.fintech.payment.grpc.dto.WalletInfoResult;
import com.fintech.payment.grpc.dto.WalletLimitResult;
import com.fintech.payment.grpc.dto.WalletReservationResult;
import com.fintech.wallet.grpc.*;
import io.grpc.StatusRuntimeException;
import net.devh.boot.grpc.client.inject.GrpcClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * gRPC Client gọi sang Wallet Service (wallet-service:9090) qua hợp đồng WalletInternalService.
 * Mỗi method bọc lỗi gRPC thành Wallet*Result để Payment Service xử lý Sagaorchestrator.
 */
@Component
public class WalletGrpcClient {

    private static final Logger log = LoggerFactory.getLogger(WalletGrpcClient.class);

    @GrpcClient("wallet-service")
    private WalletInternalServiceGrpc.WalletInternalServiceBlockingStub walletStub;

    // ======================== DEBIT ========================

    public WalletBalanceResult debit(String walletId, Long amount, String transactionId, String idempotencyKey) {
        try {
            DebitRequest request = DebitRequest.newBuilder()
                    .setWalletId(walletId)
                    .setAmount(amount)
                    .setTransactionId(transactionId)
                    .setIdempotencyKey(idempotencyKey)
                    .build();
            DebitResponse response = walletStub.debitWallet(request);
            return WalletBalanceResult.builder()
                    .success(response.getSuccess())
                    .balanceAfter(response.getBalanceAfter())
                    .errorCode(response.getErrorCode())
                    .errorMessage(response.getErrorMessage())
                    .build();
        } catch (StatusRuntimeException e) {
            log.error("gRPC DebitWallet failed walletId={} txId={}: {}", walletId, transactionId, e.getStatus().getDescription());
            return WalletBalanceResult.builder()
                    .success(false)
                    .errorCode("GRPC_DEBIT_ERROR")
                    .errorMessage(e.getStatus().getDescription())
                    .build();
        }
    }

    // ======================== CREDIT ========================

    public WalletBalanceResult credit(String walletId, Long amount, String transactionId, String idempotencyKey) {
        try {
            CreditRequest request = CreditRequest.newBuilder()
                    .setWalletId(walletId)
                    .setAmount(amount)
                    .setTransactionId(transactionId)
                    .setIdempotencyKey(idempotencyKey)
                    .build();
            CreditResponse response = walletStub.creditWallet(request);
            return WalletBalanceResult.builder()
                    .success(response.getSuccess())
                    .balanceAfter(response.getBalanceAfter())
                    .errorCode(response.getErrorCode())
                    .errorMessage(response.getErrorMessage())
                    .build();
        } catch (StatusRuntimeException e) {
            log.error("gRPC CreditWallet failed walletId={} txId={}: {}", walletId, transactionId, e.getStatus().getDescription());
            return WalletBalanceResult.builder()
                    .success(false)
                    .errorCode("GRPC_CREDIT_ERROR")
                    .errorMessage(e.getStatus().getDescription())
                    .build();
        }
    }

    // ======================== RESERVE ========================

    public WalletReservationResult reserve(String walletId, Long amount, String transactionId, int reserveDurationSeconds) {
        try {
            ReserveRequest request = ReserveRequest.newBuilder()
                    .setWalletId(walletId)
                    .setAmount(amount)
                    .setTransactionId(transactionId)
                    .setReserveDurationSeconds(reserveDurationSeconds)
                    .build();
            ReserveResponse response = walletStub.reserveBalance(request);
            return WalletReservationResult.builder()
                    .success(response.getSuccess())
                    .reservedAmount(response.getReservedAmount())
                    .reservationId(response.getReservationId())
                    .errorCode(response.getErrorCode())
                    .errorMessage(response.getErrorMessage())
                    .build();
        } catch (StatusRuntimeException e) {
            log.error("gRPC ReserveBalance failed walletId={} txId={}: {}", walletId, transactionId, e.getStatus().getDescription());
            return WalletReservationResult.builder()
                    .success(false)
                    .errorCode("GRPC_RESERVE_ERROR")
                    .errorMessage(e.getStatus().getDescription())
                    .build();
        }
    }

    // ======================== RELEASE ========================

    public WalletReservationResult release(String reservationId, String transactionId) {
        try {
            ReleaseRequest request = ReleaseRequest.newBuilder()
                    .setReservationId(reservationId)
                    .setTransactionId(transactionId)
                    .build();
            ReleaseResponse response = walletStub.releaseBalance(request);
            return WalletReservationResult.builder()
                    .success(response.getSuccess())
                    .reservationId(reservationId)
                    .errorCode(response.getErrorCode())
                    .errorMessage(response.getErrorMessage())
                    .build();
        } catch (StatusRuntimeException e) {
            log.error("gRPC ReleaseBalance failed reservationId={} txId={}: {}", reservationId, transactionId, e.getStatus().getDescription());
            return WalletReservationResult.builder()
                    .success(false)
                    .errorCode("GRPC_RELEASE_ERROR")
                    .errorMessage(e.getStatus().getDescription())
                    .build();
        }
    }

    // ======================== CHECK LIMIT ========================

    public WalletLimitResult checkLimit(String walletId, Long amount, String transactionType, String userId) {
        try {
            LimitCheckRequest request = LimitCheckRequest.newBuilder()
                    .setWalletId(walletId)
                    .setAmount(amount)
                    .setTransactionType(transactionType)
                    .setUserId(userId)
                    .build();
            LimitCheckResponse response = walletStub.checkLimit(request);
            return WalletLimitResult.builder()
                    .allowed(response.getAllowed())
                    .availableBalance(response.getAvailableBalance())
                    .dailyLimitRemaining(response.getDailyLimitRemaining())
                    .transactionLimitRemaining(response.getTransactionLimitRemaining())
                    .errorCode(response.getErrorCode())
                    .errorMessage(response.getErrorMessage())
                    .build();
        } catch (StatusRuntimeException e) {
            log.error("gRPC CheckLimit failed walletId={}: {}", walletId, e.getStatus().getDescription());
            return WalletLimitResult.builder()
                    .allowed(false)
                    .errorCode("GRPC_LIMIT_ERROR")
                    .errorMessage(e.getStatus().getDescription())
                    .build();
        }
    }

    // ======================== GET WALLET BY USER ID ========================

    public WalletInfoResult getWalletByUserId(String userId) {
        try {
            UserWalletRequest request = UserWalletRequest.newBuilder().setUserId(userId).build();
            WalletResponse response = walletStub.getWalletByUserId(request);
            return WalletInfoResult.builder()
                    .found(response.getFound())
                    .walletId(response.getWalletId())
                    .userId(response.getUserId())
                    .balance(response.getBalance())
                    .currency(response.getCurrency())
                    .status(response.getStatus())
                    .errorCode(response.getErrorCode())
                    .errorMessage(response.getErrorMessage())
                    .build();
        } catch (StatusRuntimeException e) {
            log.error("gRPC GetWalletByUserId failed userId={}: {}", userId, e.getStatus().getDescription());
            return WalletInfoResult.builder()
                    .found(false)
                    .errorCode("GRPC_GET_WALLET_ERROR")
                    .errorMessage(e.getStatus().getDescription())
                    .build();
        }
    }
}
