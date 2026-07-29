package com.fintech.wallet.domain.port.in;

public interface PinUseCase {
    void setPin(String userId, String rawPin);
    String verifyPinAndIssueToken(String userId, String rawPin);
    boolean validatePinToken(String userId, String pinToken);
}
