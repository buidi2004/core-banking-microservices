package com.fintech.wallet.presentation.response;

import com.fintech.wallet.domain.model.UserKyc;

public class KycResponse {

    private String id;
    private String userId;
    private String idCardNumber;
    private String fullName;
    private String status;

    public KycResponse(String id, String userId, String idCardNumber, String fullName, String status) {
        this.id = id;
        this.userId = userId;
        this.idCardNumber = idCardNumber;
        this.fullName = fullName;
        this.status = status;
    }

    public static KycResponse fromDomain(UserKyc kyc) {
        if (kyc == null) return null;
        return new KycResponse(
                kyc.getId(),
                kyc.getUserId(),
                kyc.getIdCardNumber(),
                kyc.getFullName(),
                kyc.getStatus().name()
        );
    }

    public String getId() { return id; }
    public String getUserId() { return userId; }
    public String getIdCardNumber() { return idCardNumber; }
    public String getFullName() { return fullName; }
    public String getStatus() { return status; }
}
