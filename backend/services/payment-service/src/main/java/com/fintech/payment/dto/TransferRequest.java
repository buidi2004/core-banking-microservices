package com.fintech.payment.dto;

import com.fasterxml.jackson.annotation.JsonAlias;
import jakarta.validation.constraints.*;
import lombok.*;

@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class TransferRequest {

    @JsonAlias({"senderId", "sender_id", "sourceId", "source_id"})
    private String sourceUserId;

    @JsonAlias({"receiverId", "receiver_id", "targetId", "target_id"})
    private String targetUserId;

    @JsonAlias({"source_wallet_id", "sourceWallet"})
    private String sourceWalletId;

    @JsonAlias({"target_wallet_id", "targetWallet", "receiverWalletId", "receiver_wallet_id"})
    private String targetWalletId;

    @JsonAlias({"senderPhone", "sender_phone", "sourcePhone"})
    private String senderPhone;

    @JsonAlias({"receiverPhone", "receiver_phone", "targetPhone"})
    private String receiverPhone;

    @NotNull(message = "amount là bắt buộc")
    @Positive(message = "amount phải lớn hơn 0")
    private Long amount;

    @Builder.Default
    private String currency = "VND";

    private String note;

    @JsonAlias({"requestId", "request_id"})
    private String idempotencyKey;

    private String pinToken;

    @JsonAlias({"biometricToken", "biometric_token", "faceToken", "face_token"})
    private String biometricToken;
}

