package com.fintech.gateway;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Mono;

import java.util.LinkedHashMap;
import java.util.Map;

@RestController
@RequestMapping("/fallback")
public class FallbackController {

    private Map<String, Object> fallbackBody(String serviceName) {
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("success", false);
        map.put("error", "SERVICE_UNAVAILABLE");
        map.put("errorCode", "SERVICE_UNAVAILABLE");
        map.put("message", serviceName + " tạm thời gián đoạn, vui lòng thử lại sau.");
        map.put("data", null);
        return map;
    }

    @RequestMapping("/identity")
    public Mono<ResponseEntity<Map<String, Object>>> identityFallback() {
        return Mono.just(ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                .body(fallbackBody("Dịch vụ định danh (Identity Service)")));
    }

    @RequestMapping("/notification")
    public Mono<ResponseEntity<Map<String, Object>>> notificationFallback() {
        return Mono.just(ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                .body(fallbackBody("Dịch vụ thông báo (Notification Service)")));
    }

    @RequestMapping("/wallet")
    public Mono<ResponseEntity<Map<String, Object>>> walletFallback() {
        return Mono.just(ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                .body(fallbackBody("Dịch vụ tài khoản ví (Wallet Service)")));
    }

    @RequestMapping("/payment")
    public Mono<ResponseEntity<Map<String, Object>>> paymentFallback() {
        return Mono.just(ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                .body(fallbackBody("Dịch vụ thanh toán (Payment Service)")));
    }

    @RequestMapping("/ledger")
    public Mono<ResponseEntity<Map<String, Object>>> ledgerFallback() {
        return Mono.just(ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                .body(fallbackBody("Dịch vụ sổ cái tài chính (Ledger Service)")));
    }

    @RequestMapping("/default")
    public Mono<ResponseEntity<Map<String, Object>>> defaultFallback() {
        return Mono.just(ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                .body(fallbackBody("Dịch vụ hệ thống Core Banking")));
    }
}
