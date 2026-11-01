package com.fintech.identity.security;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                .csrf(AbstractHttpConfigurer::disable)
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers(
                                "/api/v1/auth/**",
                                "/actuator/**",
                                "/v3/api-docs/**",
                                "/swagger-ui/**"
                        ).permitAll()
                        // Cho phép các endpoint downstream vì Gateway đã kiểm tra JWT và inject X-User-Id
                        .requestMatchers(
                                "/api/v1/users/**",
                                "/api/v1/kyc/**",
                                "/api/v1/sessions/**",
                                "/api/v1/staff/**",
                                "/api/v1/legal/**",
                                "/api/v1/referrals/**",
                                "/api/v1/devices/**",
                                "/api/v1/security/**",
                                "/api/v1/feedback/**",
                                // Service-to-service nội bộ (không route qua API Gateway)
                                "/api/v1/internal/**"
                        ).permitAll()
                        .anyRequest().authenticated()
                );

        return http.build();
    }
}
