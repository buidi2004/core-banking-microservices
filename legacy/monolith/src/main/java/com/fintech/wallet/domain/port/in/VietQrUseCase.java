package com.fintech.wallet.domain.port.in;

import com.fintech.wallet.domain.model.VietQrPayload;
import java.math.BigDecimal;

public interface VietQrUseCase {
    VietQrPayload generateQr(String bankBin, String accountNumber, BigDecimal amount, String purpose);
    VietQrPayload decodeQr(String qrCodeString);
}
