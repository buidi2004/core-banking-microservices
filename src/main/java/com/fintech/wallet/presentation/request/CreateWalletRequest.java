package com.fintech.wallet.presentation.request;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class CreateWalletRequest {

    @NotBlank(message = "Owner ID is required")
    private String ownerId;

    @NotBlank(message = "Currency is required")
    private String currency;
}
