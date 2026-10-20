package com.fintech.identity.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.*;

import java.time.LocalDate;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class KycSubmitRequest {

    @NotBlank(message = "Document type is required (ID_CARD, PASSPORT, DRIVER_LICENSE)")
    private String documentType;

    @NotBlank(message = "Document number is required")
    private String documentNumber;

    @NotBlank(message = "Front image URL is required")
    private String frontImageUrl;

    private String backImageUrl;

    @NotBlank(message = "Face selfie image URL is required")
    private String faceImageUrl;

    private LocalDate issuedDate;
    private String issuedPlace;
}
