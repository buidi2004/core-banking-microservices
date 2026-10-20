package com.fintech.wallet.service;

import com.fintech.wallet.domain.entity.Wallet;
import com.fintech.wallet.repository.WalletRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ValueOperations;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * Unit tests cho WalletGrpcService — 6 RPC methods:
 * DebitWallet, CreditWallet, ReserveBalance, ReleaseBalance, CheckLimit, GetWalletByUserId.
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class WalletGrpcServiceTest {

    @Mock
    private WalletRepository walletRepository;

    @Mock
    private StringRedisTemplate redisTemplate;

    @Mock
    private ValueOperations<String, String> valueOperations;

    @InjectMocks
    private WalletGrpcService walletGrpcService;

    @BeforeEach
    void setUp() {
        when(redisTemplate.opsForValue()).thenReturn(valueOperations);
        when(valueOperations.setIfAbsent(anyString(), anyString(), any())).thenReturn(true);
    }

    private Wallet createWallet(String id, String userId, long balance, long reservedBalance,
                                String currency, String status) {
        return Wallet.builder()
                .id(id)
                .userId(userId)
                .balance(balance)
                .reservedBalance(reservedBalance)
                .currency(currency)
                .status(status)
                .dailyLimit(50000000L)
                .dailySpent(0L)
                .build();
    }

    // ======================== DEBIT WALLET ========================

    @Nested
    @DisplayName("DebitWallet")
    class DebitWalletTests {

        @Test
        @DisplayName("Should debit successfully when sufficient balance")
        void debit_success() {
            String walletId = "w-1";
            Wallet wallet = createWallet(walletId, "u-1", 100000L, 0L, "VND", "ACTIVE");
            when(walletRepository.findByIdForUpdate(walletId)).thenReturn(Optional.of(wallet));
            when(redisTemplate.opsForValue().setIfAbsent(anyString(), anyString(), any()))
                    .thenReturn(true);

            WalletGrpcService.DebitResult result = walletGrpcService.debitWallet(walletId, 30000L, "tx-1", null);

            assertTrue(result.success);
            assertEquals(70000L, result.balanceAfter);
            verify(walletRepository).save(wallet);
        }

        @Test
        @DisplayName("Should throw IllegalArgumentException when wallet not found")
        void debit_walletNotFound() {
            when(walletRepository.findByIdForUpdate(any())).thenReturn(Optional.empty());

            IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, () ->
                    walletGrpcService.debitWallet("w-missing", 1000L, "tx-1", null)
            );
            assertEquals("Wallet not found: w-missing", ex.getMessage());
        }

        @Test
        @DisplayName("Should return failure when insufficient balance")
        void debit_insufficientBalance() {
            Wallet wallet = createWallet("w-1", "u-1", 5000L, 0L, "VND", "ACTIVE");
            when(walletRepository.findByIdForUpdate("w-1")).thenReturn(Optional.of(wallet));
            when(redisTemplate.opsForValue().setIfAbsent(anyString(), anyString(), any()))
                    .thenReturn(true);

            WalletGrpcService.DebitResult result = walletGrpcService.debitWallet("w-1", 10000L, "tx-1", null);

            assertFalse(result.success);
            assertEquals("DEBIT_INSUFFICIENT_BALANCE", result.errorCode);
        }

        @Test
        @DisplayName("Should return failure when wallet is frozen")
        void debit_walletFrozen() {
            Wallet wallet = createWallet("w-1", "u-1", 100000L, 0L, "VND", "LOCKED");
            when(walletRepository.findByIdForUpdate("w-1")).thenReturn(Optional.of(wallet));

            WalletGrpcService.DebitResult result = walletGrpcService.debitWallet("w-1", 1000L, "tx-1", null);

            assertFalse(result.success);
            assertEquals("DEBIT_WALLET_FROZEN", result.errorCode);
        }

        @Test
        @DisplayName("Should return idempotent error when transaction already processed")
        void debit_idempotent() {
            when(redisTemplate.opsForValue().setIfAbsent(anyString(), anyString(), any()))
                    .thenReturn(false);

            WalletGrpcService.DebitResult result = walletGrpcService.debitWallet("w-1", 1000L, "tx-dup", null);

            assertFalse(result.success);
            assertEquals("DEBIT_IDEMPOTENT", result.errorCode);
        }
    }

    // ======================== CREDIT WALLET ========================

    @Nested
    @DisplayName("CreditWallet")
    class CreditWalletTests {

        @Test
        @DisplayName("Should credit successfully")
        void credit_success() {
            Wallet wallet = createWallet("w-1", "u-1", 50000L, 0L, "VND", "ACTIVE");
            when(walletRepository.findByIdForUpdate("w-1")).thenReturn(Optional.of(wallet));
            when(redisTemplate.opsForValue().setIfAbsent(anyString(), anyString(), any()))
                    .thenReturn(true);

            WalletGrpcService.CreditResult result = walletGrpcService.creditWallet("w-1", 20000L, "tx-2", null);

            assertTrue(result.success);
            assertEquals(70000L, result.balanceAfter);
            verify(walletRepository).save(wallet);
        }

        @Test
        @DisplayName("Should throw IllegalArgumentException when wallet not found")
        void credit_walletNotFound() {
            when(walletRepository.findByIdForUpdate(any())).thenReturn(Optional.empty());

            IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, () ->
                    walletGrpcService.creditWallet("w-missing", 1000L, "tx-2", null)
            );
            assertEquals("Wallet not found: w-missing", ex.getMessage());
        }
    }

    // ======================== RESERVE BALANCE ========================

    @Nested
    @DisplayName("ReserveBalance")
    class ReserveBalanceTests {

        @Test
        @DisplayName("Should reserve balance successfully")
        void reserve_success() {
            Wallet wallet = createWallet("w-1", "u-1", 100000L, 0L, "VND", "ACTIVE");
            when(walletRepository.findByIdForUpdate("w-1")).thenReturn(Optional.of(wallet));
            // setIfAbsent with any key returns true
            when(valueOperations.setIfAbsent(anyString(), anyString(), any())).thenReturn(true);

            WalletGrpcService.ReserveResult result = walletGrpcService.reserveBalance("w-1", 30000L, "tx-3", 3600);

            assertTrue(result.success);
            assertNotNull(result.reservationId);
            assertEquals(30000L, wallet.getReservedBalance());
            verify(walletRepository).save(wallet);
        }

        @Test
        @DisplayName("Should return failure when insufficient available balance")
        void reserve_insufficient() {
            Wallet wallet = createWallet("w-1", "u-1", 10000L, 8000L, "VND", "ACTIVE");
            when(walletRepository.findByIdForUpdate("w-1")).thenReturn(Optional.of(wallet));

            WalletGrpcService.ReserveResult result = walletGrpcService.reserveBalance("w-1", 5000L, "tx-3", 3600);

            assertFalse(result.success);
            assertEquals("RESERVE_INSUFFICIENT", result.errorCode);
        }
    }

    // ======================== RELEASE BALANCE ========================

    @Nested
    @DisplayName("ReleaseBalance")
    class ReleaseBalanceTests {

        @Test
        @DisplayName("Should release balance successfully")
        void release_success() {
            String reservationId = "res-1";
            String walletId = "w-1";
            long amount = 30000L;
            when(valueOperations.get("wallet:reservation:" + reservationId))
                    .thenReturn(walletId + ":" + amount);

            Wallet wallet = createWallet(walletId, "u-1", 100000L, amount, "VND", "ACTIVE");
            when(walletRepository.findByIdForUpdate(walletId)).thenReturn(Optional.of(wallet));
            when(redisTemplate.delete("wallet:reservation:" + reservationId)).thenReturn(true);

            WalletGrpcService.ReleaseResult result = walletGrpcService.releaseBalance(reservationId, "tx-4");

            assertTrue(result.success);
            assertEquals(0L, wallet.getReservedBalance());
            verify(walletRepository).save(wallet);
        }

        @Test
        @DisplayName("Should return failure when reservation not found")
        void release_notFound() {
            when(valueOperations.get("wallet:reservation:missing")).thenReturn(null);

            WalletGrpcService.ReleaseResult result = walletGrpcService.releaseBalance("missing", "tx-4");

            assertFalse(result.success);
            assertEquals("RELEASE_NOT_FOUND", result.errorCode);
        }
    }

    // ======================== CHECK LIMIT ========================

    @Nested
    @DisplayName("CheckLimit")
    class CheckLimitTests {

        @Test
        @DisplayName("Should allow when sufficient available balance")
        void checkLimit_allowed() {
            Wallet wallet = createWallet("w-1", "u-1", 100000L, 10000L, "VND", "ACTIVE");
            wallet.setDailyLimit(50000L);
            wallet.setDailySpent(5000L);
            when(walletRepository.findById("w-1")).thenReturn(Optional.of(wallet));

            WalletGrpcService.LimitCheckResult result = walletGrpcService.checkLimit("w-1", 50000L, "TRANSFER", "u-1");

            assertTrue(result.allowed);
            assertEquals(90000L, result.availableBalance);
            assertEquals(45000L, result.dailyLimitRemaining);
        }

        @Test
        @DisplayName("Should reject when balance insufficient")
        void checkLimit_rejected() {
            Wallet wallet = createWallet("w-1", "u-1", 5000L, 0L, "VND", "ACTIVE");
            when(walletRepository.findById("w-1")).thenReturn(Optional.of(wallet));

            WalletGrpcService.LimitCheckResult result = walletGrpcService.checkLimit("w-1", 10000L, "TRANSFER", "u-1");

            assertFalse(result.allowed);
            assertEquals("LIMIT_EXCEEDED", result.errorCode);
        }

        @Test
        @DisplayName("Should reject when wallet is not active")
        void checkLimit_walletNotActive() {
            Wallet wallet = createWallet("w-1", "u-1", 100000L, 0L, "VND", "LOCKED");
            when(walletRepository.findById("w-1")).thenReturn(Optional.of(wallet));

            WalletGrpcService.LimitCheckResult result = walletGrpcService.checkLimit("w-1", 1000L, "TRANSFER", "u-1");

            assertFalse(result.allowed);
        }
    }

    // ======================== GET WALLET BY USER ID ========================

    @Nested
    @DisplayName("GetWalletByUserId")
    class GetWalletByUserIdTests {

        @Test
        @DisplayName("Should return wallet when found")
        void getWallet_found() {
            Wallet wallet = createWallet("w-1", "u-1", 50000L, 0L, "VND", "ACTIVE");
            when(walletRepository.findByUserId("u-1")).thenReturn(Optional.of(wallet));

            WalletGrpcService.GetWalletResult result = walletGrpcService.getWalletByUserId("u-1");

            assertTrue(result.found);
            assertEquals("w-1", result.walletId);
            assertEquals("u-1", result.userId);
            assertEquals(50000L, result.balance);
            assertEquals("VND", result.currency);
            assertEquals("ACTIVE", result.status);
        }

        @Test
        @DisplayName("Should return not found when no wallet")
        void getWallet_notFound() {
            when(walletRepository.findByUserId("u-missing")).thenReturn(Optional.empty());

            WalletGrpcService.GetWalletResult result = walletGrpcService.getWalletByUserId("u-missing");

            assertFalse(result.found);
            assertEquals("WALLET_NOT_FOUND", result.errorCode);
        }
    }
}
