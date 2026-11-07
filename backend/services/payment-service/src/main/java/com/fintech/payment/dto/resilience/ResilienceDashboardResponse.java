package com.fintech.payment.dto.resilience;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ResilienceDashboardResponse {

    private String overallStatus; // HEALTHY, DEGRADED, UNHEALTHY
    private Instant timestamp;

    private DatabaseMetrics database;
    private RedisMetrics redis;
    private MessagingMetrics messaging;
    private GrpcMetrics grpc;
    private Map<String, ServiceStatus> microservices;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class DatabaseMetrics {
        private String status; // UP, DOWN
        private String poolName;
        private int activeConnections;
        private int idleConnections;
        private int totalConnections;
        private int threadsAwaitingConnection;
        private long connectionTimeoutMs;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class RedisMetrics {
        private String status; // UP, DOWN
        private long latencyMs;
        private String mode; // STANDALONE, CLUSTER
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class MessagingMetrics {
        private String rabbitMqStatus; // UP, DOWN
        private String rabbitMqExchange;
        private String kafkaStatus; // UP, DOWN
        private String kafkaLifecycleTopic;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class GrpcMetrics {
        private String status; // UP, DOWN
        private String targetService;
        private String port;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ServiceStatus {
        private String name;
        private String status; // UP, DEGRADED, DOWN
        private String uri;
        private String note;
    }
}

