package com.fintech.wallet.domain.port.in;

import com.fintech.wallet.domain.model.UserSession;

import java.util.List;

/**
 * Input Port: session management operations exposed to the presentation layer.
 */
public interface SessionUseCase {

    UserSession createSession(String userId, String deviceInfo, String ipAddress);

    List<UserSession> getActiveSessions(String userId);

    void revokeSession(String userId, String sessionId);

    void revokeAllSessions(String userId);
}
