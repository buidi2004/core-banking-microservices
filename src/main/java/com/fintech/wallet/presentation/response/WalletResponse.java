package com.fintech.wallet.presentation.response;

import com.fintech.wallet.domain.model.Wallet;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class WalletResponse {

    private String id;
    private String ownerId;
    private BigDecimal balance;
    private String currency;
    private Instant createdAt;
    private Instant updatedAt;

    public static WalletResponse fromDomain(Wallet wallet) {
        if (wallet == null) return null;
        return new WalletResponse(
                wallet.getId(),
                wallet.getOwnerId(),
                wallet.getBalance().getAmount(),
                wallet.getBalance().getCurrency(),
                wallet.getCreatedAt(),
                wallet.getUpdatedAt()
        );
    }
}
