package com.fintech.identity.domain.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.Instant;

/**
 * Entity đại diện cho tài liệu xác minh danh tính eKYC (bảng user_kycs).
 */
@Entity
@Table(name = "user_kycs", indexes = {
    @Index(name = "idx_kycs_user_id", columnList = "user_id"),
    @Index(name = "idx_kycs_status", columnList = "verification_status")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserKycEntity {

    @Id
    @Column(length = 36, nullable = false)
    private String id;

    @Column(name = "user_id", length = 36, nullable = false)
    private String userId;

    @Column(name = "document_type", length = 20, nullable = false)
    private String documentType; // ID_CARD, PASSPORT, DRIVER_LICENSE

    @Column(name = "document_number", length = 50, nullable = false)
    private String documentNumber;

    @Column(name = "front_image_url", length = 255, nullable = false)
    private String frontImageUrl;

    @Column(name = "back_image_url", length = 255)
    private String backImageUrl;

    @Column(name = "face_image_url", length = 255, nullable = false)
    private String faceImageUrl;

    @Column(name = "ocr_extracted_data", columnDefinition = "JSONB")
    private String ocrExtractedData;

    @Column(name = "verification_status", length = 20, nullable = false)
    @Builder.Default
    private String verificationStatus = "PENDING"; // PENDING, APPROVED, REJECTED

    @Column(name = "reject_reason", columnDefinition = "TEXT")
    private String rejectReason;

    @Column(name = "verified_by", length = 36)
    private String verifiedBy;

    @Column(name = "verified_at")
    private Instant verifiedAt;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private Instant createdAt;
}
