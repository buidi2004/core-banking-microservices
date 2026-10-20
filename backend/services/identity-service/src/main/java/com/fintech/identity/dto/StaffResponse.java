package com.fintech.identity.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fintech.identity.domain.entity.UserEntity;
import lombok.*;

import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class StaffResponse {

    private String id;
    private String username;
    private String fullName;
    private String phoneNumber;
    private String email;
    private String role;
    private List<String> roles;
    private String branchId;
    private String status;
    private String kycTier;

    public static StaffResponse fromEntity(UserEntity user) {
        if (user == null) {
            return null;
        }

        String resolvedUsername = user.getUsername();
        if (resolvedUsername == null || resolvedUsername.isBlank()) {
            if (user.getEmail() != null && user.getEmail().contains("@")) {
                resolvedUsername = user.getEmail().substring(0, user.getEmail().indexOf('@'));
            } else {
                resolvedUsername = user.getPhoneNumber();
            }
        }

        String role = user.getRole();
        List<String> rolesList = role != null ? List.of(role) : List.of();

        return StaffResponse.builder()
                .id(user.getId())
                .username(resolvedUsername)
                .fullName(user.getFullName())
                .phoneNumber(user.getPhoneNumber())
                .email(user.getEmail())
                .role(role)
                .roles(rolesList)
                .branchId(user.getBranchId())
                .status(user.getStatus())
                .kycTier(user.getKycTier())
                .build();
    }
}
