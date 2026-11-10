package com.fintech.wallet.infrastructure.web;

import com.fintech.wallet.domain.model.Money;
import com.fintech.wallet.domain.model.Wallet;
import com.fintech.wallet.domain.model.WalletStatus;
import com.fintech.wallet.domain.port.out.WalletPersistencePort;
import com.fintech.wallet.infrastructure.kafka.WalletBalanceChangedKafkaProducer;
import com.fintech.wallet.kafka.WalletBalanceChangedPayload;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestClient;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/**
 * REST adapter cho Mobile (chỉ đọc thông tin ví).
 * Các API ghi (transfer/deposit/withdraw) đi qua payment-service để giữ nguyên saga.
 *
 * Gateway inject header tin cậy X-User-Id; controller không tự parse JWT.
 */
@RestController
@RequestMapping("/api/v1/wallets")
public class WalletRestController {

    private static final Logger log = LoggerFactory.getLogger(WalletRestController.class);

    private final WalletPersistencePort walletPersistencePort;
    private final RestClient identityClient;
    private final WalletBalanceChangedKafkaProducer walletKafkaProducer;

    public WalletRestController(WalletPersistencePort walletPersistencePort,
                                @Value("${identity.service.url:http://localhost:8081}") String identityServiceUrl,
                                @Autowired(required = false) WalletBalanceChangedKafkaProducer walletKafkaProducer) {
        this.walletPersistencePort = walletPersistencePort;
        this.identityClient = RestClient.builder().baseUrl(identityServiceUrl).build();
        this.walletKafkaProducer = walletKafkaProducer;
    }

    @GetMapping("/me")
    public ResponseEntity<Map<String, Object>> myWallet(
            @RequestHeader(value = "X-User-Id", required = false) String userId) {
        if (userId == null || userId.isBlank()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(error("Missing trusted header X-User-Id"));
        }
        return walletPersistencePort.findWalletByOwnerId(userId)
                .map(wallet -> ResponseEntity.ok(ok("Wallet retrieved", walletData(wallet))))
                .orElseGet(() -> ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(error("Không tìm thấy ví cho người dùng: " + userId)));
    }

    @GetMapping("/{walletId}")
    public ResponseEntity<Map<String, Object>> walletDetail(@PathVariable String walletId) {
        return walletPersistencePort.findWalletById(walletId)
                .map(wallet -> ResponseEntity.ok(ok("Wallet retrieved", walletData(wallet))))
                .orElseGet(() -> ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(error("Không tìm thấy ví: " + walletId)));
    }

    /**
     * Tra cứu người nhận trước khi chuyển tiền.
     * Hỗ trợ walletId hoặc phoneNumber (gọi identity-service nội bộ để map phone -> userId).
     */
    @GetMapping("/recipient-info")
    public ResponseEntity<Map<String, Object>> recipientInfo(
            @RequestParam(required = false) String walletId,
            @RequestParam(required = false) String phoneNumber,
            @RequestParam(required = false) String alias) {

        Optional<Wallet> wallet = Optional.empty();
        Map<String, Object> identity = null;

        if (walletId != null && !walletId.isBlank()) {
            wallet = walletPersistencePort.findWalletById(walletId.trim())
                    .or(() -> walletPersistencePort.findWalletByOwnerId(walletId.trim()));
        } else if (alias != null && !alias.isBlank()) {
            identity = lookupIdentity("phone", alias.trim().toUpperCase());
            String ownerId = identity != null ? asString(identity.get("id")) : null;
            if (ownerId != null) {
                wallet = walletPersistencePort.findWalletByOwnerId(ownerId);
            }
        } else if (phoneNumber != null && !phoneNumber.isBlank()) {
            String cleanPhone = normalizePhone(phoneNumber);
            identity = lookupIdentity("phone", cleanPhone);
            if (identity == null && !cleanPhone.equals(phoneNumber.trim())) {
                identity = lookupIdentity("phone", phoneNumber.trim());
            }
            String ownerId = identity != null ? asString(identity.get("id")) : null;
            if (ownerId != null) {
                wallet = walletPersistencePort.findWalletByOwnerId(ownerId);
            }
        } else {
            return ResponseEntity.badRequest().body(error("Cần truyền walletId, phoneNumber hoặc alias"));
        }

        if (wallet.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(error("Không tìm thấy ví người nhận"));
        }

        Wallet w = wallet.get();
        if (identity == null) {
            identity = lookupIdentity("id", w.getOwnerId());
        }

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("walletId", w.getId());
        data.put("ownerId", w.getOwnerId());
        data.put("fullName", identity != null ? identity.get("fullName") : null);
        data.put("phoneNumber", identity != null ? identity.get("phoneNumber") : null);
        data.put("currency", w.getBalance().getCurrency());
        data.put("status", w.getStatus() != null ? w.getStatus().name() : "ACTIVE");
        data.put("accountNumber", w.getId());
        return ResponseEntity.ok(ok("Recipient info retrieved", data));
    }

    /** Mobile hiển thị phí trước khi chuyển; saga hiện chưa thu phí nên trả 0. */
    @GetMapping("/fees/estimate")
    public ResponseEntity<Map<String, Object>> estimateFee(
            @RequestParam(required = false) String type,
            @RequestParam(defaultValue = "0") double amount,
            @RequestParam(defaultValue = "VND") String currency) {
        long roundedAmount = Math.round(amount);
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("type", type != null ? type : "TRANSFER");
        data.put("amount", roundedAmount);
        data.put("feeAmount", 0);
        data.put("totalAmount", roundedAmount);
        data.put("currency", currency);
        return ResponseEntity.ok(ok("Fee estimated", data));
    }

    /**
     * Tra cứu & Lọc danh mục tài khoản khách hàng dành cho Admin / Giám đốc:
     * - keyword: Lọc theo SĐT, Tên khách hàng, Mã ví/Số tài khoản
     * - status: ALL, ACTIVE, BLOCKED, LOCKED
     * - minBalance / maxBalance: Khoảng số dư ví
     */
    @GetMapping("/admin/accounts")
    public ResponseEntity<Map<String, Object>> searchAccountsForAdmin(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) Double minBalance,
            @RequestParam(required = false) Double maxBalance) {

        List<Wallet> allWallets = walletPersistencePort.findAllWallets();
        List<Map<String, Object>> result = new ArrayList<>();

        String kw = keyword != null ? keyword.trim().toLowerCase() : null;
        String filterStatus = status != null && !"ALL".equalsIgnoreCase(status.trim()) ? status.trim().toUpperCase() : null;

        for (Wallet w : allWallets) {
            String currentStatus = w.getStatus() != null ? w.getStatus().name() : "ACTIVE";
            if (filterStatus != null && !currentStatus.equalsIgnoreCase(filterStatus)) {
                continue;
            }

            double bal = w.getBalance().getAmount().doubleValue();
            if (minBalance != null && bal < minBalance) {
                continue;
            }
            if (maxBalance != null && bal > maxBalance) {
                continue;
            }

            Map<String, Object> identity = lookupIdentity("id", w.getOwnerId());
            String phone = identity != null && identity.get("phoneNumber") != null ? String.valueOf(identity.get("phoneNumber")) : "";
            String name = identity != null && identity.get("fullName") != null ? String.valueOf(identity.get("fullName")) : "Khách hàng " + w.getOwnerId().substring(0, Math.min(8, w.getOwnerId().length()));
            String kycTier = identity != null && identity.get("kycTier") != null ? String.valueOf(identity.get("kycTier")) : "VERIFIED";

            if (kw != null && !kw.isBlank()) {
                boolean matchId = w.getId().toLowerCase().contains(kw);
                boolean matchPhone = phone.toLowerCase().contains(kw);
                boolean matchName = name.toLowerCase().contains(kw);
                boolean matchOwner = w.getOwnerId().toLowerCase().contains(kw);
                if (!matchId && !matchPhone && !matchName && !matchOwner) {
                    continue;
                }
            }

            Map<String, Object> item = new LinkedHashMap<>();
            item.put("walletId", w.getId());
            item.put("accountNumber", w.getId());
            item.put("ownerId", w.getOwnerId());
            item.put("customerName", name);
            item.put("phoneNumber", phone);
            item.put("balance", w.getBalance().getAmount());
            item.put("currency", w.getBalance().getCurrency());
            item.put("status", currentStatus);
            item.put("kycTier", kycTier);
            item.put("dailyLimit", w.getDailyLimit());
            item.put("overdraftLimit", w.getOverdraftLimit());
            item.put("createdAt", w.getCreatedAt().toString());
            result.add(item);
        }

        return ResponseEntity.ok(ok("Danh sách tài khoản khách hàng (" + result.size() + " tài khoản)", result));
    }

    /**
     * Khóa hoặc Mở khóa tài khoản ví bởi Giám đốc / Admin.
     */
    @PostMapping("/admin/accounts/{walletId}/status")
    public ResponseEntity<Map<String, Object>> updateWalletStatus(
            @PathVariable String walletId,
            @RequestParam String status) {

        Optional<Wallet> walletOpt = walletPersistencePort.findWalletById(walletId);
        if (walletOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error("Không tìm thấy ví: " + walletId));
        }

        Wallet wallet = walletOpt.get();
        try {
            WalletStatus newStatus = WalletStatus.valueOf(status.trim().toUpperCase());
            wallet.setStatus(newStatus);
            walletPersistencePort.saveWallet(wallet);

            Map<String, Object> data = new LinkedHashMap<>();
            data.put("walletId", wallet.getId());
            data.put("status", newStatus.name());
            data.put("updatedAt", wallet.getUpdatedAt().toString());

            log.info("Admin updated wallet {} status to {}", walletId, newStatus);
            return ResponseEntity.ok(ok("Cập nhật trạng thái ví thành công: " + newStatus, data));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(error("Trạng thái không hợp lệ: " + status));
        }
    }

    /**
     * Batch tính và trả lãi tiền gửi không kỳ hạn CASA hàng tháng theo thông lệ Ngân hàng Việt Nam.
     * Áp dụng mức lãi suất 0.2%/năm tính theo số dư bình quân ngày (30 ngày/kỳ).
     */
    @PostMapping("/admin/casa-interest/accrue")
    public ResponseEntity<Map<String, Object>> accrueCasaInterest(
            @RequestParam(defaultValue = "0.2") double annualRate,
            @RequestParam(defaultValue = "30") int daysInPeriod) {

        List<Wallet> allWallets = walletPersistencePort.findAllWallets();
        int walletsAccrued = 0;
        long totalInterestPaid = 0;

        for (Wallet wallet : allWallets) {
            if (wallet.getStatus() != WalletStatus.ACTIVE) continue;
            long currentBal = wallet.getBalance().getAmount() != null ? wallet.getBalance().getAmount().longValue() : 0L;
            if (currentBal < 10000L) continue;

            long interest = (long) Math.round(currentBal * (annualRate / 100.0) * daysInPeriod / 365.0);
            if (interest >= 1L) {
                wallet.deposit(Money.of(interest, wallet.getBalance().getCurrency()));
                walletPersistencePort.saveWallet(wallet);
                totalInterestPaid += interest;
                walletsAccrued++;
            }
        }

        Map<String, Object> summary = new LinkedHashMap<>();
        summary.put("walletsAccrued", walletsAccrued);
        summary.put("totalInterestPaid", totalInterestPaid);
        summary.put("annualRatePercent", annualRate);
        summary.put("daysInPeriod", daysInPeriod);
        summary.put("currency", "VND");
        summary.put("standard", "Quy chế tính lãi tiền gửi không kỳ hạn theo ngày thực tế (365 ngày)");

        log.info("CASA interest batch completed: {} wallets accrued, total payout {} VND", walletsAccrued, totalInterestPaid);
        return ResponseEntity.ok(ok("Đã tính và trả lãi tiền gửi không kỳ hạn CASA thành công", summary));
    }

    /**
     * Tính năng 4.1 — Cấp hoặc thu hồi Hạn Mức Thấu Chi cho ví của khách hàng (Overdraft Limit).
     * Số dư khả dụng = balance + overdraftLimit; lãi vay thấu chi tính theo ngày trên phần dư nợ âm.
     */
    @PostMapping("/admin/accounts/{walletId}/overdraft-limit")
    public ResponseEntity<Map<String, Object>> setOverdraftLimit(
            @PathVariable String walletId,
            @RequestParam(defaultValue = "20000000") long limit) {

        // Hạn mức thấu chi cấp trên sổ người dùng: tối thiểu 0, tối đa 200 triệu VND
        final long OVERDRAFT_CAP = 200_000_000L;
        if (limit < 0 || limit > OVERDRAFT_CAP) {
            return ResponseEntity.badRequest().body(error(
                    "Hạn mức thấu chi phải nằm trong khoảng [0 - " + OVERDRAFT_CAP + "] VND, nhận được: " + limit));
        }

        Optional<Wallet> walletOpt = walletPersistencePort.findWalletById(walletId);
        if (walletOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error("Không tìm thấy ví: " + walletId));
        }

        Wallet wallet = walletOpt.get();
        wallet.setOverdraftLimit(limit);
        walletPersistencePort.saveWallet(wallet);

        java.math.BigDecimal newAvailable = wallet.getBalance().getAmount().add(java.math.BigDecimal.valueOf(limit));
        if (walletKafkaProducer != null) {
            try {
                String txId = "ODL-" + System.currentTimeMillis();
                WalletBalanceChangedPayload payload = new WalletBalanceChangedPayload(
                        wallet.getId(),
                        wallet.getBalance().getAmount(),
                        java.math.BigDecimal.valueOf(limit),
                        newAvailable,
                        wallet.getBalance().getCurrency(),
                        txId,
                        "OVERDRAFT_LIMIT"
                );
                walletKafkaProducer.publishBalanceChanged(payload);
                log.info("Published OVERDRAFT_LIMIT event to Kafka for walletId={}, limit={}, available={}",
                        walletId, limit, newAvailable);
            } catch (Exception e) {
                log.error("Failed to publish OVERDRAFT_LIMIT event to Kafka for walletId={}", walletId, e);
            }
        }

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("walletId", wallet.getId());
        data.put("ownerId", wallet.getOwnerId());
        data.put("overdraftLimit", limit);
        data.put("availableBalance", newAvailable);
        data.put("updatedAt", wallet.getUpdatedAt().toString());

        log.info("Admin set overdraft limit {} VND for wallet {}", limit, walletId);
        return ResponseEntity.ok(ok("Hạn mức thấu chi đã cập nhật thành công: " + limit + " VND", data));
    }

    /**
     * Tính năng 4.1 — Batch tính lãi vay thấu chi hàng ngày trên phần dư nợ âm.
     * Lãi trừ trực tiếp làm tăng dư nợ (balance giảm sâu hơn), không bị giới hạn bởi overdraftLimit.
     * Mặc định 16%/năm (≈ 0.0438%/ngày) — mức phổ biến của hạn mức thấu chi không bảo đảm tại Việt Nam.
     */
    @PostMapping("/admin/overdraft-interest/accrue")
    public ResponseEntity<Map<String, Object>> accrueOverdraftInterest(
            @RequestParam(defaultValue = "16.0") double annualRate,
            @RequestParam(defaultValue = "1") int daysInPeriod) {

        List<Wallet> allWallets = walletPersistencePort.findAllWallets();
        int walletsCharged = 0;
        long totalInterestCharged = 0;

        for (Wallet wallet : allWallets) {
            if (wallet.getStatus() != WalletStatus.ACTIVE) continue;
            long currentBal = wallet.getBalance().getAmount() != null ? wallet.getBalance().getAmount().longValue() : 0L;
            if (currentBal >= 0) continue; // chỉ tính lãi trên phần dư nợ âm

            long overdrawnDebt = -currentBal; // dư nợ thấu chi (số dương)
            long interest = (long) Math.round(overdrawnDebt * (annualRate / 100.0) * daysInPeriod / 365.0);
            if (interest >= 1L) {
                wallet.chargeOverdraftInterest(Money.of(interest, wallet.getBalance().getCurrency()));
                walletPersistencePort.saveWallet(wallet);
                totalInterestCharged += interest;
                walletsCharged++;
            }
        }

        Map<String, Object> summary = new LinkedHashMap<>();
        summary.put("walletsCharged", walletsCharged);
        summary.put("totalInterestCharged", totalInterestCharged);
        summary.put("annualRatePercent", annualRate);
        summary.put("daysInPeriod", daysInPeriod);
        summary.put("currency", "VND");
        summary.put("standard", "Lãi vay thấu chi tính trên phần dư nợ âm theo ngày thực tế (365 ngày)");

        log.info("Overdraft interest batch completed: {} wallets charged, total interest {} VND", walletsCharged, totalInterestCharged);
        return ResponseEntity.ok(ok("Đã tính và ghi nhận lãi vay thấu chi thành công", summary));
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> lookupIdentity(String field, String value) {
        try {
            String uri = "phone".equals(field)
                    ? "/api/v1/internal/users/by-phone?phoneNumber={value}"
                    : "/api/v1/internal/users/{value}";
            return identityClient.get().uri(uri, value).retrieve().body(Map.class);
        } catch (Exception e) {
            log.warn("Identity lookup failed ({}={}): {}", field, value, e.getMessage());
            return null;
        }
    }

    private Map<String, Object> walletData(Wallet wallet) {
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("id", wallet.getId());
        data.put("walletId", wallet.getId());
        data.put("ownerId", wallet.getOwnerId());
        data.put("userId", wallet.getOwnerId());
        data.put("balance", wallet.getBalance().getAmount());
        data.put("currency", wallet.getBalance().getCurrency());
        data.put("status", wallet.getStatus() != null ? wallet.getStatus().name() : "ACTIVE");
        data.put("reservedBalance", wallet.getReservedBalance());
        data.put("dailyLimit", wallet.getDailyLimit());
        data.put("overdraftLimit", wallet.getOverdraftLimit());
        // Số dư khả dụng = balance + overdraftLimit (tính năng 4.1 — thấu chi)
        java.math.BigDecimal overdraftDaily = wallet.getOverdraftLimit() != null
                ? java.math.BigDecimal.valueOf(wallet.getOverdraftLimit()) : java.math.BigDecimal.ZERO;
        data.put("availableBalance", wallet.getBalance().getAmount().add(overdraftDaily));
        return data;
    }

    private Map<String, Object> ok(String message, Object data) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("success", true);
        body.put("message", message);
        body.put("data", data);
        body.put("errorCode", null);
        return body;
    }

    private Map<String, Object> error(String message) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("success", false);
        body.put("message", message);
        body.put("data", null);
        body.put("errorCode", "WALLET_ERROR");
        return body;
    }

    private String asString(Object value) {
        return value != null ? String.valueOf(value) : null;
    }

    private String normalizePhone(String raw) {
        if (raw == null) return null;
        String digits = raw.replaceAll("[^0-9]", "");
        if (digits.startsWith("84") && digits.length() == 11) {
            return "0" + digits.substring(2);
        }
        if (digits.length() == 9 && !digits.startsWith("0")) {
            return "0" + digits;
        }
        return digits.isEmpty() ? raw.trim() : digits;
    }
}
