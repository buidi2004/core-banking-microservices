package com.fintech.wallet.presentation.controller;

import com.fintech.wallet.domain.model.UserProfile;
import com.fintech.wallet.domain.port.in.UserProfileUseCase;
import com.fintech.wallet.presentation.response.ApiResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/users")
public class ProfileController {

    private final UserProfileUseCase userProfileUseCase;

    public ProfileController(UserProfileUseCase userProfileUseCase) {
        this.userProfileUseCase = userProfileUseCase;
    }

    @GetMapping("/me")
    public ResponseEntity<ApiResponse<UserProfile>> getMyProfile(Authentication auth) {
        String userId = auth.getName();
        UserProfile profile = userProfileUseCase.getProfile(userId);
        return ResponseEntity.ok(ApiResponse.success("Profile retrieved", profile));
    }

    @PutMapping("/me")
    public ResponseEntity<ApiResponse<UserProfile>> updateProfile(
            Authentication auth,
            @RequestParam(required = false) String fullName,
            @RequestParam(required = false) String email,
            @RequestParam(required = false) String dob) {
        String userId = auth.getName();
        UserProfile profile = userProfileUseCase.updateProfile(userId, fullName, email, dob);
        return ResponseEntity.ok(ApiResponse.success("Profile updated", profile));
    }

    @PostMapping("/me/avatar")
    public ResponseEntity<ApiResponse<UserProfile>> updateAvatar(
            Authentication auth,
            @RequestParam String avatarUrl) {
        String userId = auth.getName();
        UserProfile profile = userProfileUseCase.updateAvatar(userId, avatarUrl);
        return ResponseEntity.ok(ApiResponse.success("Avatar updated", profile));
    }

    @GetMapping("/{id}/public-info")
    public ResponseEntity<ApiResponse<UserProfile>> getPublicRecipientInfo(@PathVariable String id) {
        UserProfile publicProfile = userProfileUseCase.getPublicRecipientInfo(id);
        return ResponseEntity.ok(ApiResponse.success("Recipient public info retrieved", publicProfile));
    }
}
