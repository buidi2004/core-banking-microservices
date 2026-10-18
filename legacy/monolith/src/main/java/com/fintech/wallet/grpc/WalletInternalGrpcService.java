package com.fintech.wallet.grpc;

import com.fintech.wallet.application.service.WalletInternalApplicationService;
import io.grpc.stub.StreamObserver;
import net.devh.boot.grpc.server.service.GrpcService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * gRPC Server Implementation cho WalletInternalService.
 * Được gọi bởi Payment Service qua giao thức nhị phân (độ trễ < 2ms).
 * Mỗi RPC method sử dụng pessimistic lock (SELECT FOR UPDATE) từ WalletInternalApplicationService.
 */
@GrpcService
public class WalletInternalGrpcService extends WalletInternalServiceGrpc.WalletInternalServiceImplBase {

    private static final Logger log = LoggerFactory.getLogger(WalletInternalGrpcService.class);

    private final WalletInternalApplicationService applicationService;

    public WalletInternalGrpcService(WalletInternalApplicationService applicationService) {
        this.applicationService = applicationService;
    }

    // ======================== DEBIT WALLET ========================

    @Override
    public void debitWallet(DebitRequest request, StreamObserver<DebitResponse> responseObserver) {
        log.debug("gRPC DebitWallet: walletId={}, amount={}, txId={}",
                request.getWalletId(), request.getAmount(), request.getTransactionId());

        WalletInternalApplicationService.DebitResult result = applicationService.debitWallet(
                request.getWalletId(),
                request.getAmount(),
                request.getTransactionId(),
                request.getIdempotencyKey()
        );

        DebitResponse.Builder builder = DebitResponse.newBuilder()
                .setSuccess(result.success());

        if (result.success() && result.balanceAfter() != null) {
            builder.setBalanceAfter(result.balanceAfter());
        }

        if (!result.success()) {
            builder.setErrorCode(result.errorCode());
            if (result.errorMessage() != null) {
                builder.setErrorMessage(result.errorMessage());
            }
        }

        responseObserver.onNext(builder.build());
        responseObserver.onCompleted();
    }

    // ======================== CREDIT WALLET ========================

    @Override
    public void creditWallet(CreditRequest request, StreamObserver<CreditResponse> responseObserver) {
        log.debug("gRPC CreditWallet: walletId={}, amount={}, txId={}",
                request.getWalletId(), request.getAmount(), request.getTransactionId());

        WalletInternalApplicationService.CreditResult result = applicationService.creditWallet(
                request.getWalletId(),
                request.getAmount(),
                request.getTransactionId(),
                request.getIdempotencyKey()
        );

        CreditResponse.Builder builder = CreditResponse.newBuilder()
                .setSuccess(result.success());

        if (result.success() && result.balanceAfter() != null) {
            builder.setBalanceAfter(result.balanceAfter());
        }

        if (!result.success()) {
            builder.setErrorCode(result.errorCode());
            if (result.errorMessage() != null) {
                builder.setErrorMessage(result.errorMessage());
            }
        }

        responseObserver.onNext(builder.build());
        responseObserver.onCompleted();
    }

    // ======================== RESERVE BALANCE ========================

    @Override
    public void reserveBalance(ReserveRequest request, StreamObserver<ReserveResponse> responseObserver) {
        log.debug("gRPC ReserveBalance: walletId={}, amount={}, txId={}",
                request.getWalletId(), request.getAmount(), request.getTransactionId());

        WalletInternalApplicationService.ReserveResult result = applicationService.reserveBalance(
                request.getWalletId(),
                request.getAmount(),
                request.getTransactionId(),
                request.getReserveDurationSeconds()
        );

        ReserveResponse.Builder builder = ReserveResponse.newBuilder()
                .setSuccess(result.success());

        if (result.success()) {
            if (result.reservedAmount() != null) {
                builder.setReservedAmount(result.reservedAmount());
            }
            if (result.reservationId() != null) {
                builder.setReservationId(result.reservationId());
            }
        }

        if (!result.success()) {
            builder.setErrorCode(result.errorCode());
            if (result.errorMessage() != null) {
                builder.setErrorMessage(result.errorMessage());
            }
        }

        responseObserver.onNext(builder.build());
        responseObserver.onCompleted();
    }

    // ======================== RELEASE BALANCE ========================

    @Override
    public void releaseBalance(ReleaseRequest request, StreamObserver<ReleaseResponse> responseObserver) {
        log.debug("gRPC ReleaseBalance: reservationId={}, txId={}",
                request.getReservationId(), request.getTransactionId());

        WalletInternalApplicationService.ReleaseResult result = applicationService.releaseBalance(
                request.getReservationId(),
                request.getTransactionId()
        );

        ReleaseResponse.Builder builder = ReleaseResponse.newBuilder()
                .setSuccess(result.success());

        if (!result.success()) {
            builder.setErrorCode(result.errorCode());
            if (result.errorMessage() != null) {
                builder.setErrorMessage(result.errorMessage());
            }
        }

        responseObserver.onNext(builder.build());
        responseObserver.onCompleted();
    }

    // ======================== CHECK LIMIT ========================

    @Override
    public void checkLimit(LimitCheckRequest request, StreamObserver<LimitCheckResponse> responseObserver) {
        log.debug("gRPC CheckLimit: walletId={}, amount={}, type={}",
                request.getWalletId(), request.getAmount(), request.getTransactionType());

        WalletInternalApplicationService.LimitCheckResult result = applicationService.checkLimit(
                request.getWalletId(),
                request.getAmount(),
                request.getTransactionType(),
                request.getUserId()
        );

        LimitCheckResponse.Builder builder = LimitCheckResponse.newBuilder()
                .setAllowed(result.allowed());

        if (result.availableBalance() != null) {
            builder.setAvailableBalance(result.availableBalance());
        }
        if (result.dailyLimitRemaining() != null) {
            builder.setDailyLimitRemaining(result.dailyLimitRemaining());
        }
        if (result.transactionLimitRemaining() != null) {
            builder.setTransactionLimitRemaining(result.transactionLimitRemaining());
        }

        if (!result.allowed()) {
            builder.setErrorCode(result.errorCode());
            if (result.errorMessage() != null) {
                builder.setErrorMessage(result.errorMessage());
            }
        }

        responseObserver.onNext(builder.build());
        responseObserver.onCompleted();
    }

    // ======================== GET WALLET BY USER ID ========================

    @Override
    public void getWalletByUserId(UserWalletRequest request, StreamObserver<WalletResponse> responseObserver) {
        log.debug("gRPC GetWalletByUserId: userId={}", request.getUserId());

        WalletInternalApplicationService.GetWalletResult result = applicationService.getWalletByUserId(
                request.getUserId()
        );

        WalletResponse.Builder builder = WalletResponse.newBuilder()
                .setFound(result.found())
                .setUserId(result.userId());

        if (result.found()) {
            builder.setWalletId(result.walletId());
            if (result.balance() != null) {
                builder.setBalance(result.balance());
            }
            if (result.currency() != null) {
                builder.setCurrency(result.currency());
            }
            if (result.status() != null) {
                builder.setStatus(result.status());
            }
        } else {
            builder.setErrorCode(result.errorCode());
            if (result.errorMessage() != null) {
                builder.setErrorMessage(result.errorMessage());
            }
        }

        responseObserver.onNext(builder.build());
        responseObserver.onCompleted();
    }
}
