package com.fintech.identity.service;

import com.fintech.identity.domain.entity.UserEntity;
import com.fintech.identity.domain.entity.UserProfileEntity;
import com.fintech.identity.dto.UpdateProfileRequest;
import com.fintech.identity.dto.UserProfileResponse;
import com.fintech.identity.repository.UserProfileRepository;
import com.fintech.identity.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final UserProfileRepository userProfileRepository;

    @Transactional(readOnly = true)
    public UserProfileResponse getProfile(String userId) {
        UserEntity user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy người dùng với ID: " + userId));

        UserProfileEntity profile = userProfileRepository.findByUserId(userId)
                .orElse(null);

        return mapToResponse(user, profile);
    }

    @Transactional
    public UserProfileResponse updateProfile(String userId, UpdateProfileRequest request) {
        UserEntity user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy người dùng với ID: " + userId));

        if (request.getFullName() != null && !request.getFullName().isBlank()) {
            user.setFullName(request.getFullName().trim());
        }
        if (request.getEmail() != null && !request.getEmail().isBlank()) {
            String email = request.getEmail().trim();
            if (!email.equalsIgnoreCase(user.getEmail()) && userRepository.existsByEmail(email)) {
                throw new IllegalArgumentException("Email " + email + " đã được sử dụng bởi tài khoản khác.");
            }
            user.setEmail(email);
        }
        userRepository.save(user);

        UserProfileEntity profile = userProfileRepository.findByUserId(userId)
                .orElseGet(() -> UserProfileEntity.builder()
                        .id(UUID.randomUUID().toString())
                        .userId(userId)
                        .build());

        if (request.getAvatarUrl() != null) profile.setAvatarUrl(request.getAvatarUrl());
        if (request.getDateOfBirth() != null) profile.setDateOfBirth(request.getDateOfBirth());
        if (request.getAddress() != null) profile.setAddress(request.getAddress());
        if (request.getGender() != null) profile.setGender(request.getGender());

        userProfileRepository.save(profile);
        log.info("Cập nhật thông tin thành công cho userId={}", userId);

        return mapToResponse(user, profile);
    }

    private UserProfileResponse mapToResponse(UserEntity user, UserProfileEntity profile) {
        return UserProfileResponse.builder()
                .userId(user.getId())
                .phoneNumber(user.getPhoneNumber())
                .fullName(user.getFullName())
                .email(user.getEmail())
                .role(user.getRole())
                .status(user.getStatus())
                .kycTier(user.getKycTier())
                .createdAt(user.getCreatedAt())
                .updatedAt(user.getUpdatedAt())
                .avatarUrl(profile != null ? profile.getAvatarUrl() : null)
                .dateOfBirth(profile != null ? profile.getDateOfBirth() : null)
                .address(profile != null ? profile.getAddress() : null)
                .gender(profile != null ? profile.getGender() : null)
                .identityCardNumber(profile != null ? profile.getIdentityCardNumber() : null)
                .identityCardIssuedDate(profile != null ? profile.getIdentityCardIssuedDate() : null)
                .identityCardIssuedPlace(profile != null ? profile.getIdentityCardIssuedPlace() : null)
                .build();
    }
}
