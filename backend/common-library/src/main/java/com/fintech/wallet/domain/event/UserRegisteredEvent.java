package com.fintech.wallet.domain.event;

import java.time.Instant;
import java.util.UUID;

/**
 * Sự kiện công khai khi một user mới đăng ký thành công.
 * Được publish lên RabbitMQ để khởi tạo ví tự động (Event-Driven Onboarding).
 *
 * Flow:
 *   1. Identity Service nhận đăng ký → persist user vào ewallet_identity_db
 *   2. Publish UserRegisteredEvent lên RabbitMQ exchange "wallet.exchange"
 *   3. Wallet Service (hoặc Monolith tạm thời) lắng nghe → khởi tạo ví trong ewallet_wallet_db
 *   4. Nếu thành công → publish WalletCreatedEvent
 *   5. Nếu thất bại → retry tự động theo cơ chế dead-letter
 */
public record UserRegisteredEvent(
    /** UUID duy nhất của sự kiện, dùng cho idempotency */
    UUID eventId,

    /** Timestamp sự kiện được tạo */
    Instant occurredAt,

    /** ID người dùng mới đăng ký (UUID định dạng String) */
    String userId,

    /** Số điện thoại của người dùng */
    String phone,

    /** Họ và tên đầy đủ */
    String fullName,

    /** Tier eKYC ban đầu (0 = chưa xác thực) */
    Integer kycTier,

    /** Mã quốc gia (VD: 'VN') */
    String countryCode,

    /** Header mở rộng tùy chọn (metadata bổ sung) */
    String metadata
) {
    public UserRegisteredEvent {
        if (userId == null || userId.isBlank()) {
            throw new IllegalArgumentException("userId must not be null or blank");
        }
        if (phone == null || phone.isBlank()) {
            throw new IllegalArgumentException("phone must not be null or blank");
        }
    }

    /** Alias tương thích ngược cho phoneNumber */
    public String phoneNumber() {
        return phone;
    }

    /** Factory method tạo event mới từ thông tin user vừa đăng ký */
    public static UserRegisteredEvent of(String userId, String phone, String fullName,
                                          Integer kycTier, String countryCode) {
        return new UserRegisteredEvent(
            UUID.randomUUID(),
            Instant.now(),
            userId,
            phone,
            fullName,
            kycTier,
            countryCode,
            null
        );
    }
}
