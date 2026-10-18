package com.fintech.identity.dto;

import lombok.*;

import java.time.LocalDate;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UpdateProfileRequest {

    private String fullName;
    private String email;
    private String avatarUrl;
    private LocalDate dateOfBirth;
    private String address;
    private String gender;
}
