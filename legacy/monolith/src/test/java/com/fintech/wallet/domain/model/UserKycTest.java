package com.fintech.wallet.domain.model;

import org.junit.jupiter.api.Test;

import java.time.Instant;

import static org.junit.jupiter.api.Assertions.*;

class UserKycTest {

    @Test
    void createPending_shouldSetPendingStatus() {
        UserKyc kyc = UserKyc.createPending("user-1", "123456789", "John Doe", "1990-01-01", "url1", "url2", "url3");
        assertEquals(KycStatus.PENDING, kyc.getStatus());
        assertEquals("user-1", kyc.getUserId());
        assertEquals("123456789", kyc.getIdCardNumber());
    }

    @Test
    void approve_shouldSetVerifiedStatus() {
        UserKyc kyc = UserKyc.createPending("user-1", "123456789", "John Doe", "1990-01-01", "url1", "url2", "url3");
        kyc.approve();
        assertEquals(KycStatus.VERIFIED, kyc.getStatus());
    }

    @Test
    void reject_shouldSetRejectedStatus() {
        UserKyc kyc = UserKyc.createPending("user-1", "123456789", "John Doe", "1990-01-01", "url1", "url2", "url3");
        kyc.reject();
        assertEquals(KycStatus.REJECTED, kyc.getStatus());
    }
}
