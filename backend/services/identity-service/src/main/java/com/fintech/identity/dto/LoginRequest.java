package com.fintech.identity.dto;

import com.fasterxml.jackson.annotation.JsonAlias;
import jakarta.validation.constraints.NotBlank;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LoginRequest {

    @JsonAlias({"username", "user_name", "user"})
    private String username;

    @JsonAlias({"phoneNumber", "phone_number", "phone"})
    private String phoneNumber;

    @NotBlank(message = "Password is required")
    private String password;

    private String deviceId;
    private String deviceName;
    private String deviceOs;

    /**
     * Lấy định danh tài khoản để đăng nhập (ưu tiên username, sau đó phoneNumber).
     */
    public String getIdentifier() {
        if (username != null && !username.isBlank()) {
            return username.trim();
        }
        if (phoneNumber != null && !phoneNumber.isBlank()) {
            return phoneNumber.trim();
        }
        return null;
    }

    /**
     * Tương thích ngược: nếu phoneNumber null nhưng username có, trả về username.
     */
    public String getPhoneNumber() {
        if (phoneNumber != null && !phoneNumber.isBlank()) {
            return phoneNumber;
        }
        return username;
    }
}
