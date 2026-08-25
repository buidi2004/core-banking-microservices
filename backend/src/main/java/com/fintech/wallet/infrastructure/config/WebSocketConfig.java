package com.fintech.wallet.infrastructure.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    // ISSUE #11 fix: Configurable allowed origins. Production should override this property.
    // Mobile app (Expo tunnel) uses dynamic hostname, so we use wildcard * for development.
    @Value("${wallet.websocket.allowed-origins:*}")
    private String allowedOrigins;

    @Override
    public void configureMessageBroker(MessageBrokerRegistry config) {
        config.enableSimpleBroker("/topic");
        config.setApplicationDestinationPrefixes("/app");
    }

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        registry.addEndpoint("/ws")
                .setAllowedOriginPatterns("*")   // Dev: allow all (Expo tunnel)
                .withSockJS();
        // Also register a raw WebSocket endpoint for React Native (no SockJS)
        registry.addEndpoint("/ws-native")
                .setAllowedOriginPatterns("*");
    }
}
