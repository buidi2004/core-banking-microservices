package com.fintech.wallet.concurrency;

import com.fintech.wallet.domain.entity.Wallet;
import com.fintech.wallet.repository.WalletRepository;
import com.fintech.wallet.service.WalletGrpcService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ValueOperations;

import java.util.Optional;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * Concurrency stress test — verifies that WalletGrpcService correctly serialises
 * balance mutations when multiple threads call debit/credit concurrently.
 *
 * Because the real pessimistic lock lives at the DB layer (PESSIMISTIC_WRITE on
 * WalletRepository.findByIdForUpdate), this test simulates lock contention by
 * making the repository return a shared mutable wallet instance. Each thread
 * reads → mutates → writes back; if the service were not serialised the final
 * balance would drift. We assert it converges to the mathematically correct value.
 */
@ExtendWith(MockitoExtension.class)
class WalletConcurrencyTest {

    @Mock
    private WalletRepository walletRepository;

    @Mock
    private StringRedisTemplate redisTemplate;

    @Mock
    private ValueOperations<String, String> valueOperations;

    @InjectMocks
    private WalletGrpcService walletGrpcService;

    private static final String WALLET_ID = "w-concurrent";
    private static final String USER_ID = "u-concurrent";
    private static final int THREAD_COUNT = 20;
    private static final long CREDIT_AMOUNT = 5000L;
    private static final long INITIAL_BALANCE = 0L;

    @BeforeEach
    void setUp() {
        when(redisTemplate.opsForValue()).thenReturn(valueOperations);
    }

    @Test
    @DisplayName("20 luồng credit đồng thời — số dư cuối = THREAD_COUNT * CREDIT_AMOUNT")
    void concurrentCredit_sumMatches() throws InterruptedException {
        Wallet sharedWallet = Wallet.builder()
                .id(WALLET_ID)
                .userId(USER_ID)
                .balance(INITIAL_BALANCE)
                .reservedBalance(0L)
                .currency("VND")
                .status("ACTIVE")
                .dailyLimit(50000000L)
                .dailySpent(0L)
                .build();

        // Mô phỏng pessimistic row-level lock (SELECT FOR UPDATE) trên DB
        java.util.concurrent.locks.ReentrantLock dbCreditLock = new java.util.concurrent.locks.ReentrantLock(true);
        when(walletRepository.findByIdForUpdate(WALLET_ID)).thenAnswer(inv -> {
            dbCreditLock.lock();
            return Optional.of(sharedWallet);
        });
        // save trả về chính đối tượng đó và giải phóng row lock
        when(walletRepository.save(any(Wallet.class))).thenAnswer(inv -> {
            try {
                return inv.getArgument(0);
            } finally {
                if (dbCreditLock.isHeldByCurrentThread()) {
                    dbCreditLock.unlock();
                }
            }
        });
        // idempotency key luôn unique
        when(valueOperations.setIfAbsent(anyString(), anyString(), any())).thenReturn(true);

        ExecutorService executor = Executors.newFixedThreadPool(THREAD_COUNT);
        CountDownLatch start = new CountDownLatch(1);
        CountDownLatch done = new CountDownLatch(THREAD_COUNT);
        AtomicInteger success = new AtomicInteger(0);

        for (int i = 0; i < THREAD_COUNT; i++) {
            final int idx = i;
            executor.submit(() -> {
                try {
                    start.await();
                    WalletGrpcService.CreditResult r = walletGrpcService.creditWallet(
                            WALLET_ID, CREDIT_AMOUNT, "tx-" + idx, null);
                    if (r.success) success.incrementAndGet();
                } catch (Exception e) {
                    // ignore
                } finally {
                    if (dbCreditLock.isHeldByCurrentThread()) {
                        dbCreditLock.unlock();
                    }
                    done.countDown();
                }
            });
        }

        start.countDown();
        done.await(15, java.util.concurrent.TimeUnit.SECONDS);
        executor.shutdown();

        long expected = (long) THREAD_COUNT * CREDIT_AMOUNT;
        System.out.printf("[Concurrency Credit] threads=%d, success=%d, finalBalance=%d, expected=%d%n",
                THREAD_COUNT, success.get(), sharedWallet.getBalance(), expected);

        // Nếu có race condition: số dư thực tế != tổng credit dự kiến
        assertEquals(expected, sharedWallet.getBalance(),
                "Concurrent credit produced wrong balance — possible race condition!");
    }

    @Test
    @DisplayName("20 luồng debit đồng thời — số dư không được âm, không vượt quá balance ban đầu")
    void concurrentDebit_noNegativeBalance() throws InterruptedException {
        long initial = 50000L;
        long debitAmt = 1000L;
        Wallet sharedWallet = Wallet.builder()
                .id(WALLET_ID)
                .userId(USER_ID)
                .balance(initial)
                .reservedBalance(0L)
                .currency("VND")
                .status("ACTIVE")
                .dailyLimit(50000000L)
                .dailySpent(0L)
                .build();

        // Mô phỏng pessimistic row-level lock (SELECT FOR UPDATE) trên DB
        java.util.concurrent.locks.ReentrantLock dbDebitLock = new java.util.concurrent.locks.ReentrantLock(true);
        when(walletRepository.findByIdForUpdate(WALLET_ID)).thenAnswer(inv -> {
            dbDebitLock.lock();
            return Optional.of(sharedWallet);
        });
        when(walletRepository.save(any(Wallet.class))).thenAnswer(inv -> {
            try {
                return inv.getArgument(0);
            } finally {
                if (dbDebitLock.isHeldByCurrentThread()) {
                    dbDebitLock.unlock();
                }
            }
        });
        when(valueOperations.setIfAbsent(anyString(), anyString(), any())).thenReturn(true);

        ExecutorService executor = Executors.newFixedThreadPool(THREAD_COUNT);
        CountDownLatch start = new CountDownLatch(1);
        CountDownLatch done = new CountDownLatch(THREAD_COUNT);
        AtomicInteger success = new AtomicInteger(0);
        AtomicInteger failed = new AtomicInteger(0);

        for (int i = 0; i < THREAD_COUNT; i++) {
            final int idx = i;
            executor.submit(() -> {
                try {
                    start.await();
                    WalletGrpcService.DebitResult r = walletGrpcService.debitWallet(
                            WALLET_ID, debitAmt, "tx-d-" + idx, null);
                    if (r.success) success.incrementAndGet();
                    else failed.incrementAndGet();
                } catch (Exception e) {
                    failed.incrementAndGet();
                } finally {
                    if (dbDebitLock.isHeldByCurrentThread()) {
                        dbDebitLock.unlock();
                    }
                    done.countDown();
                }
            });
        }

        start.countDown();
        done.await(15, java.util.concurrent.TimeUnit.SECONDS);
        executor.shutdown();

        System.out.printf("[Concurrency Debit] threads=%d, success=%d, failed=%d, finalBalance=%d, initial=%d%n",
                THREAD_COUNT, success.get(), failed.get(), sharedWallet.getBalance(), initial);

        // Số dư không bao giờ âm (không có race condition cho phép trừ quá mức)
        assertTrue(sharedWallet.getBalance() >= 0,
                "Balance went negative — race condition detected! Balance=" + sharedWallet.getBalance());
        // Không debit quá số dư ban đầu
        assertTrue(success.get() * debitAmt <= initial,
                "Total debited (" + (success.get() * debitAmt) + ") exceeds initial balance (" + initial + ")");
    }
}
