package com.fintech.wallet.infrastructure.grpc;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Cấu hình gRPC server cho Wallet Service.
 * - Port mặc định: 9090 (config trong application-wallet.yml)
 * - Production: cấu hình certificate qua grpc.server.ssl.keyCertChainFile / grpc.server.ssl.keyFile
 */
@Configuration
public class GrpcServerSecurityConfig {

    @Bean
    public net.devh.boot.grpc.server.security.SecurityManager securityManager() {
        return net.devh.boot.grpc.server.security.SecurityManager.create();
    }
}
