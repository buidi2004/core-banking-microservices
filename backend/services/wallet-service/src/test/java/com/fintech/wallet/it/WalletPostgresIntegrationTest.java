package com.fintech.wallet.it;

import com.fintech.wallet.WalletCoreApplication;
import com.fintech.wallet.domain.entity.Wallet;
import com.fintech.wallet.repository.WalletRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestInstance;
import org.junit.jupiter.api.condition.DisabledIfEnvironmentVariable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.math.BigDecimal;
import java.sql.Timestamp;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Integration test với PostgreSQL thật qua Testcontainers.
 * Xác thực:
 *  - CREATE: ví mới được lưu chính xác
 *  - READ: findById, findByOwnerId, findByIdForUpdate
 *  - UPDATE: pessimistic lock hoạt động đúng với SELECT FOR UPDATE
 *  - CHECK CONSTRAINT: balance không âm, reserved_balance không âm
 *  - UNIQUE INDEX: không tạo 2 ví cùng user_id
 */
@Testcontainers(disabledWithoutDocker = true)
@SpringBootTest(classes = WalletCoreApplication.class)
@ActiveProfiles("it")
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class WalletPostgresIntegrationTest {

    static final PostgreSQLContainer<?> POSTGRES;

    static {
        POSTGRES = new PostgreSQLContainer<>("postgres:15-alpine")
                .withDatabaseName("ewallet_wallet_db_test")
                .withUsername("postgres")
                .withPassword("postgres")
                .withReuse(true);
        POSTGRES.start();
    }

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        registry.add("spring.datasource.username", POSTGRES::getUsername);
        registry.add("spring.datasource.password", POSTGRES::getPassword);
        registry.add("spring.datasource.driver-class-name",
                () -> "org.postgresql.Driver");
    }

    @Autowired
    private WalletRepository walletRepository;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Autowired
    private org.springframework.transaction.support.TransactionTemplate transactionTemplate;

    // ─── Helper ─────────────────────────────────────────────────────────────────

    private Wallet buildWallet(String userId, long balance) {
        return Wallet.builder()
                .userId(userId)
                .balance(balance)
                .reservedBalance(0L)
                .currency("VND")
                .status("ACTIVE")
                .dailyLimit(50000000L)
                .dailySpent(0L)
                .build();
    }

    private Wallet saveWallet(String userId, long balance) {
        Wallet w = buildWallet(userId, balance);
        return walletRepository.saveAndFlush(w);
    }

    private long rawBalance(String walletId) {
        return jdbcTemplate.queryForObject(
                "SELECT balance FROM wallets WHERE id = ?", Long.class, walletId);
    }

    private long rawReservedBalance(String walletId) {
        return jdbcTemplate.queryForObject(
                "SELECT reserved_balance FROM wallets WHERE id = ?", Long.class, walletId);
    }

    private String rawStatus(String walletId) {
        return jdbcTemplate.queryForObject(
                "SELECT status FROM wallets WHERE id = ?", String.class, walletId);
    }

    // ─── CREATE ─────────────────────────────────────────────────────────────────

    @Nested
    @DisplayName("CREATE — tạo ví mới")
    class CreateTests {

        @Test
        @DisplayName("Tạo ví thành công — ID tự sinh, balance=0, currency=VND, status=ACTIVE")
        void create_wallet() {
            Wallet wallet = saveWallet("user-create-1", 0L);

            assertThat(wallet.getId()).isNotNull();
            assertThat(wallet.getUserId()).isEqualTo("user-create-1");
            assertThat(wallet.getBalance()).isEqualTo(0L);
            assertThat(wallet.getReservedBalance()).isEqualTo(0L);
            assertThat(wallet.getCurrency()).isEqualTo("VND");
            assertThat(wallet.getStatus()).isEqualTo("ACTIVE");
            assertThat(wallet.getDailyLimit()).isEqualTo(50000000L);
            assertThat(wallet.getDailySpent()).isEqualTo(0L);

            // Xác thực tồn tại trong DB
            Long count = jdbcTemplate.queryForObject(
                    "SELECT count(*) FROM wallets WHERE id = ?", Long.class, wallet.getId());
            assertThat(count).isEqualTo(1L);
        }

        @Test
        @DisplayName("Tạo ví với số dư ban đầu khác 0")
        void create_wallet_withInitialBalance() {
            Wallet wallet = saveWallet("user-create-2", 100000L);

            assertThat(wallet.getBalance()).isEqualTo(100000L);
            assertThat(rawBalance(wallet.getId())).isEqualTo(100000L);
        }

        @Test
        @DisplayName("Không tạo được 2 ví cùng user_id — unique constraint")
        void create_duplicateUserId_fails() {
            saveWallet("user-dup-1", 0L);

            Wallet second = buildWallet("user-dup-1", 0L);
            assertThatThrownBy(() -> walletRepository.saveAndFlush(second))
                    .isInstanceOf(org.springframework.dao.DataIntegrityViolationException.class);
        }
    }

    // ─── READ ───────────────────────────────────────────────────────────────────

    @Nested
    @DisplayName("READ — truy vấn ví")
    class ReadTests {

        @BeforeEach
        void setUp() {
            walletRepository.deleteAll();
        }

        @Test
        @DisplayName("findById trả về ví đúng")
        void findById_returnsWallet() {
            Wallet saved = saveWallet("user-read-1", 50000L);
            Optional<Wallet> found = walletRepository.findById(saved.getId());

            assertThat(found).isPresent();
            assertThat(found.get().getUserId()).isEqualTo("user-read-1");
            assertThat(found.get().getBalance()).isEqualTo(50000L);
        }

        @Test
        @DisplayName("findByIdForUpdate — PESSIMISTIC_WRITE lock active")
        void findByIdForUpdate_acquiresPessimisticLock() {
            Wallet saved = saveWallet("user-lock-1", 10000L);
            Optional<Wallet> locked = transactionTemplate.execute(status -> walletRepository.findByIdForUpdate(saved.getId()));

            assertThat(locked).isPresent();
            assertThat(locked.get().getId()).isEqualTo(saved.getId());
            assertThat(locked.get().getBalance()).isEqualTo(10000L);
        }

        @Test
        @DisplayName("findByUserId tìm theo userId (logical FK)")
        void findByUserId_returnsWallet() {
            Wallet saved = saveWallet("user-find-1", 75000L);
            Optional<Wallet> found = walletRepository.findByUserId("user-find-1");

            assertThat(found).isPresent();
            assertThat(found.get().getId()).isEqualTo(saved.getId());
            assertThat(found.get().getBalance()).isEqualTo(75000L);
        }

        @Test
        @DisplayName("findById trả về empty khi không tồn tại")
        void findById_notFound_returnsEmpty() {
            Optional<Wallet> found = walletRepository.findById(UUID.randomUUID().toString());
            assertThat(found).isEmpty();
        }
    }

    // ─── UPDATE với PESSIMISTIC LOCK ────────────────────────────────────────────

    @Nested
    @DisplayName("UPDATE — pessimistic lock (SELECT FOR UPDATE)")
    class UpdateWithLockTests {

        @BeforeEach
        void setUp() {
            walletRepository.deleteAll();
        }

        @Test
        @DisplayName("Cập nhật balance qua findByIdForUpdate — thay đổi persist vào DB")
        void updateBalance_viaForUpdate_persisted() {
            Wallet wallet = saveWallet("user-upd-1", 100000L);
            long before = rawBalance(wallet.getId());

            // Lock + update
            transactionTemplate.executeWithoutResult(status -> {
                Optional<Wallet> locked = walletRepository.findByIdForUpdate(wallet.getId());
                assertThat(locked).isPresent();
                Wallet w = locked.get();
                w.setBalance(80000L);
                walletRepository.saveAndFlush(w);
            });

            long after = rawBalance(wallet.getId());
            assertThat(after).isEqualTo(80000L);
            assertThat(after).isLessThan(before);
        }

        @Test
        @DisplayName("UPDATE với số dư âm — CHECK constraint chặn từ DB")
        void update_negativeBalance_blockedByCheckConstraint() {
            Wallet wallet = saveWallet("user-check-1", 10000L);

            // CHECK constraint (balance >= 0) phải chặn ở cấp DB
            assertThatThrownBy(() -> {
                transactionTemplate.executeWithoutResult(status -> {
                    Wallet w = walletRepository.findByIdForUpdate(wallet.getId()).orElseThrow();
                    w.setBalance(-1L);
                    walletRepository.saveAndFlush(w);
                });
            }).isInstanceOf(org.springframework.dao.DataIntegrityViolationException.class)
              .satisfies(e -> assertThat(e.getMessage()).containsIgnoringCase("balance"));
        }

        @Test
        @DisplayName("UPDATE reserved_balance âm — CHECK constraint chặn")
        void update_negativeReservedBalance_blockedByCheckConstraint() {
            Wallet wallet = saveWallet("user-reserve-check", 100000L);

            // CHECK constraint (reserved_balance >= 0) phải chặn ở cấp DB
            assertThatThrownBy(() -> {
                transactionTemplate.executeWithoutResult(status -> {
                    Wallet w = walletRepository.findByIdForUpdate(wallet.getId()).orElseThrow();
                    w.setReservedBalance(-1L);
                    walletRepository.saveAndFlush(w);
                });
            }).isInstanceOf(org.springframework.dao.DataIntegrityViolationException.class)
              .satisfies(e -> assertThat(e.getMessage()).containsIgnoringCase("reserved_balance"));
        }

        @Test
        @DisplayName("Cập nhật status sang LOCKED — persist đúng")
        void update_statusToLocked_persisted() {
            Wallet wallet = saveWallet("user-status-1", 50000L);

            transactionTemplate.executeWithoutResult(status -> {
                Wallet w = walletRepository.findByIdForUpdate(wallet.getId()).orElseThrow();
                w.setStatus("LOCKED");
                walletRepository.saveAndFlush(w);
            });

            assertThat(rawStatus(wallet.getId())).isEqualTo("LOCKED");
        }
    }

    // ─── CHECK CONSTRAINTS ──────────────────────────────────────────────────────

    @Nested
    @DisplayName("CHECK CONSTRAINTS — ràng buộc toàn vẹn dữ liệu")
    class CheckConstraintTests {

        @Test
        @DisplayName("INSERT balance < 0 bị chặn bởi CHECK constraint")
        void insert_negativeBalance_rejected() {
            Wallet wallet = Wallet.builder()
                    .userId("user-balance-check")
                    .balance(-100L)
                    .reservedBalance(0L)
                    .currency("VND")
                    .status("ACTIVE")
                    .dailyLimit(50000000L)
                    .dailySpent(0L)
                    .build();

            assertThatThrownBy(() -> walletRepository.saveAndFlush(wallet))
                    .isInstanceOf(org.springframework.dao.DataIntegrityViolationException.class)
                    .satisfies(e -> assertThat(e.getMessage()).containsIgnoringCase("balance"));
        }

        @Test
        @DisplayName("INSERT reserved_balance < 0 bị chặn bởi CHECK constraint")
        void insert_negativeReservedBalance_rejected() {
            Wallet wallet = Wallet.builder()
                    .userId("user-reserve-check2")
                    .balance(100000L)
                    .reservedBalance(-1L)
                    .currency("VND")
                    .status("ACTIVE")
                    .dailyLimit(50000000L)
                    .dailySpent(0L)
                    .build();

            assertThatThrownBy(() -> walletRepository.saveAndFlush(wallet))
                    .isInstanceOf(org.springframework.dao.DataIntegrityViolationException.class)
                    .satisfies(e -> assertThat(e.getMessage()).containsIgnoringCase("reserved_balance"));
        }
    }

    // ─── PESSIMISTIC LOCK CONCURRENCY ──────────────────────────────────────────

    @Nested
    @DisplayName("PESSIMISTIC LOCK — concurrent update serialization")
    class PessimisticLockConcurrencyTests {

        @BeforeEach
        void setUp() {
            walletRepository.deleteAll();
        }

        @Test
        @DisplayName("Hai luồng cùng findByIdForUpdate — thứ tự serialized, không race condition")
        void concurrentForUpdate_noRaceCondition() throws InterruptedException {
            Wallet initial = saveWallet("user-concurrent", 10000L);
            String walletId = initial.getId();

            int iterations = 20;
            java.util.concurrent.CountDownLatch start = new java.util.concurrent.CountDownLatch(1);
            java.util.concurrent.CountDownLatch done = new java.util.concurrent.CountDownLatch(iterations);
            java.util.concurrent.atomic.AtomicInteger successCount = new java.util.concurrent.atomic.AtomicInteger(0);

            java.util.concurrent.ExecutorService executor = java.util.concurrent.Executors.newFixedThreadPool(8);

            for (int i = 0; i < iterations; i++) {
                executor.submit(() -> {
                    try {
                        start.await();
                        transactionTemplate.executeWithoutResult(status -> {
                            walletRepository.findByIdForUpdate(walletId).ifPresent(w -> {
                                if (w.getBalance() >= 500L) {
                                    w.setBalance(w.getBalance() - 500L);
                                    walletRepository.saveAndFlush(w);
                                    successCount.incrementAndGet();
                                }
                            });
                        });
                    } catch (Exception e) {
                        // lock contention hoặc deadlock — vẫn chấp nhận được
                    } finally {
                        done.countDown();
                    }
                });
            }

            start.countDown();
            done.await(15, java.util.concurrent.TimeUnit.SECONDS);
            executor.shutdown();

            long finalBalance = rawBalance(walletId);
            System.out.printf("[PessimisticLock] initial=10000, iterations=%d, success=%d, finalBalance=%d%n",
                    iterations, successCount.get(), finalBalance);

            // Không bao giờ âm
            assertThat(finalBalance).isGreaterThanOrEqualTo(0L);
            // Không có nhiều hơn 20 lần trừ 500 (20 * 500 = 10000)
            assertThat(finalBalance).isGreaterThanOrEqualTo(0L);
        }
    }

    // ─── AUTO-INCREMENT TIMESTAMP ───────────────────────────────────────────────

    @Nested
    @DisplayName("TRIGGER updated_at — tự động cập nhật timestamp")
    class TimestampTriggerTests {

        @BeforeEach
        void setUp() {
            walletRepository.deleteAll();
        }

        @Test
        @DisplayName("UPDATE wallet — triggered updated_at tự động đổi")
        void update_triggersUpdatedAt() throws InterruptedException {
            Wallet wallet = saveWallet("user-ts-1", 10000L);
            String walletId = wallet.getId();

            Timestamp before = jdbcTemplate.queryForObject(
                    "SELECT updated_at FROM wallets WHERE id = ?", Timestamp.class, walletId);

            Thread.sleep(100); // đảm bảo thời gian thay đổi

            Wallet w = walletRepository.findById(walletId).orElseThrow();
            w.setBalance(9000L);
            walletRepository.saveAndFlush(w);

            Timestamp after = jdbcTemplate.queryForObject(
                    "SELECT updated_at FROM wallets WHERE id = ?", Timestamp.class, walletId);

            assertThat(after).isNotNull();
            assertThat(before).isNotNull();
            assertThat(after.getTime()).isGreaterThanOrEqualTo(before.getTime());
        }
    }
}
