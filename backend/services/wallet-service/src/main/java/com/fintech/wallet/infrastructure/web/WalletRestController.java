package com.fintech.wallet.infrastructure.web;

import com.fintech.wallet.domain.model.Wallet;
import com.fintech.wallet.domain.port.out.WalletPersistencePort;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestClient;

import java.util.LinkedHashMap;
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

    public WalletRestController(WalletPersistencePort walletPersistencePort,
                                @Value("${identity.service.url:http://localhost:8081}") String identityServiceUrl) {
        this.walletPersistencePort = walletPersistencePort;
        this.identityClient = RestClient.builder().baseUrl(identityServiceUrl).build();
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
            @RequestParam(required = false) String phoneNumber) {

        Optional<Wallet> wallet = Optional.empty();
        Map<String, Object> identity = null;

        if (walletId != null && !walletId.isBlank()) {
            wallet = walletPersistencePort.findWalletById(walletId);
        } else if (phoneNumber != null && !phoneNumber.isBlank()) {
            identity = lookupIdentity("phone", phoneNumber);
            String ownerId = identity != null ? asString(identity.get("id")) : null;
            if (ownerId != null) {
                wallet = walletPersistencePort.findWalletByOwnerId(ownerId);
            }
        } else {
            return ResponseEntity.badRequest().body(error("Cần truyền walletId hoặc phoneNumber"));
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
            @RequestParam(defaultValue = "0") long amount,
            @RequestParam(defaultValue = "VND") String currency) {
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("type", type != null ? type : "TRANSFER");
        data.put("amount", amount);
        data.put("feeAmount", 0);
        data.put("totalAmount", amount);
        data.put("currency", currency);
        return ResponseEntity.ok(ok("Fee estimated", data));
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
        data.put("ownerId", wallet.getOwnerId());
        data.put("balance", wallet.getBalance().getAmount());
        data.put("currency", wallet.getBalance().getCurrency());
        data.put("status", wallet.getStatus() != null ? wallet.getStatus().name() : "ACTIVE");
        data.put("reservedBalance", wallet.getReservedBalance());
        data.put("dailyLimit", wallet.getDailyLimit());
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
}
