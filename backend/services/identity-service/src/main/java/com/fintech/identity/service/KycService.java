package com.fintech.identity.service;

import com.fintech.identity.domain.entity.UserEntity;
import com.fintech.identity.domain.entity.UserKycEntity;
import com.fintech.identity.domain.entity.UserProfileEntity;
import com.fintech.identity.dto.KycResponse;
import com.fintech.identity.dto.KycSubmitRequest;
import com.fintech.identity.repository.UserKycRepository;
import com.fintech.identity.repository.UserProfileRepository;
import com.fintech.identity.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class KycService {

    private final UserKycRepository userKycRepository;
    private final UserRepository userRepository;
    private final UserProfileRepository userProfileRepository;

    @Transactional
    public KycResponse submitKyc(String userId, KycSubmitRequest request) {
        UserEntity user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy người dùng với ID: " + userId));

        // Lưu hồ sơ eKYC mới
        String kycId = UUID.randomUUID().toString();
        UserKycEntity kyc = UserKycEntity.builder()
                .id(kycId)
                .userId(userId)
                .documentType(request.getDocumentType())
                .documentNumber(request.getDocumentNumber())
                .frontImageUrl(request.getFrontImageUrl())
                .backImageUrl(request.getBackImageUrl())
                .faceImageUrl(request.getFaceImageUrl())
                .verificationStatus("PENDING")
                .build();
        userKycRepository.save(kyc);

        // Đồng bộ số CCCD/CMND vào UserProfile
        UserProfileEntity profile = userProfileRepository.findByUserId(userId)
                .orElseGet(() -> UserProfileEntity.builder()
                        .id(UUID.randomUUID().toString())
                        .userId(userId)
                        .build());
        profile.setIdentityCardNumber(request.getDocumentNumber());
        if (request.getIssuedDate() != null) profile.setIdentityCardIssuedDate(request.getIssuedDate());
        if (request.getIssuedPlace() != null) profile.setIdentityCardIssuedPlace(request.getIssuedPlace());
        userProfileRepository.save(profile);

        log.info("Người dùng userId={} đã gửi hồ sơ eKYC (kycId={}, status=PENDING)", userId, kycId);

        return mapToResponse(kyc, user.getKycTier());
    }

    @Transactional(readOnly = true)
    public KycResponse getKycStatus(String userId) {
        UserEntity user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy người dùng với ID: " + userId));

        UserKycEntity kyc = userKycRepository.findTopByUserIdOrderByCreatedAtDesc(userId)
                .orElse(null);

        if (kyc == null) {
            return KycResponse.builder()
                    .userId(userId)
                    .verificationStatus("NOT_SUBMITTED")
                    .currentKycTier(user.getKycTier())
                    .build();
        }

        return mapToResponse(kyc, user.getKycTier());
    }

    @Transactional(readOnly = true)
    public List<KycResponse> getPendingKycs() {
        return userKycRepository.findByVerificationStatus("PENDING").stream()
                .map(kyc -> {
                    UserEntity user = userRepository.findById(kyc.getUserId()).orElse(null);
                    String tier = user != null ? user.getKycTier() : "UNVERIFIED";
                    return mapToResponse(kyc, tier);
                })
                .toList();
    }

    @Transactional
    public KycResponse reviewKyc(String kycId, String status, String reason, String verifiedBy) {
        UserKycEntity kyc = userKycRepository.findById(kycId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy hồ sơ eKYC ID: " + kycId));

        kyc.setVerificationStatus(status);
        kyc.setRejectReason(reason);
        kyc.setVerifiedBy(verifiedBy);
        kyc.setVerifiedAt(Instant.now());
        userKycRepository.save(kyc);

        UserEntity user = userRepository.findById(kyc.getUserId())
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy user: " + kyc.getUserId()));

        if ("APPROVED".equalsIgnoreCase(status)) {
            user.setKycTier("VERIFIED");
            userRepository.save(user);
            log.info("eKYC đã được phê duyệt! Nâng cấp userId={} lên kycTier=VERIFIED", user.getId());
        } else if ("REJECTED".equalsIgnoreCase(status)) {
            log.warn("eKYC bị từ chối cho userId={}, lý do: {}", user.getId(), reason);
        }

        return mapToResponse(kyc, user.getKycTier());
    }

    @Transactional
    public KycResponse autoApproveKyc(com.fintech.identity.dto.KycAutoApproveRequest request) {
        String userId = request.getUserId();
        UserEntity user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy người dùng với ID: " + userId));

        UserKycEntity kyc = userKycRepository.findTopByUserIdOrderByCreatedAtDesc(userId)
                .orElseGet(() -> {
                    String newId = UUID.randomUUID().toString();
                    return UserKycEntity.builder()
                            .id(newId)
                            .userId(userId)
                            .documentType("CHIP_ID_CARD")
                            .documentNumber(request.getDocumentNumber() != null ? request.getDocumentNumber() : "NFC_VERIFIED")
                            .frontImageUrl("NFC_DG2_CHIP_PHOTO")
                            .faceImageUrl("BIOMETRIC_LIVENESS_SELFIE")
                            .build();
                });

        String reviewer = request.getVerifiedBy() != null ? request.getVerifiedBy() : "AI_EKYC_PIPELINE";
        String note = String.format("Duyệt tự động bởi AI eKYC Pipeline (Liveness: %.2f, Sim: %.2f, Session: %s)",
                request.getLivenessScore() != null ? request.getLivenessScore() : 1.0,
                request.getSimilarity() != null ? request.getSimilarity() : 1.0,
                request.getSessionId() != null ? request.getSessionId() : "N/A");

        kyc.setVerificationStatus("APPROVED");
        kyc.setRejectReason(note);
        kyc.setVerifiedBy(reviewer);
        kyc.setVerifiedAt(Instant.now());
        if (request.getDocumentNumber() != null) {
            kyc.setDocumentNumber(request.getDocumentNumber());
            // Đồng bộ số CCCD vào UserProfile khi duyệt tự động qua AI
            if (!"NFC_VERIFIED".equals(request.getDocumentNumber())) {
                UserProfileEntity profile = userProfileRepository.findByUserId(userId)
                        .orElseGet(() -> UserProfileEntity.builder()
                                .id(UUID.randomUUID().toString())
                                .userId(userId)
                                .build());
                profile.setIdentityCardNumber(request.getDocumentNumber());
                userProfileRepository.save(profile);
            }
        }
        userKycRepository.save(kyc);

        user.setKycTier("VERIFIED");
        userRepository.save(user);
        log.info("eKYC tự động phê duyệt thành công qua AI Pipeline cho userId={} (Session: {})", userId, request.getSessionId());

        return mapToResponse(kyc, user.getKycTier());
    }

    private KycResponse mapToResponse(UserKycEntity kyc, String currentKycTier) {
        return KycResponse.builder()
                .id(kyc.getId())
                .userId(kyc.getUserId())
                .documentType(kyc.getDocumentType())
                .documentNumber(kyc.getDocumentNumber())
                .frontImageUrl(kyc.getFrontImageUrl())
                .backImageUrl(kyc.getBackImageUrl())
                .faceImageUrl(kyc.getFaceImageUrl())
                .verificationStatus(kyc.getVerificationStatus())
                .rejectReason(kyc.getRejectReason())
                .currentKycTier(currentKycTier)
                .createdAt(kyc.getCreatedAt())
                .verifiedAt(kyc.getVerifiedAt())
                .build();
    }
}
