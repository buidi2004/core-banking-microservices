package com.fintech.identity.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LockStaffRequest {

    @NotBlank(message = "Lý do khóa tài khoản cán bộ không được để trống")
    private String reason;
}

