package com.fintech.wallet.infrastructure.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.Message;
import org.springframework.messaging.MessageChannel;
import org.springframework.messaging.simp.config.ChannelRegistration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.messaging.simp.stomp.StompCommand;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.messaging.support.ChannelInterceptor;
import org.springframework.messaging.support.MessageHeaderAccessor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.util.StringUtils;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

import com.fintech.wallet.infrastructure.security.JwtTokenProvider;
import com.fintech.wallet.domain.port.out.TokenBlacklistPort;
import com.fintech.wallet.domain.port.in.SessionManagementUseCase;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.Collections;
import java.util.List;

@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    private final JwtTokenProvider tokenProvider;
    private final TokenBlacklistPort tokenBlacklistPort;
    private final SessionManagementUseCase sessionManagementUseCase;

    public WebSocketConfig(JwtTokenProvider tokenProvider,
                           @Autowired(required = false) TokenBlacklistPort tokenBlacklistPort,
                           SessionManagementUseCase sessionManagementUseCase) {
        this.tokenProvider = tokenProvider;
        this.tokenBlacklistPort = tokenBlacklistPort;
        this.sessionManagementUseCase = sessionManagementUseCase;
    }

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

    @Override
    public void configureClientInboundChannel(ChannelRegistration registration) {
        registration.interceptors(new ChannelInterceptor() {
            @Override
            public Message<?> preSend(Message<?> message, MessageChannel channel) {
                StompHeaderAccessor accessor = MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);
                if (accessor != null && StompCommand.CONNECT.equals(accessor.getCommand())) {
                    List<String> authorization = accessor.getNativeHeader("Authorization");
                    if (authorization != null && !authorization.isEmpty()) {
                        String bearerToken = authorization.get(0);
                        if (StringUtils.hasText(bearerToken) && bearerToken.startsWith("Bearer ")) {
                            String jwt = bearerToken.substring(7);
                            if (tokenProvider.validateToken(jwt)) {
                                if (tokenBlacklistPort != null && tokenBlacklistPort.isBlacklisted(jwt)) {
                                    throw new org.springframework.messaging.MessageDeliveryException("Token is blacklisted");
                                }
                                
                                String userId = tokenProvider.getUserIdFromToken(jwt);
                                String tokenType = tokenProvider.getTokenType(jwt);
                                String deviceId = tokenProvider.getDeviceIdFromToken(jwt);
                                
                                if ("ACCESS".equals(tokenType)) {
                                    boolean isSessionValid = sessionManagementUseCase.validateSession(userId, deviceId).isPresent();
                                    if (!isSessionValid) {
                                        throw new org.springframework.messaging.MessageDeliveryException("Session expired or revoked");
                                    }
                                    
                                    UsernamePasswordAuthenticationToken auth = new UsernamePasswordAuthenticationToken(
                                            userId, null, Collections.singletonList(new SimpleGrantedAuthority("ROLE_USER"))
                                    );
                                    accessor.setUser(auth);
                                }
                            }
                        }
                    }
                }
                return message;
            }
        });
    }
}
