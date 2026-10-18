package com.fintech.wallet.application.service;

import org.springframework.beans.factory.annotation.Autowired;

import org.springframework.beans.factory.annotation.Autowired;

import com.fintech.wallet.domain.exception.InvalidPinException;
import com.fintech.wallet.domain.model.KycStatus;
import com.fintech.wallet.domain.model.User;
import com.fintech.wallet.domain.model.UserKyc;
import com.fintech.wallet.domain.port.in.KycUseCase;
import com.fintech.wallet.domain.port.in.PinUseCase;
import com.fintech.wallet.domain.model.AuditLog;
import com.fintech.wallet.domain.port.out.AuditLogPersistencePort;
import com.fintech.wallet.domain.port.out.ClientInfoPort;
import com.fintech.wallet.domain.port.out.KycPersistencePort;
import com.fintech.wallet.domain.port.out.UserPersistencePort;
import com.fintech.wallet.infrastructure.security.JwtTokenProvider;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class UserService implements PinUseCase, KycUseCase {

    private static final Logger log = LoggerFactory.getLogger(UserService.class);

    private final UserPersistencePort userPersistencePort;
    private final KycPersistencePort kycPersistencePort;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider tokenProvider;
    private final AuditLogPersistencePort auditLogPersistencePort;
    private final ClientInfoPort clientInfoPort;

    @Autowired
    public UserService(UserPersistencePort userPersistencePort,
                       KycPersistencePort kycPersistencePort,
                       PasswordEncoder passwordEncoder,
                       JwtTokenProvider tokenProvider,
                       AuditLogPersistencePort auditLogPersistencePort,
                       ClientInfoPort clientInfoPort) {
        this.userPersistencePort = userPersistencePort;
        this.kycPersistencePort = kycPersistencePort;
        this.passwordEncoder = passwordEncoder;
        this.tokenProvider = tokenProvider;
        this.auditLogPersistencePort = auditLogPersistencePort;
        this.clientInfoPort = clientInfoPort;
    }

    public UserService(UserPersistencePort userPersistencePort,
                       KycPersistencePort kycPersistencePort,
                       PasswordEncoder passwordEncoder,
                       JwtTokenProvider tokenProvider) {
        this(userPersistencePort, kycPersistencePort, passwordEncoder, tokenProvider, null, null);
    }


    public User getUserById(String userId) {
        return userPersistencePort.findUserById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found: " + userId));
    }

    @Override
    public boolean verifyPin(String userId, String rawPin) {
        User user = userPersistencePort.findUserById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found: " + userId));
        if (user.getPinHash() == null) return false;
        return passwordEncoder.matches(rawPin, user.getPinHash());
    }

    @Override
    @Transactional
    public void setPin(String userId, String rawPin) {
        if (rawPin == null || !rawPin.matches("^\\d{6}$")) {
            throw new IllegalArgumentException("PIN must be exactly 6 digits");
        }
        User user = userPersistencePort.findUserById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found: " + userId));

        user.updatePin(passwordEncoder.encode(rawPin));
        userPersistencePort.saveUser(user);
        recordAuditLog(userId, "SET_PIN", "pin_updated");
    }

    @Override
    public String verifyPinAndIssueToken(String userId, String rawPin) {
        User user = userPersistencePort.findUserById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found: " + userId));

        if (user.getPinHash() == null) {
            throw new InvalidPinException("Transaction PIN has not been set yet");
        }

        if (!passwordEncoder.matches(rawPin, user.getPinHash())) {
            throw new InvalidPinException("Incorrect PIN");
        }

        return tokenProvider.generatePinToken(userId);
    }

    @Override
    public boolean validatePinToken(String userId, String pinToken) {
        if (pinToken == null || !tokenProvider.validateToken(pinToken)) {
            return false;
        }
        String tokenUserId = tokenProvider.getUserIdFromToken(pinToken);
        String tokenType = tokenProvider.getTokenType(pinToken);
        return userId.equals(tokenUserId) && "PIN_VERIFIED".equals(tokenType);
    }

    @Override
    @Transactional
    public UserKyc submitKyc(String userId, String idCardNumber, String fullName, String dob, String frontUrl, String backUrl, String selfieUrl) {
        User user = userPersistencePort.findUserById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found: " + userId));

        UserKyc kyc = UserKyc.createPending(userId, idCardNumber, fullName, dob, frontUrl, backUrl, selfieUrl);
        UserKyc savedKyc = kycPersistencePort.saveKyc(kyc);

        user.updateKycStatus(KycStatus.PENDING);
        userPersistencePort.saveUser(user);
        recordAuditLog(userId, "SUBMIT_KYC", "idCard:" + idCardNumber);

        return savedKyc;
    }

    @Override
    public UserKyc getKycStatus(String userId) {
        return kycPersistencePort.findKycByUserId(userId)
                .orElse(null);
    }

    @Override
    @Transactional
    public UserKyc processKycWebhook(String userId, KycStatus status, String rejectionReason) {
        UserKyc kyc = kycPersistencePort.findKycByUserId(userId)
                .orElseThrow(() -> new IllegalArgumentException("KYC record not found for user: " + userId));
        User user = userPersistencePort.findUserById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found: " + userId));

        if (status == KycStatus.VERIFIED) {
            kyc.approve();
            user.updateKycStatus(KycStatus.VERIFIED);
        } else if (status == KycStatus.REJECTED) {
            kyc.reject();
            user.updateKycStatus(KycStatus.REJECTED);
        }

        kycPersistencePort.saveKyc(kyc);
        userPersistencePort.saveUser(user);
        recordAuditLog(userId, "KYC_WEBHOOK", "status:" + status + ",reason:" + rejectionReason);
        return kyc;
    }

    @Transactional
    public void changePassword(String userId, String oldPassword, String newPassword) {
        User user = userPersistencePort.findUserById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found: " + userId));

        if (!passwordEncoder.matches(oldPassword, user.getPasswordHash())) {
            throw new IllegalArgumentException("Incorrect old password");
        }
        if (newPassword == null || newPassword.length() < 6) {
            throw new IllegalArgumentException("New password must be at least 6 characters");
        }

        user.updatePassword(passwordEncoder.encode(newPassword));
        userPersistencePort.saveUser(user);
        recordAuditLog(userId, "CHANGE_PASSWORD", "success");
    }

    private void recordAuditLog(String callerId, String action, String payloadHash) {
        if (auditLogPersistencePort != null) {
            try {
                auditLogPersistencePort.saveAuditLog(AuditLog.record(callerId, "127.0.0.1", action, payloadHash, java.util.UUID.randomUUID().toString()));
            } catch (Exception e) {
                log.warn("Failed to record audit log action={}: {}", action, e.getMessage());
            }
        }
    }
}

