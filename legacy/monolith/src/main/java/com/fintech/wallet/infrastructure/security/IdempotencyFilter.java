package com.fintech.wallet.infrastructure.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import org.springframework.web.util.ContentCachingRequestWrapper;
import org.springframework.web.util.ContentCachingResponseWrapper;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.TimeUnit;

@Component
public class IdempotencyFilter extends OncePerRequestFilter {

    private final RedisTemplate<String, Object> redisTemplate;
    private final ObjectMapper objectMapper;

    public IdempotencyFilter(RedisTemplate<String, Object> redisTemplate, ObjectMapper objectMapper) {
        this.redisTemplate = redisTemplate;
        this.objectMapper = objectMapper;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {

        String idempotencyKey = request.getHeader("Idempotency-Key");

        // Only apply idempotency for POST requests with the header
        if (idempotencyKey == null || idempotencyKey.isBlank() || !request.getMethod().equalsIgnoreCase("POST")) {
            filterChain.doFilter(request, response);
            return;
        }

        String cacheKey = "idempotency:key:" + idempotencyKey;

        // Check if request is already processed
        Object cachedObj = redisTemplate.opsForValue().get(cacheKey);
        if (cachedObj != null) {
            CachedResponse cachedResponse = objectMapper.convertValue(cachedObj, CachedResponse.class);
            
            response.setStatus(cachedResponse.getStatus());
            if (cachedResponse.getContentType() != null) {
                response.setContentType(cachedResponse.getContentType());
            }
            if (cachedResponse.getHeaders() != null) {
                for (Map.Entry<String, String> entry : cachedResponse.getHeaders().entrySet()) {
                    response.setHeader(entry.getKey(), entry.getValue());
                }
            }
            if (cachedResponse.getBody() != null) {
                response.getOutputStream().write(cachedResponse.getBody());
            }
            return;
        }

        // Lock to avoid race conditions on the same key processing at the identical millisecond
        Boolean isFirst = redisTemplate.opsForValue().setIfAbsent(cacheKey + ":lock", "locked", 10, TimeUnit.SECONDS);
        if (Boolean.FALSE.equals(isFirst)) {
            response.setStatus(409); // Conflict - request is currently being processed
            response.getWriter().write("{\"code\":409,\"message\":\"Duplicate request is currently processing\"}");
            return;
        }

        ContentCachingRequestWrapper requestWrapper = new ContentCachingRequestWrapper(request);
        ContentCachingResponseWrapper responseWrapper = new ContentCachingResponseWrapper(response);

        try {
            filterChain.doFilter(requestWrapper, responseWrapper);

            // Only cache successful or non-server-error responses
            if (responseWrapper.getStatus() >= 200 && responseWrapper.getStatus() < 500) {
                Map<String, String> headers = new HashMap<>();
                for (String headerName : responseWrapper.getHeaderNames()) {
                    headers.put(headerName, responseWrapper.getHeader(headerName));
                }

                CachedResponse cachedResponse = new CachedResponse(
                        responseWrapper.getStatus(),
                        responseWrapper.getContentType(),
                        headers,
                        responseWrapper.getContentAsByteArray()
                );

                redisTemplate.opsForValue().set(cacheKey, cachedResponse, 24, TimeUnit.HOURS);
            }
        } finally {
            redisTemplate.delete(cacheKey + ":lock");
            responseWrapper.copyBodyToResponse();
        }
    }
}
