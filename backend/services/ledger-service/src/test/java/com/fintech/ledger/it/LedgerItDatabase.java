package com.fintech.ledger.it;

import org.flywaydb.core.Flyway;
import org.testcontainers.containers.PostgreSQLContainer;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.UUID;

/**
 * Cung cấp một database thật (PostgreSQL) để chạy integration test:
 * - Ưu tiên JDBC URL truyền vào qua -Dledger.it.jdbcUrl (+ -Dledger.it.user / -Dledger.it.pass)
 *   cho môi trường không có Docker (container build/CI) — DB phải chạy sẵn và schema sẽ được
 *   áp bằng Flyway V1 (idempotent).
 * - Nếu không có URL: tự khởi container PostgreSQL (Testcontainers) + apply migration V1.
 * Endpoint test ghi dữ liệu bằng transaction id UUID random nên các test dùng chung DB không xung đột.
 */
public final class LedgerItDatabase {

    private static final String URL_PROP = "ledger.it.jdbcUrl";
    private static final String USER_PROP = "ledger.it.user";
    private static final String PASS_PROP = "ledger.it.pass";

    private static PostgreSQLContainer<?> embeddedPostgres;
    private static boolean migrated;

    private LedgerItDatabase() {
    }

    public static synchronized String jdbcUrl() {
        if (System.getProperty(URL_PROP) != null) {
            return System.getProperty(URL_PROP);
        }
        if (embeddedPostgres == null) {
            embeddedPostgres = new PostgreSQLContainer<>("postgres:16-alpine")
                    .withDatabaseName("ewallet_ledger_db")
                    .withUsername("ledger_owner")
                    .withPassword("ledger_owner");
            embeddedPostgres.start();
        }
        return embeddedPostgres.getJdbcUrl();
    }

    public static synchronized String user() {
        return System.getProperty(USER_PROP, "ledger_owner");
    }

    public static synchronized String password() {
        return System.getProperty(PASS_PROP, "ledger_owner");
    }

    /** Áp migration V1 (idempotent nếu DB đã có flyway history) */
    public static synchronized void migrate() {
        if (migrated) {
            return;
        }
        Flyway.configure()
                .dataSource(jdbcUrl(), user(), password())
                .locations("classpath:db/migration")
                .load()
                .migrate();
        migrated = true;
    }

    public static Connection ownerConnection() throws SQLException {
        migrate();
        return DriverManager.getConnection(jdbcUrl(), user(), password());
    }

    public static UUID randomId() {
        return UUID.randomUUID();
    }
}
