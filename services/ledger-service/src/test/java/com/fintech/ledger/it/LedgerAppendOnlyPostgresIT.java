package com.fintech.ledger.it;

import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfSystemProperty;

import java.math.BigDecimal;
import java.sql.Connection;
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
 *   từ chối ở cấp권 DB, không thể sửa/xóa chứng từ kế toán.
 * - Trigger duy trì số dư vẫn hoạt động khi INSERT bằng role bị giới hạn (SECURITY DEFINER).
 * - ΣDebit = ΣCredit ở cấp SQL sau khi ghi chứng từ cân đối.
 */
@EnabledIfSystemProperty(named = "ledger.it.jdbcUrl", matches = ".+",
        disabledReason = "Chạy khi có PostgreSQL thật qua -Dledger.it.jdbcUrl")
class LedgerAppendOnlyPostgresIT {

    private static final String LIMITED_USER = "ledger_app_user";
    private static final String LIMITED_PASS = "Limited#Pass2025!";

    @BeforeAll
    static void setUpOwnerAndLimitedRole() throws SQLException {
        try (Connection owner = LedgerItDatabase.ownerConnection();
             Statement st = owner.createStatement()) {
            st.execute("DO $$ BEGIN "
                    + "IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '" + LIMITED_USER + "') THEN "
                    + "CREATE ROLE " + LIMITED_USER + " LOGIN PASSWORD '" + LIMITED_PASS + "'; "
                    + "END IF; END $$;");
            // Append-only đúng nghĩa: chỉ SELECT + INSERT, REVOKE UPDATE/DELETE
            st.execute("GRANT USAGE ON SCHEMA public TO " + LIMITED_USER);
            st.execute("GRANT SELECT, INSERT ON ALL TABLES IN SCHEMA public TO " + LIMITED_USER);
            st.execute("GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO " + LIMITED_USER);
        }
    }

    private static Connection limitedConnection() throws SQLException {
        String url = LedgerItDatabase.jdbcUrl();
        int slash = url.lastIndexOf('/');
        String base = url.substring(0, slash);
        return DriverManager.getConnection(base + "/ewallet_ledger_db", LIMITED_USER, LIMITED_PASS);
    }

    private static UUID insertAccount(Connection c, String code, String type) throws SQLException {
        UUID id = UUID.randomUUID();
        try (PreparedStatement ps = c.prepareStatement(
                "INSERT INTO ledger_accounts(id, code, name, type, currency) VALUES (?,?,?,?,?)")) {
            ps.setObject(1, id);
            ps.setString(2, code);
            ps.setString(3, code);
            ps.setString(4, type);
            ps.setString(5, "VND");
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
            ps.setString(3, "Test entry " + transactionId);
            ps.setString(4, reference);
            ps.executeUpdate();
        }
        return id;
    }

    private static void insertPosting(Connection c, UUID entryId, UUID accountId, String side, String amount)
            throws SQLException {
        try (PreparedStatement ps = c.prepareStatement(
                "INSERT INTO ledger_postings(journal_entry_id, account_id, side, amount, currency) "
                        + "VALUES (?,?,?,?,?)")) {
            ps.setObject(1, entryId);
            ps.setObject(2, accountId);
            ps.setString(3, side);
            ps.setBigDecimal(4, new BigDecimal(amount));
            ps.setString(5, "VND");
            ps.executeUpdate();
        }
    }

    @Test
    void restrictedRoleCanInsertAndSelectButCannotUpdateOrDelete() throws SQLException {
        // Given: role giới hạn có thể INSERT được
        try (Connection limited = limitedConnection()) {
            UUID bank = insertAccount(limited, "AO-" + UUID.randomUUID().toString().substring(0, 8), "ASSET");

            // SELECT được phép
            try (Statement st = limited.createStatement();
                 ResultSet rs = st.executeQuery("SELECT count(*) FROM ledger_accounts")) {
                assertThat(rs.next()).isTrue();
                assertThat(rs.getInt(1)).isGreaterThan(0);
            }

            // Then: UPDATE bị từ chối
            assertThatThrownBy(() -> {
                PreparedStatement ps = limited.prepareStatement(
                        "UPDATE ledger_accounts SET balance = 999999 WHERE id = ?");
                ps.setObject(1, bank);
                ps.executeUpdate();
            }).isInstanceOf(SQLException.class)
                    .hasMessageContaining("permission denied");

            // Then: DELETE bị từ chối
            assertThatThrownBy(() -> {
                PreparedStatement ps = limited.prepareStatement(
                        "DELETE FROM ledger_accounts WHERE id = ?");
                ps.setObject(1, bank);
                ps.executeUpdate();
            }).isInstanceOf(SQLException.class)
                    .hasMessageContaining("permission denied");

            // Then: UPDATE/DELETE trên bảng chứng từ + bút toán cũng bị từ chối
            UUID entry = insertEntry(limited, "tx-append-only-" + UUID.randomUUID().toString().substring(0, 8),
                    "ref-" + UUID.randomUUID().toString().substring(0, 8));
            assertThatThrownBy(() -> {
                PreparedStatement ps = limited.prepareStatement(
                        "DELETE FROM journal_entries WHERE id = ?");
                ps.setObject(1, entry);
                ps.executeUpdate();
            }).isInstanceOf(SQLException.class)
                    .hasMessageContaining("permission denied");
        }
    }

    @Test
    void balanceIsMaintainedByTriggerEvenWithRestrictedRole() throws SQLException {
        // Security Definer trigger cho phép role "append-only" INSERT posting mà không cần quyền UPDATE
        try (Connection limited = limitedConnection()) {
            UUID bank = insertAccount(limited, "AO-" + UUID.randomUUID().toString().substring(0, 8), "ASSET");
            UUID wallet = insertAccount(limited, "AO-" + UUID.randomUUID().toString().substring(0, 8), "LIABILITY");
            UUID entry = insertEntry(limited, "tx-bal-" + UUID.randomUUID().toString().substring(0, 8),
                    "ref-" + UUID.randomUUID().toString().substring(0, 8));
            insertPosting(limited, entry, bank, "DEBIT", "150000.00");
            insertPosting(limited, entry, wallet, "CREDIT", "150000.00");

            // Then: trigger cập nhật số dư đúng công thức kế toán
            assertThat(queryBalance(limited, bank)).isEqualByComparingTo("150000.00");
            assertThat(queryBalance(limited, wallet)).isEqualByComparingTo("150000.00");
        }
    }

    @Test
    void debitMustEqualCreditAtSqlLevel() throws SQLException {
        String txId = "tx-sum-" + UUID.randomUUID().toString().substring(0, 8);
        try (Connection limited = limitedConnection()) {
            UUID bank = insertAccount(limited, "AO-" + UUID.randomUUID().toString().substring(0, 8), "ASSET");
            UUID wallet = insertAccount(limited, "AO-" + UUID.randomUUID().toString().substring(0, 8), "LIABILITY");
            UUID entry = insertEntry(limited, txId, "ref-" + UUID.randomUUID().toString().substring(0, 8));
            insertPosting(limited, entry, bank, "DEBIT", "420000.50");
            insertPosting(limited, entry, wallet, "CREDIT", "420000.50");

            // ΣDebit của chứng từ = ΣCredit của chứng từ (đối soát theo giao dịch)
            BigDecimal debit = sumByTransactionAndSide(limited, txId, "DEBIT");
            BigDecimal credit = sumByTransactionAndSide(limited, txId, "CREDIT");
            assertThat(debit).isEqualByComparingTo(credit);
            assertThat(debit).isEqualByComparingTo("420000.50");
        }
    }

    @Test
    void duplicateEventIdIsRejectedWithAppendedUniqueIndex() throws SQLException {
        String reference = "uq-" + UUID.randomUUID();
        try (Connection limited = limitedConnection()) {
            insertEntry(limited, "tx-dup-" + UUID.randomUUID().toString().substring(0, 8), reference);

            // Ghi trùng eventId → bị unique index chặn (idempotency)
            assertThatThrownBy(() -> insertEntry(limited, "tx-dup-other", reference))
                    .isInstanceOf(SQLException.class)
                    .hasMessageContaining("uq_journal_entries_reference");
        }
    }

    @Test
    void partiallyUniqueIndexAllowsReversalForSameTransaction() throws SQLException {
        String txId = "tx-rev-" + UUID.randomUUID().toString().substring(0, 8);
        try (Connection limited = limitedConnection()) {
            String ref = "ref-" + UUID.randomUUID().toString().substring(0, 8);
            insertEntry(limited, txId, ref);

            // Giao dịch đã có chứng từ POSTED → không được ghi thêm chứng từ gốc thứ 2
            assertThatThrownBy(() -> insertEntry(limited, txId, "ref-" + UUID.randomUUID(),
                    "POSTED"))
                    .isInstanceOf(SQLException.class)
                    .hasMessageContaining("uq_journal_entries_transaction_posted");
        }
    }

    private void insertEntry(Connection c, String txId, String ref, String status) throws SQLException {
        DB(c, "INSERT INTO journal_entries(transaction_id, description, reference_number, status) "
                + "VALUES (?,?,?,?)", txId, "Test", ref, status);
    }

    private void DB(Connection c, String sql, Object... params) throws SQLException {
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            for (int i = 0; i < params.length; i++) {
                ps.setObject(i + 1, params[i]);
            }
            ps.executeUpdate();
        }
    }
}
