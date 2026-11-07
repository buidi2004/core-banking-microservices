package com.fintech.payment.service;

import com.fintech.payment.dto.resilience.ResilienceDashboardResponse;
import com.fintech.payment.dto.resilience.ResilienceDashboardResponse.*;
import com.fintech.payment.grpc.WalletGrpcClient;
import com.zaxxer.hikari.HikariDataSource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

import javax.sql.DataSource;
import java.sql.Connection;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;

@Slf4j
@Service
public class ResilienceOpsService {

    private final DataSource dataSource;
    private final StringRedisTemplate stringRedisTemplate;
    private final RabbitTemplate rabbitTemplate;
    private final KafkaTemplate<String, Object> kafkaTemplate;
    private final WalletGrpcClient walletGrpcClient;

    public ResilienceOpsService(
            @Autowired(required = false) DataSource dataSource,
            @Autowired(required = false) StringRedisTemplate stringRedisTemplate,
            @Autowired(required = false) RabbitTemplate rabbitTemplate,
            @Autowired(required = false) KafkaTemplate<String, Object> kafkaTemplate,
            @Autowired(required = false) WalletGrpcClient walletGrpcClient) {
        this.dataSource = dataSource;
        this.stringRedisTemplate = stringRedisTemplate;
        this.rabbitTemplate = rabbitTemplate;
        this.kafkaTemplate = kafkaTemplate;
        this.walletGrpcClient = walletGrpcClient;
    }

    public ResilienceDashboardResponse getResilienceDashboard() {
        DatabaseMetrics dbMetrics = checkDatabase();
        RedisMetrics redisMetrics = checkRedis();
        MessagingMetrics msgMetrics = checkMessaging();
        GrpcMetrics grpcMetrics = checkGrpc();
        Map<String, ServiceStatus> microservices = collectMicroservicesStatus(dbMetrics, redisMetrics, msgMetrics, grpcMetrics);

        boolean anyDown = "DOWN".equals(dbMetrics.getStatus()) || "DOWN".equals(redisMetrics.getStatus()) || "DOWN".equals(msgMetrics.getRabbitMqStatus());
        boolean anyDegraded = "DOWN".equals(msgMetrics.getKafkaStatus()) || "DOWN".equals(grpcMetrics.getStatus());

        String overallStatus = anyDown ? "UNHEALTHY" : (anyDegraded ? "DEGRADED" : "HEALTHY");

        return ResilienceDashboardResponse.builder()
                .overallStatus(overallStatus)
                .timestamp(Instant.now())
                .database(dbMetrics)
                .redis(redisMetrics)
                .messaging(msgMetrics)
                .grpc(grpcMetrics)
                .microservices(microservices)
                .build();
    }

    private DatabaseMetrics checkDatabase() {
        DatabaseMetrics.DatabaseMetricsBuilder builder = DatabaseMetrics.builder()
                .poolName("HikariPool-PaymentDB")
                .status("DOWN")
                .activeConnections(0)
                .idleConnections(0)
                .totalConnections(0)
                .threadsAwaitingConnection(0)
                .connectionTimeoutMs(30000);

        if (dataSource == null) {
            return builder.build();
        }

        try {
            if (dataSource instanceof HikariDataSource hikari) {
                builder.poolName(hikari.getPoolName());
                builder.connectionTimeoutMs(hikari.getConnectionTimeout());
                if (hikari.getHikariPoolMXBean() != null) {
                    builder.activeConnections(hikari.getHikariPoolMXBean().getActiveConnections());
                    builder.idleConnections(hikari.getHikariPoolMXBean().getIdleConnections());
                    builder.totalConnections(hikari.getHikariPoolMXBean().getTotalConnections());
                    builder.threadsAwaitingConnection(hikari.getHikariPoolMXBean().getThreadsAwaitingConnection());
                }
            }
            try (Connection conn = dataSource.getConnection()) {
                if (conn.isValid(2)) {
                    builder.status("UP");
                }
            }
        } catch (Exception e) {
            log.warn("Database health check failed: {}", e.getMessage());
            builder.status("DOWN");
        }
        return builder.build();
    }

    private RedisMetrics checkRedis() {
        RedisMetrics.RedisMetricsBuilder builder = RedisMetrics.builder()
                .status("DOWN")
                .latencyMs(-1)
                .mode("STANDALONE");

        if (stringRedisTemplate == null) {
            return builder.build();
        }

        try {
            long start = System.currentTimeMillis();
            String pingRes = stringRedisTemplate.getConnectionFactory().getConnection().ping();
            long latency = System.currentTimeMillis() - start;
            if ("PONG".equalsIgnoreCase(pingRes)) {
                builder.status("UP").latencyMs(latency);
            }
        } catch (Exception e) {
            log.warn("Redis health check failed: {}", e.getMessage());
            builder.status("DOWN");
        }
        return builder.build();
    }

    private MessagingMetrics checkMessaging() {
        MessagingMetrics.MessagingMetricsBuilder builder = MessagingMetrics.builder()
                .rabbitMqStatus("DOWN")
                .rabbitMqExchange("wallet.transaction.events")
                .kafkaStatus("DOWN")
                .kafkaLifecycleTopic("banking.payment.transaction-lifecycle.v1");

        if (rabbitTemplate != null) {
            try {
                var conn = rabbitTemplate.getConnectionFactory().createConnection();
                if (conn.isOpen()) {
                    builder.rabbitMqStatus("UP");
                    conn.close();
                }
            } catch (Exception e) {
                log.warn("RabbitMQ health check failed: {}", e.getMessage());
            }
        }

        if (kafkaTemplate != null) {
            builder.kafkaStatus("UP");
        }

        return builder.build();
    }

    private GrpcMetrics checkGrpc() {
        GrpcMetrics.GrpcMetricsBuilder builder = GrpcMetrics.builder()
                .status("DOWN")
                .targetService("wallet-service")
                .port("9090");

        if (walletGrpcClient != null) {
            builder.status("UP");
        }
        return builder.build();
    }

    private Map<String, ServiceStatus> collectMicroservicesStatus(
            DatabaseMetrics db, RedisMetrics redis, MessagingMetrics msg, GrpcMetrics grpc) {
        Map<String, ServiceStatus> map = new LinkedHashMap<>();

        map.put("api-gateway", ServiceStatus.builder()
                .name("API Gateway")
                .status("UP")
                .uri("http://api-gateway:8080")
                .note("Spring Cloud Gateway, JWT filter & rate limit")
                .build());

        map.put("identity-service", ServiceStatus.builder()
                .name("Identity Service")
                .status("UP")
                .uri("http://identity-service:8081")
                .note("Auth, JWT, BCrypt PIN, KYC, Staff IAM")
                .build());

        map.put("wallet-service", ServiceStatus.builder()
                .name("Wallet Service")
                .status("UP".equals(grpc.getStatus()) ? "UP" : "DEGRADED")
                .uri("http://wallet-service:8082 / gRPC :9090")
                .note("Số dư, Pessimistic lock, Hạn mức")
                .build());

        map.put("payment-service", ServiceStatus.builder()
                .name("Payment Service")
                .status("UP".equals(db.getStatus()) ? "UP" : "DOWN")
                .uri("http://payment-service:8083")
                .note("Payment Saga, Outbox Relay, Tra soát, Maker-Checker")
                .build());

        map.put("ledger-service", ServiceStatus.builder()
                .name("General Ledger Service")
                .status("UP")
                .uri("http://ledger-service:8084")
                .note("Sổ cái kép, JournalEntry & Posting, EOD batches")
                .build());

        map.put("notification-service", ServiceStatus.builder()
                .name("Notification Service")
                .status("UP".equals(msg.getRabbitMqStatus()) ? "UP" : "DEGRADED")
                .uri("http://notification-service:8085")
                .note("STOMP WebSocket, FCM, SMS Banking, DLQ")
                .build());

        return map;
    }
}

