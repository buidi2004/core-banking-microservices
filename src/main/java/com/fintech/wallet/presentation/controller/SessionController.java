package com.fintech.wallet.presentation.controller;

import com.fintech.wallet.domain.model.UserSession;
import com.fintech.wallet.domain.port.in.SessionUseCase;
import com.fintech.wallet.presentation.response.ApiResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/account/sessions")
public class SessionController {

    private final SessionUseCase sessionUseCase;

    public SessionController(SessionUseCase sessionUseCase) {
        this.sessionUseCase = sessionUseCase;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<UserSession>>> getActiveSessions(Authentication auth) {
        String userId = auth.getName();
        List<UserSession> sessions = sessionUseCase.getActiveSessions(userId);
        return ResponseEntity.ok(ApiResponse.success("Active sessions retrieved", sessions));
    }

    @DeleteMapping("/{sessionId}")
    public ResponseEntity<ApiResponse<Void>> revokeSession(
            Authentication auth, @PathVariable String sessionId) {
        String userId = auth.getName();
        sessionUseCase.revokeSession(userId, sessionId);
        return ResponseEntity.ok(ApiResponse.success("Session revoked successfully", null));
    }

    @DeleteMapping
    public ResponseEntity<ApiResponse<Void>> revokeAllSessions(Authentication auth) {
        String userId = auth.getName();
        sessionUseCase.revokeAllSessions(userId);
        return ResponseEntity.ok(ApiResponse.success("All active sessions revoked successfully", null));
    }
}
