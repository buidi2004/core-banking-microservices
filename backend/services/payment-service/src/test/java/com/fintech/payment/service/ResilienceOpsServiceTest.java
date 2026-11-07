package com.fintech.payment.service;

import com.fintech.payment.dto.resilience.ResilienceDashboardResponse;
import com.fintech.payment.grpc.WalletGrpcClient;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.amqp.rabbit.connection.ConnectionFactory;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.data.redis.connection.RedisConnection;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.kafka.core.KafkaTemplate;

import javax.sql.DataSource;
import java.sql.Connection;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ResilienceOpsServiceTest {

    @Mock
    private DataSource dataSource;

    @Mock
    private Connection dbConnection;

    @Mock
    private StringRedisTemplate stringRedisTemplate;

    @Mock
    private RedisConnectionFactory redisConnectionFactory;

    @Mock
    private RedisConnection redisConnection;

    @Mock
    private RabbitTemplate rabbitTemplate;

    @Mock
    private ConnectionFactory rabbitConnectionFactory;

    @Mock
    private org.springframework.amqp.rabbit.connection.Connection rabbitConnection;

    @Mock
    private KafkaTemplate<String, Object> kafkaTemplate;

    @Mock
    private WalletGrpcClient walletGrpcClient;

    @Test
    @DisplayName("Dashboard returns HEALTHY when all components are UP")
    void shouldReturnHealthyWhenAllComponentsUp() throws Exception {
        when(dataSource.getConnection()).thenReturn(dbConnection);
        when(dbConnection.isValid(2)).thenReturn(true);

        when(stringRedisTemplate.getConnectionFactory()).thenReturn(redisConnectionFactory);
        when(redisConnectionFactory.getConnection()).thenReturn(redisConnection);
        when(redisConnection.ping()).thenReturn("PONG");

        when(rabbitTemplate.getConnectionFactory()).thenReturn(rabbitConnectionFactory);
        when(rabbitConnectionFactory.createConnection()).thenReturn(rabbitConnection);
        when(rabbitConnection.isOpen()).thenReturn(true);

        ResilienceOpsService service = new ResilienceOpsService(
                dataSource, stringRedisTemplate, rabbitTemplate, kafkaTemplate, walletGrpcClient);

        ResilienceDashboardResponse response = service.getResilienceDashboard();

        assertThat(response).isNotNull();
        assertThat(response.getOverallStatus()).isEqualTo("HEALTHY");
        assertThat(response.getDatabase().getStatus()).isEqualTo("UP");
        assertThat(response.getRedis().getStatus()).isEqualTo("UP");
        assertThat(response.getMessaging().getRabbitMqStatus()).isEqualTo("UP");
        assertThat(response.getMessaging().getKafkaStatus()).isEqualTo("UP");
        assertThat(response.getGrpc().getStatus()).isEqualTo("UP");
        assertThat(response.getMicroservices()).hasSize(6);
    }

    @Test
    @DisplayName("Dashboard returns UNHEALTHY when DB or Redis is DOWN")
    void shouldReturnUnhealthyWhenDatabaseFails() throws Exception {
        when(dataSource.getConnection()).thenThrow(new RuntimeException("DB Connection timeout"));

        ResilienceOpsService service = new ResilienceOpsService(
                dataSource, null, null, null, null);

        ResilienceDashboardResponse response = service.getResilienceDashboard();

        assertThat(response).isNotNull();
        assertThat(response.getOverallStatus()).isEqualTo("UNHEALTHY");
        assertThat(response.getDatabase().getStatus()).isEqualTo("DOWN");
        assertThat(response.getRedis().getStatus()).isEqualTo("DOWN");
    }
}

