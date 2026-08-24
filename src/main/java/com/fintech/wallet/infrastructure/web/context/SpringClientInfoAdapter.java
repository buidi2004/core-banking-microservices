package com.fintech.wallet.infrastructure.web.context;

import com.fintech.wallet.domain.port.out.ClientInfoPort;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.stereotype.Component;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

@Component
public class SpringClientInfoAdapter implements ClientInfoPort {

    @Override
    public String getClientIp() {
        HttpServletRequest request = getCurrentHttpRequest();
        if (request != null) {
            String ip = request.getHeader("X-Forwarded-For");
            if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
                ip = request.getRemoteAddr();
            }
            return ip != null ? ip : "SYSTEM";
        }
        return "SYSTEM"; // When called outside an HTTP request context (e.g. background job)
    }

    @Override
    public String getDeviceId() {
        HttpServletRequest request = getCurrentHttpRequest();
        if (request != null) {
            String deviceId = request.getHeader("X-Device-Id");
            if (deviceId == null || deviceId.isBlank()) {
                deviceId = request.getHeader("User-Agent");
            }
            return (deviceId != null && !deviceId.isBlank()) ? deviceId : "UNKNOWN_DEVICE";
        }
        return "SYSTEM_DEVICE";
    }

    private HttpServletRequest getCurrentHttpRequest() {
        ServletRequestAttributes attributes = (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
        return (attributes != null) ? attributes.getRequest() : null;
    }
}
