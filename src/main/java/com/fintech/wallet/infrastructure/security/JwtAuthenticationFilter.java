package com.fintech.wallet.infrastructure.security;

import com.fintech.wallet.domain.port.in.SessionManagementUseCase;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Collections;

@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtTokenProvider tokenProvider;
    private final com.fintech.wallet.domain.port.out.TokenBlacklistPort tokenBlacklistPort;
    private final SessionManagementUseCase sessionManagementUseCase;

    public JwtAuthenticationFilter(JwtTokenProvider tokenProvider,
                                   @org.springframework.beans.factory.annotation.Autowired(required = false)
                                   com.fintech.wallet.domain.port.out.TokenBlacklistPort tokenBlacklistPort,
                                   SessionManagementUseCase sessionManagementUseCase) {
        this.tokenProvider = tokenProvider;
        this.tokenBlacklistPort = tokenBlacklistPort;
        this.sessionManagementUseCase = sessionManagementUseCase;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        String jwt = getJwtFromRequest(request);

        if (StringUtils.hasText(jwt) && tokenProvider.validateToken(jwt)) {
            if (tokenBlacklistPort != null && tokenBlacklistPort.isBlacklisted(jwt)) {
                filterChain.doFilter(request, response);
                return;
            }

            String userId = tokenProvider.getUserIdFromToken(jwt);
            String tokenType = tokenProvider.getTokenType(jwt);
            String deviceId = tokenProvider.getDeviceIdFromToken(jwt);

            if ("ACCESS".equals(tokenType)) {
                // Check database session deep validation
                boolean isSessionValid = sessionManagementUseCase.validateSession(userId, deviceId).isPresent();
                if (!isSessionValid) {
                    response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Session expired or revoked");
                    return;
                }

                UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(
                        userId, null, Collections.singletonList(new SimpleGrantedAuthority("ROLE_USER"))
                );
                authentication.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
                SecurityContextHolder.getContext().setAuthentication(authentication);
            }
        }

        filterChain.doFilter(request, response);
    }

    private String getJwtFromRequest(HttpServletRequest request) {
        String bearerToken = request.getHeader("Authorization");
        if (StringUtils.hasText(bearerToken) && bearerToken.startsWith("Bearer ")) {
            return bearerToken.substring(7);
        }
        return null;
    }
}
