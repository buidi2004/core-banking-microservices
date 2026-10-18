package com.fintech.identity.service;

import com.fintech.identity.domain.entity.UserSessionEntity;
import com.fintech.identity.dto.SessionResponse;
import com.fintech.identity.repository.UserSessionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class SessionService {

    private final UserSessionRepository userSessionRepository;

    @Transactional(readOnly = true)
    public List<SessionResponse> getUserSessions(String userId, String currentDeviceId) {
        List<UserSessionEntity> sessions = userSessionRepository.findByUserIdAndIsRevokedFalse(userId);

        return sessions.stream()
                .map(s -> SessionResponse.builder()
                        .id(s.getId())
                        .deviceId(s.getDeviceId())
                        .deviceName(s.getDeviceName())
                        .deviceOs(s.getDeviceOs())
                        .ipAddress(s.getIpAddress())
                        .createdAt(s.getCreatedAt())
                        .lastAccessedAt(s.getLastAccessedAt())
                        .expiresAt(s.getExpiresAt())
                        .isCurrentDevice(s.getDeviceId().equals(currentDeviceId))
                        .build())
                .toList();
    }

    @Transactional
    public void revokeSession(String userId, String sessionId) {
        UserSessionEntity session = userSessionRepository.findById(sessionId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy phiên đăng nhập với ID: " + sessionId));

        if (!session.getUserId().equals(userId)) {
            throw new SecurityException("Không có quyền thu hồi phiên đăng nhập của người dùng khác.");
        }

        session.setIsRevoked(true);
        userSessionRepository.save(session);
        log.info("Đã thu hồi phiên đăng nhập sessionId={} của userId={}", sessionId, userId);
    }
}
