package com.fintech.wallet.presentation.request;

import jakarta.validation.constraints.NotBlank;

public class KycSubmitRequest {

    @NotBlank(message = "ID card number is required")
    private String idCardNumber;

    @NotBlank(message = "Full name is required")
    private String fullName;

    @NotBlank(message = "Date of birth is required")
    private String dob;

    private String frontCardUrl;
    private String backCardUrl;
    private String selfieUrl;

    public String getIdCardNumber() { return idCardNumber; }
    public void setIdCardNumber(String idCardNumber) { this.idCardNumber = idCardNumber; }
    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }
    public String getDob() { return dob; }
    public void setDob(String dob) { this.dob = dob; }
    public String getFrontCardUrl() { return frontCardUrl; }
    public void setFrontCardUrl(String frontCardUrl) { this.frontCardUrl = frontCardUrl; }
    public String getBackCardUrl() { return backCardUrl; }
    public void setBackCardUrl(String backCardUrl) { this.backCardUrl = backCardUrl; }
    public String getSelfieUrl() { return selfieUrl; }
    public void setSelfieUrl(String selfieUrl) { this.selfieUrl = selfieUrl; }
}
