package com.fintech.gateway;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.web.reactive.error.ErrorWebExceptionHandler;
import org.springframework.core.annotation.Order;
import org.springframework.core.io.buffer.DataBuffer;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.server.reactive.ServerHttpResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;

@Component
@Order(-2)
public class GatewayGlobalExceptionHandler implements ErrorWebExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GatewayGlobalExceptionHandler.class);
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    public Mono<Void> handle(ServerWebExchange exchange, Throwable ex) {
        ServerHttpResponse response = exchange.getResponse();

        if (response.isCommitted()) {
            return Mono.error(ex);
        }

        HttpStatus status = HttpStatus.INTERNAL_SERVER_ERROR;
        String errorCode = "INTERNAL_SERVER_ERROR";
        String message = "Đã xảy ra sự cố kết nối tới dịch vụ Core Banking";

        if (ex instanceof ResponseStatusException rse) {
            status = HttpStatus.resolve(rse.getStatusCode().value());
            if (status == null) status = HttpStatus.INTERNAL_SERVER_ERROR;
            if (status == HttpStatus.NOT_FOUND) {
                errorCode = "NOT_FOUND";
                message = "Đường dẫn yêu cầu không tồn tại";
            } else if (status == HttpStatus.UNAUTHORIZED) {
                errorCode = "UNAUTHORIZED";
                message = "Yêu cầu chưa được xác thực";
            } else if (status == HttpStatus.FORBIDDEN) {
                errorCode = "FORBIDDEN";
                message = "Bạn không có quyền truy cập tài nguyên này";
            } else if (status == HttpStatus.SERVICE_UNAVAILABLE) {
                errorCode = "SERVICE_UNAVAILABLE";
                message = "Dịch vụ phía sau tạm thời không khả dụng, vui lòng thử lại sau";
            }
        } else if (ex instanceof java.net.ConnectException) {
            status = HttpStatus.SERVICE_UNAVAILABLE;
            errorCode = "SERVICE_UNAVAILABLE";
            message = "Không thể kết nối đến máy chủ xử lý giao dịch";
        } else if (ex.getMessage() != null && ex.getMessage().toLowerCase().contains("connection refused")) {
            status = HttpStatus.SERVICE_UNAVAILABLE;
            errorCode = "SERVICE_UNAVAILABLE";
            message = "Máy chủ dịch vụ đang bảo trì hoặc khởi động lại, vui lòng thử lại sau";
        }

        log.warn("Gateway error intercepted: path={} status={} error={}",
                exchange.getRequest().getURI().getPath(), status, ex.getMessage());

        response.setStatusCode(status);
        response.getHeaders().setContentType(MediaType.APPLICATION_JSON);

        Map<String, Object> body = new LinkedHashMap<>();
        body.put("success", false);
        body.put("errorCode", errorCode);
        body.put("error", errorCode);
        body.put("message", message);
        body.put("data", null);

        byte[] bytes;
        try {
            bytes = objectMapper.writeValueAsBytes(body);
        } catch (JsonProcessingException e) {
            bytes = ("{\"success\":false,\"errorCode\":\"" + errorCode + "\",\"message\":\"" + message + "\"}").getBytes(StandardCharsets.UTF_8);
        }

        DataBuffer buffer = response.bufferFactory().wrap(bytes);
        return response.writeWith(Mono.just(buffer));
    }
}

