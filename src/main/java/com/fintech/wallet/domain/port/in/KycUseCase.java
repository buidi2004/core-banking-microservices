package com.fintech.wallet.domain.port.in;

import com.fintech.wallet.domain.model.UserKyc;

public interface KycUseCase {
    UserKyc submitKyc(String userId, String idCardNumber, String fullName, String dob, String frontUrl, String backUrl, String selfieUrl);
    UserKyc getKycStatus(String userId);
    UserKyc processKycWebhook(String userId, com.fintech.wallet.domain.model.KycStatus status, String rejectionReason);
}
