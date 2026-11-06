package com.fintech.identity.controller;

import com.fintech.identity.domain.entity.UserEntity;
import com.fintech.identity.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * API nội bộ service-to-service (wallet-service tra cứu chủ ví theo phone/userId).
 * Không route qua API Gateway cho client bên ngoài.
 */
@RestController
@RequestMapping("/api/v1/internal/users")
@RequiredArgsConstructor
public class InternalUserController {

    private final UserRepository userRepository;

    @GetMapping("/by-phone")
    public ResponseEntity<Map<String, Object>> byPhone(@RequestParam String phoneNumber) {
        String cleanPhone = normalizePhone(phoneNumber);
        return userRepository.findByPhoneNumber(cleanPhone)
                .or(() -> (cleanPhone != null && !cleanPhone.equals(phoneNumber)) ? userRepository.findByPhoneNumber(phoneNumber) : java.util.Optional.empty())
                .or(() -> userRepository.findByAccountAlias(phoneNumber.trim().toUpperCase()))
                .map(user -> ResponseEntity.ok(view(user)))
                .orElseGet(() -> ResponseEntity.status(404)
                        .body(Map.of("error", "USER_NOT_FOUND", "phoneNumber", phoneNumber)));
    }

    @GetMapping("/by-alias")
    public ResponseEntity<Map<String, Object>> byAlias(@RequestParam String alias) {
        return userRepository.findByAccountAlias(alias.trim().toUpperCase())
                .map(user -> ResponseEntity.ok(view(user)))
                .orElseGet(() -> ResponseEntity.status(404)
                        .body(Map.of("error", "USER_NOT_FOUND", "alias", alias)));
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

    @GetMapping("/{id}")
    public ResponseEntity<Map<String, Object>> byId(@PathVariable String id) {
        return userRepository.findById(id)
                .map(user -> ResponseEntity.ok(view(user)))
                .orElseGet(() -> ResponseEntity.status(404)
                        .body(Map.of("error", "USER_NOT_FOUND", "id", id)));
    }

    private Map<String, Object> view(UserEntity user) {
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("id", user.getId());
        data.put("phoneNumber", user.getPhoneNumber());
        data.put("accountAlias", user.getAccountAlias());
        data.put("fullName", user.getFullName());
        data.put("status", user.getStatus());
        data.put("kycTier", user.getKycTier());
        return data;
    }
}
