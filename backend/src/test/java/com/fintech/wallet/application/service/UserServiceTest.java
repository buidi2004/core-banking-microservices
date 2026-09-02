package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.exception.InvalidPinException;
import com.fintech.wallet.domain.model.KycStatus;
import com.fintech.wallet.domain.model.User;
import com.fintech.wallet.domain.model.UserKyc;
import com.fintech.wallet.domain.port.out.KycPersistencePort;
import com.fintech.wallet.domain.port.out.UserPersistencePort;
import com.fintech.wallet.infrastructure.security.JwtTokenProvider;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.time.Instant;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class UserServiceTest {

    private static final String JWT_SECRET =
            "SuperSecretKeyForFintechWalletAppShouldBeAtLeast32BytesLong!";

    private UserPersistencePort userPersistencePort;
    private KycPersistencePort kycPersistencePort;
    private PasswordEncoder passwordEncoder;
    // JwtTokenProvider is a @Component with no interface — use real instance
    private JwtTokenProvider tokenProvider;
    private UserService userService;

    @BeforeEach
    void setUp() {
        userPersistencePort = Mockito.mock(UserPersistencePort.class);
        kycPersistencePort  = Mockito.mock(KycPersistencePort.class);
        passwordEncoder     = new BCryptPasswordEncoder();
        tokenProvider       = new JwtTokenProvider(JWT_SECRET);

        userService = new UserService(
                userPersistencePort,
                kycPersistencePort,
                passwordEncoder,
                tokenProvider);
    }

    // ─── PIN ────────────────────────────────────────────────────────────────

    @Test
    void setPin_validPin_shouldSave() {
        User user = new User("u1", "0987654321", "Test Name", "hash", null,
                KycStatus.UNVERIFIED, Instant.now(), Instant.now());
        when(userPersistencePort.findUserById("u1")).thenReturn(Optional.of(user));

        userService.setPin("u1", "123456");

        verify(userPersistencePort).saveUser(user);
        assertNotNull(user.getPinHash());
        assertTrue(passwordEncoder.matches("123456", user.getPinHash()));
    }

    @Test
    void setPin_invalidPin_shouldThrow() {
        // 4-digit PIN must fail validation (requires exactly 6 digits)
        assertThrows(IllegalArgumentException.class,
                () -> userService.setPin("u1", "1234"));
    }

    @Test
    void setPin_nonNumericPin_shouldThrow() {
        assertThrows(IllegalArgumentException.class,
                () -> userService.setPin("u1", "abcdef"));
    }

    @Test
    void verifyPinAndIssueToken_correctPin_shouldReturnToken() {
        String rawPin   = "123456";
        String encoded  = passwordEncoder.encode(rawPin);
        User user = new User("u1", "0987654321", "Test Name", "hash", encoded,
                KycStatus.UNVERIFIED, Instant.now(), Instant.now());
        when(userPersistencePort.findUserById("u1")).thenReturn(Optional.of(user));

        String token = userService.verifyPinAndIssueToken("u1", rawPin);

        assertNotNull(token);
        assertTrue(tokenProvider.validateToken(token));
        assertEquals("u1", tokenProvider.getUserIdFromToken(token));
        assertEquals("PIN_VERIFIED", tokenProvider.getTokenType(token));
    }

    @Test
    void verifyPinAndIssueToken_incorrectPin_shouldThrow() {
        String encoded = passwordEncoder.encode("999999");
        User user = new User("u1", "0987654321", "Test Name", "hash", encoded,
                KycStatus.UNVERIFIED, Instant.now(), Instant.now());
        when(userPersistencePort.findUserById("u1")).thenReturn(Optional.of(user));

        assertThrows(InvalidPinException.class,
                () -> userService.verifyPinAndIssueToken("u1", "123456"));
    }

    @Test
    void verifyPinAndIssueToken_noPinSet_shouldThrow() {
        User user = new User("u1", "0987654321", "Test Name", "hash", null,
                KycStatus.UNVERIFIED, Instant.now(), Instant.now());
        when(userPersistencePort.findUserById("u1")).thenReturn(Optional.of(user));

        assertThrows(InvalidPinException.class,
                () -> userService.verifyPinAndIssueToken("u1", "123456"));
    }

    @Test
    void validatePinToken_validToken_shouldReturnTrue() {
        String rawPin  = "123456";
        String encoded = passwordEncoder.encode(rawPin);
        User user = new User("u1", "0987654321", "Test Name", "hash", encoded,
                KycStatus.UNVERIFIED, Instant.now(), Instant.now());
        when(userPersistencePort.findUserById("u1")).thenReturn(Optional.of(user));

        // Issue a real PIN token, then validate it
        String token = userService.verifyPinAndIssueToken("u1", rawPin);
        assertTrue(userService.validatePinToken("u1", token));
    }

    @Test
    void validatePinToken_invalidToken_shouldReturnFalse() {
        assertFalse(userService.validatePinToken("u1", "not-a-valid-token"));
    }

    // ─── KYC ────────────────────────────────────────────────────────────────

    @Test
    void submitKyc_shouldSaveKycAndUpdateUser() {
        User user = new User("u1", "0987654321", "Test Name", "hash", null,
                KycStatus.UNVERIFIED, Instant.now(), Instant.now());
        when(userPersistencePort.findUserById("u1")).thenReturn(Optional.of(user));

        UserKyc pending = UserKyc.createPending("u1", "123", "Name", "1990", "f", "b", "s");
        when(kycPersistencePort.saveKyc(any())).thenReturn(pending);

        UserKyc result = userService.submitKyc("u1", "123", "Name", "1990", "f", "b", "s");

        assertEquals(KycStatus.PENDING, result.getStatus());
        verify(userPersistencePort).saveUser(user);
        assertEquals(KycStatus.PENDING, user.getKycStatus());
    }

    @Test
    void processKycWebhook_approved_shouldSetVerified() {
        User user = new User("u1", "0987654321", "Test Name", "hash", null,
                KycStatus.PENDING, Instant.now(), Instant.now());
        UserKyc kyc = UserKyc.createPending("u1", "123", "Name", "1990", "f", "b", "s");
        when(kycPersistencePort.findKycByUserId("u1")).thenReturn(Optional.of(kyc));
        when(userPersistencePort.findUserById("u1")).thenReturn(Optional.of(user));
        when(kycPersistencePort.saveKyc(any())).thenReturn(kyc);

        userService.processKycWebhook("u1", KycStatus.VERIFIED, null);

        assertEquals(KycStatus.VERIFIED, kyc.getStatus());
        assertEquals(KycStatus.VERIFIED, user.getKycStatus());
    }

    @Test
    void processKycWebhook_rejected_shouldSetRejected() {
        User user = new User("u1", "0987654321", "Test Name", "hash", null,
                KycStatus.PENDING, Instant.now(), Instant.now());
        UserKyc kyc = UserKyc.createPending("u1", "123", "Name", "1990", "f", "b", "s");
        when(kycPersistencePort.findKycByUserId("u1")).thenReturn(Optional.of(kyc));
        when(userPersistencePort.findUserById("u1")).thenReturn(Optional.of(user));
        when(kycPersistencePort.saveKyc(any())).thenReturn(kyc);

        userService.processKycWebhook("u1", KycStatus.REJECTED, "Document unclear");

        assertEquals(KycStatus.REJECTED, kyc.getStatus());
        assertEquals(KycStatus.REJECTED, user.getKycStatus());
    }
}
