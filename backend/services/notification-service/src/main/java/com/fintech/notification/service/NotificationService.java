package com.fintech.notification.service;

import com.fintech.notification.dto.PageResponse;
import com.fintech.notification.entity.Notification;
import com.fintech.notification.repository.NotificationRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class NotificationService {

    private static final Logger log = LoggerFactory.getLogger(NotificationService.class);

    private final NotificationRepository notificationRepository;
    private final Map<String, Map<String, Boolean>> settingsStore = new ConcurrentHashMap<>();

    public NotificationService(NotificationRepository notificationRepository) {
        this.notificationRepository = notificationRepository;
    }

    public PageResponse<Notification> getNotifications(String userId, String type, int page, int size) {
        PageRequest pageRequest = PageRequest.of(Math.max(page, 0), size > 0 ? size : 20,
                Sort.by(Sort.Direction.DESC, "createdAt"));

        if (userId != null && !userId.isBlank() && type != null && !type.isBlank()) {
            ensurePromoAndSystemNotifications(userId, type.trim().toUpperCase());
        }

        Page<Notification> result = (type != null && !type.isBlank())
                ? notificationRepository.findByUserIdAndType(userId, type, pageRequest)
                : notificationRepository.findByUserId(userId, pageRequest);
        return PageResponse.of(result.getContent(), page, pageRequest.getPageSize(), result.getTotalElements());
    }

    private void ensurePromoAndSystemNotifications(String userId, String normalizedType) {
        try {
            if ("PROMOTION".equals(normalizedType)) {
                PageRequest p0 = PageRequest.of(0, 1);
                if (notificationRepository.findByUserIdAndType(userId, "PROMOTION", p0).isEmpty()) {
                    Notification n1 = Notification.create(userId, "PROMOTION",
                            "Ưu đãi chào bạn mới: Tặng voucher 25.000đ hóa đơn",
                            "Nhập mã SENHONG5 để được giảm ngay 15.000đ khi thanh toán tiền điện, nước, internet qua Sen Hồng Bank.",
                            "IN_APP", "{\"voucherCode\":\"SENHONG5\",\"discount\":15000}");
                    Notification n2 = Notification.create(userId, "PROMOTION",
                            "Chiết khấu 3% nạp tiền điện thoại mọi nhà mạng",
                            "Nạp thẻ điện thoại Viettel, VinaPhone, MobiFone trực tiếp trên ứng dụng được chiết khấu ngay 3% giá trị giao dịch.",
                            "IN_APP", "{\"discountPercent\":3}");
                    notificationRepository.save(n1);
                    notificationRepository.save(n2);
                }
            } else if ("SYSTEM".equals(normalizedType)) {
                PageRequest p0 = PageRequest.of(0, 1);
                if (notificationRepository.findByUserIdAndType(userId, "SYSTEM", p0).isEmpty()) {
                    Notification n1 = Notification.create(userId, "SYSTEM",
                            "Quyết định 2345/QĐ-NHNN về an toàn thanh toán trực tuyến",
                            "Từ ngày 01/07/2026, các giao dịch chuyển tiền từ 10.000.000đ/lần hoặc tổng giá trị trên 20.000.000đ/ngày bắt buộc phải xác thực sinh trắc học khuôn mặt.",
                            "IN_APP", "{\"standard\":\"QĐ 2345/QĐ-NHNN\"}");
                    Notification n2 = Notification.create(userId, "SYSTEM",
                            "Cảnh báo bảo mật thông tin tài khoản ngân hàng",
                            "Sen Hồng Bank không bao giờ yêu cầu khách hàng cung cấp mã OTP, mã PIN hay mật khẩu dưới bất kỳ hình thức nào. Vui lòng cảnh giác trước các đường link lạ.",
                            "IN_APP", "{\"securityLevel\":\"HIGH\"}");
                    notificationRepository.save(n1);
                    notificationRepository.save(n2);
                }
            }
        } catch (Exception e) {
            log.warn("Không thể seed thông báo {} cho {}: {}", normalizedType, userId, e.getMessage());
        }
    }

    @Transactional
    public void markAsRead(String userId, String notificationId) {
        notificationRepository.markAsRead(userId, UUID.fromString(notificationId), Instant.now());
    }

    @Transactional
    public void markAllAsRead(String userId, String type) {
        String filter = (type == null || type.isBlank()) ? null : type;
        notificationRepository.markAllAsRead(userId, filter, Instant.now());
    }

    /** Kiểm tra notification của giao dịch đã tồn tại chưa (chống trùng khi Rabbit/Kafka cùng giao). */
    public boolean existsForTransaction(String userId, String transactionId, String status) {
        if (userId == null || userId.isBlank() || transactionId == null || transactionId.isBlank()) {
            return false;
        }
        return notificationRepository.countByUserAndTransaction(userId, transactionId,
                (status == null || status.isBlank()) ? "SUCCESS" : status.toUpperCase()) > 0;
    }

    /** Tìm notification theo transactionId để kiểm tra hoặc làm giàu dữ liệu chi tiết. */
    public java.util.Optional<Notification> findByUserAndTransaction(String userId, String transactionId, String status) {
        if (userId == null || userId.isBlank() || transactionId == null || transactionId.isBlank()) {
            return java.util.Optional.empty();
        }
        return notificationRepository.findByUserAndTransaction(userId, transactionId,
                (status == null || status.isBlank()) ? "SUCCESS" : status.toUpperCase());
    }

    @Transactional
    public Notification save(Notification notification) {
        return notificationRepository.save(notification);
    }

    public long countUnread(String userId) {
        return notificationRepository.countByUserIdAndReadFalse(userId);
    }

    public Map<String, Boolean> getSettings(String userId) {
        return settingsStore.computeIfAbsent(userId, k -> {
            Map<String, Boolean> defaults = new ConcurrentHashMap<>();
            defaults.put("TRANSACTION", true);
            defaults.put("PROMO", true);
            return defaults;
        });
    }

    public void updateSettings(String userId, boolean transactionEnabled, boolean promoEnabled) {
        Map<String, Boolean> userSettings = settingsStore.computeIfAbsent(userId, k -> new ConcurrentHashMap<>());
        userSettings.put("TRANSACTION", transactionEnabled);
        userSettings.put("PROMO", promoEnabled);
        log.info("Updated notification settings for user={}: transaction={}, promo={}",
                userId, transactionEnabled, promoEnabled);
    }
}
