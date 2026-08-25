package com.fintech.wallet.presentation.request;

import com.fintech.wallet.domain.model.FundingSourceType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public class LinkFundingSourceRequest {
    
    @NotNull(message = "Type cannot be null")
    private FundingSourceType type;
    
    @NotBlank(message = "Provider cannot be empty")
    private String provider;
    
    @NotBlank(message = "Card/Account number cannot be empty")
    @Size(min = 4, max = 20, message = "Invalid number length")
    private String number;
    
    // Optional fields for standard credit cards (mock)
    private String cardHolderName;
    private String expiryDate;
    private String cvv;

    public LinkFundingSourceRequest() {}

    public LinkFundingSourceRequest(FundingSourceType type, String provider, String number, String cardHolderName, String expiryDate, String cvv) {
        this.type = type;
        this.provider = provider;
        this.number = number;
        this.cardHolderName = cardHolderName;
        this.expiryDate = expiryDate;
        this.cvv = cvv;
    }

    public FundingSourceType getType() { return type; }
    public void setType(FundingSourceType type) { this.type = type; }

    public String getProvider() { return provider; }
    public void setProvider(String provider) { this.provider = provider; }

    public String getNumber() { return number; }
    public void setNumber(String number) { this.number = number; }

    public String getCardHolderName() { return cardHolderName; }
    public void setCardHolderName(String cardHolderName) { this.cardHolderName = cardHolderName; }

    public String getExpiryDate() { return expiryDate; }
    public void setExpiryDate(String expiryDate) { this.expiryDate = expiryDate; }

    public String getCvv() { return cvv; }
    public void setCvv(String cvv) { this.cvv = cvv; }
}
