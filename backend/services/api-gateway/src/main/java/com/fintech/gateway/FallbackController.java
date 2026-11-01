package com.fintech.gateway;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Mono;

import java.util.Map;

@RestController
@RequestMapping("/fallback")
public class FallbackController {

    @RequestMapping("/identity")
    public Mono<ResponseEntity<Map<String, Object>>> identityFallback() {
        return Mono.just(ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).body(Map.of(
                "success", false,
                "error", "SERVICE_UNAVAILABLE",
                "message", "Dịch vụ định danh (Identity Service) tạm thời gián đoạn, vui lòng thử lại sau"
        )));
    }

    @RequestMapping("/notification")
    public Mono<ResponseEntity<Map<String, Object>>> notificationFallback() {
        return Mono.just(ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).body(Map.of(
                "success", false,
                "error", "SERVICE_UNAVAILABLE",
                "message", "Dịch vụ thông báo (Notification Service) tạm thời gián đoạn, vui lòng thử lại sau"
        )));
    }
}

