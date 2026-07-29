package com.fintech.wallet.infrastructure.security;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

@Component
public class RateLimitingInterceptor implements HandlerInterceptor {

    private final RedisRateLimiter rateLimiter;

    public RateLimitingInterceptor(RedisRateLimiter rateLimiter) {
        this.rateLimiter = rateLimiter;
    }

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws Exception {
        String clientIp = getClientIp(request);
        String uri = request.getRequestURI();
        String rateKey = "rate:uri:" + uri + ":" + clientIp;

        // Allow max 20 requests per minute per IP for sensitive endpoints
        if (!rateLimiter.isAllowed(rateKey, 20, 60)) {
            response.setStatus(429);
            response.setContentType("application/json");
            response.getWriter().write("{\"code\":429,\"message\":\"Too many requests. Please slow down.\",\"data\":null,\"timestamp\":\"" + java.time.Instant.now() + "\"}");
            return false;
        }
        return true;
    }

    private String getClientIp(HttpServletRequest request) {
        String xf = request.getHeader("X-Forwarded-For");
        if (xf != null && !xf.isBlank()) {
            return xf.split(",")[0].trim();
        }
        return request.getRemoteAddr() != null ? request.getRemoteAddr() : "unknown";
    }
}
