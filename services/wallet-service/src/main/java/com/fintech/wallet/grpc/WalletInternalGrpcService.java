package com.fintech.wallet.grpc;

import com.fintech.wallet.service.WalletGrpcService;
import io.grpc.stub.StreamObserver;
import net.devh.boot.grpc.server.service.GrpcService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * gRPC Server Implementation cho WalletInternalService.
 * Được gọi bởi Payment Service qua giao thức nhị phân (độ trễ < 2ms) tại cổng 9090.
 * Mỗi RPC method sử dụng pessimistic lock (SELECT FOR UPDATE) từ WalletGrpcService.
 */
@GrpcService
public class WalletInternalGrpcService extends WalletInternalServiceGrpc.WalletInternalServiceImplBase {

    private static final Logger log = LoggerFactory.getLogger(WalletInternalGrpcService.class);

    private final WalletGrpcService walletGrpcService;

    public WalletInternalGrpcService(WalletGrpcService walletGrpcService) {
        this.walletGrpcService = walletGrpcService;
    }

    @Override
    public void debitWallet(com.fintech.wallet.grpc.DebitRequest request,
                            StreamObserver<com.fintech.wallet.grpc.DebitResponse> responseObserver) {
        log.debug("gRPC DebitWallet: walletId={}, amount={}, txId={}",
                request.getWalletId(), request.getAmount(), request.getTransactionId());

        WalletGrpcService.DebitResult result = walletGrpcService.debitWallet(
                request.getWalletId(), request.getAmount(),
                request.getTransactionId(), request.getIdempotencyKey());

        com.fintech.wallet.grpc.DebitResponse.Builder builder = com.fintech.wallet.grpc.DebitResponse.newBuilder()
                .setSuccess(result.success);
        if (result.balanceAfter != null) builder.setBalanceAfter(result.balanceAfter);
        if (result.errorCode != null) builder.setErrorCode(result.errorCode);
        if (result.errorMessage != null) builder.setErrorMessage(result.errorMessage);

        responseObserver.onNext(builder.build());
        responseObserver.onCompleted();
    }

    @Override
    public void creditWallet(com.fintech.wallet.grpc.CreditRequest request,
                             StreamObserver<com.fintech.wallet.grpc.CreditResponse> responseObserver) {
        log.debug("gRPC CreditWallet: walletId={}, amount={}, txId={}",
                request.getWalletId(), request.getAmount(), request.getTransactionId());

        WalletGrpcService.CreditResult result = walletGrpcService.creditWallet(
                request.getWalletId(), request.getAmount(),
                request.getTransactionId(), request.getIdempotencyKey());

        com.fintech.wallet.grpc.CreditResponse.Builder builder = com.fintech.wallet.grpc.CreditResponse.newBuilder()
                .setSuccess(result.success);
        if (result.balanceAfter != null) builder.setBalanceAfter(result.balanceAfter);
        if (result.errorCode != null) builder.setErrorCode(result.errorCode);
        if (result.errorMessage != null) builder.setErrorMessage(result.errorMessage);

        responseObserver.onNext(builder.build());
        responseObserver.onCompleted();
    }

    @Override
    public void reserveBalance(com.fintech.wallet.grpc.ReserveRequest request,
                               StreamObserver<com.fintech.wallet.grpc.ReserveResponse> responseObserver) {
        log.debug("gRPC ReserveBalance: walletId={}, amount={}, txId={}",
                request.getWalletId(), request.getAmount(), request.getTransactionId());

        WalletGrpcService.ReserveResult result = walletGrpcService.reserveBalance(
                request.getWalletId(), request.getAmount(),
                request.getTransactionId(), request.getReserveDurationSeconds());

        com.fintech.wallet.grpc.ReserveResponse.Builder builder = com.fintech.wallet.grpc.ReserveResponse.newBuilder()
                .setSuccess(result.success);
        if (result.reservedAmount != null) builder.setReservedAmount(result.reservedAmount);
        if (result.reservationId != null) builder.setReservationId(result.reservationId);
        if (result.errorCode != null) builder.setErrorCode(result.errorCode);
        if (result.errorMessage != null) builder.setErrorMessage(result.errorMessage);

        responseObserver.onNext(builder.build());
        responseObserver.onCompleted();
    }

    @Override
    public void releaseBalance(com.fintech.wallet.grpc.ReleaseRequest request,
                               StreamObserver<com.fintech.wallet.grpc.ReleaseResponse> responseObserver) {
        log.debug("gRPC ReleaseBalance: reservationId={}, txId={}",
                request.getReservationId(), request.getTransactionId());

        WalletGrpcService.ReleaseResult result = walletGrpcService.releaseBalance(
                request.getReservationId(), request.getTransactionId());

        com.fintech.wallet.grpc.ReleaseResponse.Builder builder = com.fintech.wallet.grpc.ReleaseResponse.newBuilder()
                .setSuccess(result.success);
        if (result.errorCode != null) builder.setErrorCode(result.errorCode);
        if (result.errorMessage != null) builder.setErrorMessage(result.errorMessage);

        responseObserver.onNext(builder.build());
        responseObserver.onCompleted();
    }

    @Override
    public void checkLimit(com.fintech.wallet.grpc.LimitCheckRequest request,
                           StreamObserver<com.fintech.wallet.grpc.LimitCheckResponse> responseObserver) {
        log.debug("gRPC CheckLimit: walletId={}, amount={}, type={}",
                request.getWalletId(), request.getAmount(), request.getTransactionType());

        WalletGrpcService.LimitCheckResult result = walletGrpcService.checkLimit(
                request.getWalletId(), request.getAmount(),
                request.getTransactionType(), request.getUserId());

        com.fintech.wallet.grpc.LimitCheckResponse.Builder builder = com.fintech.wallet.grpc.LimitCheckResponse.newBuilder()
                .setAllowed(result.allowed)
                .setTransactionType(request.getTransactionType());
        if (result.availableBalance != null) builder.setAvailableBalance(result.availableBalance);
        if (result.dailyLimitRemaining != null) builder.setDailyLimitRemaining(result.dailyLimitRemaining);
        if (result.transactionLimitRemaining != null) builder.setTransactionLimitRemaining(result.transactionLimitRemaining);
        if (result.errorCode != null) builder.setErrorCode(result.errorCode);
        if (result.errorMessage != null) builder.setErrorMessage(result.errorMessage);

        responseObserver.onNext(builder.build());
        responseObserver.onCompleted();
    }

    @Override
    public void getWalletByUserId(com.fintech.wallet.grpc.UserWalletRequest request,
                                  StreamObserver<com.fintech.wallet.grpc.WalletResponse> responseObserver) {
        log.debug("gRPC GetWalletByUserId: userId={}", request.getUserId());

        WalletGrpcService.GetWalletResult result = walletGrpcService.getWalletByUserId(request.getUserId());

        com.fintech.wallet.grpc.WalletResponse.Builder builder = com.fintech.wallet.grpc.WalletResponse.newBuilder()
                .setFound(result.found);
        if (result.walletId != null) builder.setWalletId(result.walletId);
        if (result.userId != null) builder.setUserId(result.userId);
        if (result.balance != null) builder.setBalance(result.balance);
        if (result.currency != null) builder.setCurrency(result.currency);
        if (result.status != null) builder.setStatus(result.status);
        if (result.errorCode != null) builder.setErrorCode(result.errorCode);
        if (result.errorMessage != null) builder.setErrorMessage(result.errorMessage);

        responseObserver.onNext(builder.build());
        responseObserver.onCompleted();
    }
}
