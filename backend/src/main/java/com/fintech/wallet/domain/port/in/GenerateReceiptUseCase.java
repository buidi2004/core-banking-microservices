package com.fintech.wallet.domain.port.in;

public interface GenerateReceiptUseCase {
    byte[] generateReceiptPdf(String transactionId, String userId);
}
