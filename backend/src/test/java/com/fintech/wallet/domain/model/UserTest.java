package com.fintech.wallet.domain.model;

import org.junit.jupiter.api.Test;

import java.time.Instant;

import static org.junit.jupiter.api.Assertions.*;

class UserTest {

    @Test
    void constructor_shouldSetUnverifiedKycStatus() {
        User user = new User("user-1", "0987654321", "Test Name", "pass_hash", null, KycStatus.UNVERIFIED, Instant.now(), Instant.now());
        assertEquals("user-1", user.getId());
        assertEquals("0987654321", user.getPhoneNumber());
        assertEquals("pass_hash", user.getPasswordHash());
        assertEquals(KycStatus.UNVERIFIED, user.getKycStatus());
    }

    @Test
    void updatePin_shouldSetPinHash() {
        User user = new User("user-1", "0987654321", "Test Name", "pass_hash", null, KycStatus.UNVERIFIED, Instant.now(), Instant.now());
        user.updatePin("new_pin_hash");
        assertEquals("new_pin_hash", user.getPinHash());
    }

    @Test
    void updatePassword_shouldSetPasswordHash() {
        User user = new User("user-1", "0987654321", "Test Name", "old_pass_hash", null, KycStatus.UNVERIFIED, Instant.now(), Instant.now());
        user.updatePassword("new_pass_hash");
        assertEquals("new_pass_hash", user.getPasswordHash());
    }

    @Test
    void updateKycStatus_shouldChangeStatus() {
        User user = new User("user-1", "0987654321", "Test Name", "pass_hash", null, KycStatus.UNVERIFIED, Instant.now(), Instant.now());
        user.updateKycStatus(KycStatus.VERIFIED);
        assertEquals(KycStatus.VERIFIED, user.getKycStatus());
    }
}
