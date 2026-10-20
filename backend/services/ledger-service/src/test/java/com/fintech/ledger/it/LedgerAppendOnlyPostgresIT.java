package com.fintech.ledger.it;

import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfSystemProperty;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Xác minh bất biến APPEND-ONLY của ewallet_ledger_db trên PostgreSQL thật:
 * - Role ứng dụng ledger_app_user chỉ có SELECT + INSERT → UPDATE/DELETE bị Database
 *   từ chối ở cấp quyền DB, không thể sửa/xóa chứng từ kế toán.
 * - Trigger duy trì số dư vẫn hoạt động khi INSERT bằng role bị giới hạn (SECURITY DEFINER).
 * - ΣDebit = ΣCredit ở cấp SQL sau khi ghi chứng từ cân đối + idempotency theo eventId.
 *
 * Chạy: ./mvnw -pl services/ledger-service test
 *        -Dtest=LedgerAppendOnlyPostgresIT
 *        -Dledger.it.jdbcUrl=jdbc:postgresql://localhost:55432/ewallet_ledger_db
 *        -Dledger.it.user=ledger_owner -Dledger.it.pass=ledger_owner
 */
@EnabledIfSystemProperty(named = "ledger.it.jdbcUrl", matches = ".+",
        disabledReason = "Cần PostgreSQL thật: truyền -Dledger.it.jdbcUrl/-Dledger.it.user/-Dledger.it.pass")
class LedgerAppendOnlyPostgresIT {

    private static final String LIMITED_USER = "ledger_app_user";
    private static final String LIMITED_PASS = "LimitedPass2025!";

    @BeforeAll
    static void setUpOwnerAndLimitedRole() throws SQLException {
        try (Connection owner = LedgerItDatabase.ownerConnection();
             Statement st = owner.createStatement()) {
            st.execute("DO $$ BEGIN "
                    + "IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '" + LIMITED_USER + "') THEN "
                    + "CREATE ROLE " + LIMITED_USER + " LOGIN PASSWORD '" + LIMITED_PASS + "'; "
                    + "END IF; END $$;");
            // Append-only đúng nghĩa: chỉ SELECT + INSERT, cấm UPDATE/DELETE
            st.execute("GRANT USAGE ON SCHEMA public TO " + LIMITED_USER);
            st.execute("GRANT SELECT, INSERT ON ALL TABLES IN SCHEMA public TO " + LIMITED_USER);
            st.execute("GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO " + LIMITED_USER);
        }
    }

    @Test
    void restrictedRoleCanInsertAndSelectButCannotUpdateOrDelete() throws SQLException {
        try (Connection limited = limitedConnection()) {
            UUID bank = insertAccount(limited, "ASSET");

            // SELECT được phép
            try (Statement st = limited.createStatement();
                 ResultSet rs = st.executeQuery("SELECT count(*) FROM ledger_accounts")) {
                assertThat(rs.next()).isTrue();
                assertThat(rs.getInt(1)).isGreaterThan(0);
            }

            // UPDATE bị từ chối ở cấp quyền DB
            assertThatThrownBy(() -> {
                PreparedStatement ps = limited.prepareStatement(
                        "UPDATE ledger_accounts SET balance = 999999 WHERE id = ?");
                ps.setObject(1, bank);
                ps.executeUpdate();
            }).isInstanceOf(SQLException.class)
                    .hasMessageContaining("permission denied");

            // DELETE bị từ chối ở cấp quyền DB
            assertThatThrownBy(() -> {
                PreparedStatement ps = limited.prepareStatement(
                        "DELETE FROM ledger_accounts WHERE id = ?");
                ps.setObject(1, bank);
                ps.executeUpdate();
            }).isInstanceOf(SQLException.class)
                    .hasMessageContaining("permission denied");

            // Chứng từ sổ cái cũng bất biến: không xóa được (fixture là chứng từ hoàn chỉnh, cân Nợ/Có)
            BalancesAndEntry fixture = postBalancedEntry(limited,
                    "tx-append-" + UUID.randomUUID().toString().substring(0, 8), "ref-" + UUID.randomUUID());
            UUID entry = fixture.entryId();
            assertThatThrownBy(() -> {
                PreparedStatement ps = limited.prepareStatement(
                        "DELETE FROM journal_entries WHERE id = ?");
                ps.setObject(1, entry);
                ps.executeUpdate();
            }).isInstanceOf(SQLException.class)
                    .hasMessageContaining("permission denied");

            // và không sửa được
            assertThatThrownBy(() -> {
                PreparedStatement ps = limited.prepareStatement(
                        "UPDATE journal_entries SET description = 'tampered' WHERE id = ?");
                ps.setObject(1, entry);
                ps.executeUpdate();
            }).isInstanceOf(SQLException.class)
                    .hasMessageContaining("permission denied");
        }
    }

    @Test
    void balanceIsMaintainedByTriggerEvenWithRestrictedRole() throws SQLException {
        // Trigger SECURITY DEFINER cho phép role append-only INSERT posting mà không cần quyền UPDATE
        try (Connection limited = limitedConnection()) {
            BalancesAndEntry fixture = postBalancedEntry(limited,
                    "tx-bal-" + UUID.randomUUID().toString().substring(0, 8), "ref-" + UUID.randomUUID());

            assertThat(queryBalance(limited, fixture.bankId())).isEqualByComparingTo("150000.00");
            assertThat(queryBalance(limited, fixture.walletId())).isEqualByComparingTo("150000.00");
        }
    }

    @Test
    void debitMustEqualCreditAtSqlLevel() throws SQLException {
        String txId = "tx-sum-" + UUID.randomUUID().toString().substring(0, 8);
        try (Connection limited = limitedConnection()) {
            BalancesAndEntry small = postBalancedEntry(limited, txId, "ref-" + UUID.randomUUID());

            BigDecimal debit = sumByTransactionAndSide(limited, txId, "DEBIT");
            BigDecimal credit = sumByTransactionAndSide(limited, txId, "CREDIT");
            assertThat(debit).isEqualByComparingTo(credit);
            assertThat(debit).isEqualByComparingTo("150000.00")
                    .isEqualByComparingTo(queryBalance(limited, small.bankId()).abs());
        }
    }

    @Test
    void duplicateEventIdIsRejectedByUniqueIndex() throws SQLException {
        String reference = "dup-" + UUID.randomUUID();
        try (Connection limited = limitedConnection()) {
            postBalancedEntry(limited, "tx-dup-a-" + UUID.randomUUID().toString().substring(0, 8), reference);

            // Idempotency: ghi trùng eventId phải bị unique index chặn
            assertThatThrownBy(() ->
                    postBalancedEntry(limited, "tx-dup-b-" + UUID.randomUUID().toString().substring(0, 8), reference))
                    .isInstanceOf(SQLException.class)
                    .hasMessageContaining("uq_journal_entries_reference");
        }
    }

    @Test
    void secondPostedEntryForSameTransactionIsRejected() throws SQLException {
        String txId = "tx-2nd-" + UUID.randomUUID().toString().substring(0, 8);
        try (Connection limited = limitedConnection()) {
            postBalancedEntry(limited, txId, "ref-a-" + UUID.randomUUID());

            // Chống double-posting: 1 giao dịch chỉ được 1 chứng từ status POSTED
            assertThatThrownBy(() ->
                    postBalancedEntry(limited, txId, "ref-b-" + UUID.randomUUID()))
                    .isInstanceOf(SQLException.class)
                    .hasMessageContaining("uq_journal_entries_transaction_posted");
        }
    }

    // ---------------------------------------------------------------------------

    /** Chứng từ hoàn chỉnh: 1 tài khoản ASSET + 1 LIABILITY + entry + 2 bút toán balanced */
    private static BalancesAndEntry postBalancedEntry(Connection limited, String txId, String reference)
            throws SQLException {
        UUID bankId = insertAccount(limited, "ASSET");
        UUID walletId = insertAccount(limited, "LIABILITY");
        UUID entryId = insertEntry(limited, txId, reference);
        insertPosting(limited, entryId, bankId, "DEBIT", "150000.00");
        insertPosting(limited, entryId, walletId, "CREDIT", "150000.00");
        return new BalancesAndEntry(bankId, walletId, entryId);
    }

    private record BalancesAndEntry(UUID bankId, UUID walletId, UUID entryId) {
    }

    private static Connection limitedConnection() throws SQLException {
        String url = LedgerItDatabase.jdbcUrl();
        int slash = url.lastIndexOf('/');
        return DriverManager.getConnection(url.substring(0, slash) + "/ewallet_ledger_db",
                LIMITED_USER, LIMITED_PASS);
    }

    private static UUID insertAccount(Connection c, String type) throws SQLException {
        UUID id = UUID.randomUUID();
        try (PreparedStatement ps = c.prepareStatement(
                "INSERT INTO ledger_accounts(id, code, name, type, currency) VALUES (?,?,?,?, 'VND')")) {
            ps.setObject(1, id);
            ps.setString(2, "AO-" + UUID.randomUUID().toString().substring(0, 8));
            ps.setString(3, "Append-only IT account");
            ps.setString(4, type);
            ps.executeUpdate();
        }
        return id;
    }

    private static UUID insertEntry(Connection c, String transactionId, String reference) throws SQLException {
        UUID id = UUID.randomUUID();
        try (PreparedStatement ps = c.prepareStatement(
                "INSERT INTO journal_entries(id, transaction_id, description, reference_number, status) "
                        + "VALUES (?,?,?,?, 'POSTED')")) {
            ps.setObject(1, id);
            ps.setString(2, transactionId);
            ps.setString(3, "Append-only IT entry for " + transactionId);
            ps.setString(4, reference);
            ps.executeUpdate();
        }
        return id;
    }

    private static void insertPosting(Connection c, UUID entryId, UUID accountId, String side, String amount)
            throws SQLException {
        try (PreparedStatement ps = c.prepareStatement(
                "INSERT INTO ledger_postings(journal_entry_id, account_id, side, amount, currency) "
                        + "VALUES (?,?,?,?, 'VND')")) {
            ps.setObject(1, entryId);
            ps.setObject(2, accountId);
            ps.setString(3, side);
            ps.setBigDecimal(4, new BigDecimal(amount));
            ps.executeUpdate();
        }
    }

    private static BigDecimal queryBalance(Connection c, UUID accountId) throws SQLException {
        try (PreparedStatement ps = c.prepareStatement(
                "SELECT balance FROM ledger_accounts WHERE id = ?")) {
            ps.setObject(1, accountId);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getBigDecimal("balance");
            }
        }
    }

    private static BigDecimal sumByTransactionAndSide(Connection c, String txId, String side) throws SQLException {
        try (PreparedStatement ps = c.prepareStatement("""
                SELECT COALESCE(SUM(p.amount), 0)
                FROM ledger_postings p
                JOIN journal_entries e ON e.id = p.journal_entry_id
                WHERE e.transaction_id = ? AND p.side = ?
                """)) {
            ps.setString(1, txId);
            ps.setString(2, side);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getBigDecimal(1);
            }
        }
    }
}
