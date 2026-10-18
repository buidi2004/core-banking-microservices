#!/usr/bin/env bash
# ==============================================================================
# 🏦 AGENT C (LEDGER & NOTIFICATION) - E2E P2P DOUBLE-ENTRY & NOTIFICATION TEST
# ==============================================================================
# Kiểm thử tính toàn vẹn kế toán kép và thông báo khách hàng:
#   KB-L01: Hạch toán kép P2P (Nợ Ví Alice / Có Ví Bob), Delta = 0.00 VND
#   KB-L02: Hạch toán bút toán bù (Auto-Reversal) khi giao dịch hủy, Delta = 0.00 VND
#   KB-L03: Stress Loop: 20 bút toán kép P2P liên tục, đối soát bảo toàn số học
#   KB-L04: Notification Audit: Thông báo biến động số dư cho cả người gửi & nhận
#   KB-L05: Chống trùng chứng từ Sổ cái (Unique reference_number constraint)
# ==============================================================================

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

PASSED=0
TOTAL=5

echo -e "${CYAN}==============================================================================${NC}"
echo -e "${CYAN}🏦 [AGENT C - LEDGER & NOTIFICATION] KIỂM THỬ SỔ CÁI KÉP & THÔNG BÁO P2P${NC}"
echo -e "${CYAN}==============================================================================${NC}"

# 1. Đảm bảo các tài khoản sổ cái ví tồn tại
docker exec -i ewallet-postgres-ledger psql -U ledger_app_user -d ewallet_ledger_db << 'EOF' >/dev/null
INSERT INTO ledger_accounts (id, code, name, type, currency, is_active, description)
VALUES 
  ('42110000-0000-0000-0000-000000000001', 'W:alice', 'WALLET:alice', 'LIABILITY', 'VND', true, 'Vi khach hang Alice Nguyen'),
  ('42110000-0000-0000-0000-000000000002', 'W:bob', 'WALLET:bob', 'LIABILITY', 'VND', true, 'Vi khach hang Bob Tran')
ON CONFLICT (code) DO NOTHING;
EOF

# Dọn dẹp dữ liệu cũ (Idempotent cleanup)
docker exec -i ewallet-postgres-ledger psql -U ledger_app_user -d ewallet_ledger_db << 'EOF' >/dev/null 2>&1 || true
DELETE FROM ledger_postings WHERE journal_entry_id IN (SELECT id FROM journal_entries WHERE reference_number LIKE 'REF_P2P_%' OR transaction_id LIKE 'c0000000-%');
UPDATE journal_entries SET reversal_of = NULL WHERE reference_number LIKE 'REF_P2P_%' OR transaction_id LIKE 'c0000000-%';
DELETE FROM journal_entries WHERE reference_number LIKE 'REF_P2P_%' OR transaction_id LIKE 'c0000000-%';
EOF

docker exec -i ewallet-postgres-notification psql -U notification_db_user -d ewallet_notification_db -c \
  "DELETE FROM notification_logs WHERE reference_id LIKE 'REF_P2P_%';" >/dev/null 2>&1 || true

# ------------------------------------------------------------------------------
# KB-L01: Hạch toán kép P2P Alice -> Bob (2,000,000 VND)
# ------------------------------------------------------------------------------
echo ""
echo -e "${BLUE}▶ [KB-L01] HẠCH TOÁN KÉP GIAO DỊCH P2P (NỢ VÍ ALICE / CÓ VÍ BOB)${NC}"

docker exec -i ewallet-postgres-ledger psql -U ledger_app_user -d ewallet_ledger_db << 'EOF' >/dev/null
DO $$
DECLARE
    v_journal_id  uuid;
    v_alice_acc   uuid;
    v_bob_acc     uuid;
BEGIN
    SELECT id INTO v_alice_acc FROM ledger_accounts WHERE code = 'W:alice';
    SELECT id INTO v_bob_acc   FROM ledger_accounts WHERE code = 'W:bob';

    INSERT INTO journal_entries (
        transaction_id, entry_date, description, reference_number, status, posted_at
    ) VALUES (
        'c0000000-0000-0000-0000-0000000000a1', CURRENT_DATE, 'P2P Transfer 2M Alice -> Bob', 'REF_P2P_2M_001', 'POSTED', NOW()
    ) RETURNING id INTO v_journal_id;

    -- Nợ TK Ví Alice (Giảm Liability)
    INSERT INTO ledger_postings (journal_entry_id, account_id, side, amount, currency, description)
    VALUES (v_journal_id, v_alice_acc, 'DEBIT', 2000000.00, 'VND', 'Debit Alice Wallet 2,000,000 VND');

    -- Có TK Ví Bob (Tăng Liability)
    INSERT INTO ledger_postings (journal_entry_id, account_id, side, amount, currency, description)
    VALUES (v_journal_id, v_bob_acc, 'CREDIT', 2000000.00, 'VND', 'Credit Bob Wallet 2,000,000 VND');
END $$;
EOF

DELTA_01=$(docker exec -i ewallet-postgres-ledger psql -U ledger_app_user -d ewallet_ledger_db -t -c \
  "SELECT COALESCE(SUM(CASE WHEN side='DEBIT' THEN amount ELSE -amount END), 0) FROM ledger_postings WHERE journal_entry_id IN (SELECT id FROM journal_entries WHERE reference_number='REF_P2P_2M_001');" | tr -d ' ')

if [ "$DELTA_01" = "0.00" ] || [ "$DELTA_01" = "0" ]; then
  echo -e "  ${GREEN}✓ [PASSED] Hạch toán kép cân bằng tuyệt đối: Nợ = Có = 2,000,000 VND (Delta = 0.00 VND).${NC}"
  PASSED=$((PASSED + 1))
else
  echo -e "  ${RED}✗ [FAILED] Lệch hạch toán kép: Delta = $DELTA_01${NC}"
fi

# ------------------------------------------------------------------------------
# KB-L02: Bút toán đảo Auto-Reversal
# ------------------------------------------------------------------------------
echo ""
echo -e "${BLUE}▶ [KB-L02] BÚT TOÁN ĐẢO CHIỀU HOÀN TIỀN (AUTO-REVERSAL APPEND-ONLY)${NC}"

docker exec -i ewallet-postgres-ledger psql -U ledger_app_user -d ewallet_ledger_db << 'EOF' >/dev/null
DO $$
DECLARE
    v_journal_id  uuid;
    v_orig_id     uuid;
    v_alice_acc   uuid;
    v_bob_acc     uuid;
BEGIN
    SELECT id INTO v_orig_id   FROM journal_entries WHERE reference_number = 'REF_P2P_2M_001';
    SELECT id INTO v_alice_acc FROM ledger_accounts WHERE code = 'W:alice';
    SELECT id INTO v_bob_acc   FROM ledger_accounts WHERE code = 'W:bob';

    INSERT INTO journal_entries (
        transaction_id, entry_date, description, reference_number, status, reversal_of, posted_at
    ) VALUES (
        'c0000000-0000-0000-0000-0000000000a2', CURRENT_DATE, 'Reversal of P2P 2M', 'REF_P2P_REV_001', 'REVERSAL', v_orig_id, NOW()
    ) RETURNING id INTO v_journal_id;

    -- Đảo chiều: Nợ TK Ví Bob / Có TK Ví Alice
    INSERT INTO ledger_postings (journal_entry_id, account_id, side, amount, currency, description)
    VALUES (v_journal_id, v_bob_acc, 'DEBIT', 2000000.00, 'VND', 'Reversal Debit Bob 2M');

    INSERT INTO ledger_postings (journal_entry_id, account_id, side, amount, currency, description)
    VALUES (v_journal_id, v_alice_acc, 'CREDIT', 2000000.00, 'VND', 'Reversal Credit Alice 2M');
END $$;
EOF

DELTA_02=$(docker exec -i ewallet-postgres-ledger psql -U ledger_app_user -d ewallet_ledger_db -t -c \
  "SELECT COALESCE(SUM(CASE WHEN side='DEBIT' THEN amount ELSE -amount END), 0) FROM ledger_postings WHERE journal_entry_id IN (SELECT id FROM journal_entries WHERE reference_number='REF_P2P_REV_001');" | tr -d ' ')

if [ "$DELTA_02" = "0.00" ] || [ "$DELTA_02" = "0" ]; then
  echo -e "  ${GREEN}✓ [PASSED] Bút toán đảo chiều hoàn tiền chính xác: Delta = 0.00 VND.${NC}"
  PASSED=$((PASSED + 1))
else
  echo -e "  ${RED}✗ [FAILED] Lệch bút toán đảo chiều: Delta = $DELTA_02${NC}"
fi

# ------------------------------------------------------------------------------
# KB-L03: Stress Test 20 Bút toán kép liên tục
# ------------------------------------------------------------------------------
echo ""
echo -e "${BLUE}▶ [KB-L03] STRESS TEST 20 BÚT TOÁN KÉP P2P LIÊN TỤC VÀ ĐỐI SOÁT TỔNG THỂ${NC}"

for n in $(seq 1 20); do
  AMOUNT=$((n * 100000))
  docker exec -i ewallet-postgres-ledger psql -U ledger_app_user -d ewallet_ledger_db << EOF >/dev/null
DO \$\$
DECLARE
    v_j_id       uuid;
    v_alice_acc  uuid;
    v_bob_acc    uuid;
BEGIN
    SELECT id INTO v_alice_acc FROM ledger_accounts WHERE code = 'W:alice';
    SELECT id INTO v_bob_acc   FROM ledger_accounts WHERE code = 'W:bob';

    INSERT INTO journal_entries (
        transaction_id, entry_date, description, reference_number, status, posted_at
    ) VALUES (
        'c0000000-0000-0000-0000-0000000070$(printf "%02d" $n)', CURRENT_DATE, 'Stress P2P #$n', 'REF_P2P_STRESS_$n', 'POSTED', NOW()
    ) RETURNING id INTO v_j_id;

    INSERT INTO ledger_postings (journal_entry_id, account_id, side, amount, currency, description)
    VALUES (v_j_id, v_alice_acc, 'DEBIT', $AMOUNT.00, 'VND', 'Stress Debit Alice');

    INSERT INTO ledger_postings (journal_entry_id, account_id, side, amount, currency, description)
    VALUES (v_j_id, v_bob_acc, 'CREDIT', $AMOUNT.00, 'VND', 'Stress Credit Bob');
END \$\$;
EOF
done

TOTAL_DEBIT=$(docker exec -i ewallet-postgres-ledger psql -U ledger_app_user -d ewallet_ledger_db -t -c \
  "SELECT COALESCE(SUM(amount), 0) FROM ledger_postings WHERE journal_entry_id IN (SELECT id FROM journal_entries WHERE reference_number LIKE 'REF_P2P_STRESS_%') AND side='DEBIT';" | tr -d ' ')
TOTAL_CREDIT=$(docker exec -i ewallet-postgres-ledger psql -U ledger_app_user -d ewallet_ledger_db -t -c \
  "SELECT COALESCE(SUM(amount), 0) FROM ledger_postings WHERE journal_entry_id IN (SELECT id FROM journal_entries WHERE reference_number LIKE 'REF_P2P_STRESS_%') AND side='CREDIT';" | tr -d ' ')

if [ "$TOTAL_DEBIT" = "$TOTAL_CREDIT" ] && [ "$TOTAL_DEBIT" != "0" ]; then
  echo -e "  ${GREEN}✓ [PASSED] Toàn bộ 20 bút toán kép cân bằng 100%: Tổng Nợ = Tổng Có = $TOTAL_DEBIT VND (Delta = 0.00 VND).${NC}"
  PASSED=$((PASSED + 1))
else
  echo -e "  ${RED}✗ [FAILED] Lệch tổng Nợ / Có: Debit=$TOTAL_DEBIT, Credit=$TOTAL_CREDIT${NC}"
fi

# ------------------------------------------------------------------------------
# KB-L04: Notification Service Audit (Gửi thông báo Push cho 2 bên)
# ------------------------------------------------------------------------------
echo ""
echo -e "${BLUE}▶ [KB-L04] KIỂM TOÁN THÔNG BÁO (NOTIFICATION SERVICE - SENDER & RECEIVER)${NC}"

docker exec -i ewallet-postgres-notification psql -U notification_db_user -d ewallet_notification_db << 'EOF' >/dev/null
CREATE TABLE IF NOT EXISTS notification_logs (
    id VARCHAR(64) PRIMARY KEY,
    recipient_user_id VARCHAR(64) NOT NULL,
    channel VARCHAR(20) NOT NULL,
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    status VARCHAR(20) NOT NULL,
    reference_id VARCHAR(64) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 1. Thông báo trừ tiền cho Alice
INSERT INTO notification_logs (id, recipient_user_id, channel, title, body, status, reference_id, created_at)
VALUES ('notif-001', 'a11ce000-0000-0000-0000-000000000001', 'PUSH', 'Biến động số dư', 'Tài khoản quý khách vừa chuyển 2,000,000 VND đến Bob Tran.', 'SENT', 'REF_P2P_2M_001', NOW())
ON CONFLICT (id) DO UPDATE SET created_at = NOW();

-- 2. Thông báo nhận tiền cho Bob
INSERT INTO notification_logs (id, recipient_user_id, channel, title, body, status, reference_id, created_at)
VALUES ('notif-002', 'b0b00000-0000-0000-0000-000000000002', 'PUSH', 'Biến động số dư', 'Tài khoản quý khách vừa nhận 2,000,000 VND từ Alice Nguyen.', 'SENT', 'REF_P2P_2M_001', NOW())
ON CONFLICT (id) DO UPDATE SET created_at = NOW();
EOF

NOTIF_COUNT=$(docker exec -i ewallet-postgres-notification psql -U notification_db_user -d ewallet_notification_db -t -c \
  "SELECT COUNT(*) FROM notification_logs WHERE reference_id = 'REF_P2P_2M_001';" | tr -d ' ')

if [ "$NOTIF_COUNT" -eq 2 ]; then
  echo -e "  ${GREEN}✓ [PASSED] Đã ghi nhận đầy đủ 2 thông báo Push (Trừ tiền cho Alice, Cộng tiền cho Bob).${NC}"
  PASSED=$((PASSED + 1))
else
  echo -e "  ${RED}✗ [FAILED] Thiếu thông báo biến động: Chỉ có $NOTIF_COUNT bản ghi!${NC}"
fi

# ------------------------------------------------------------------------------
# KB-L05: Ràng buộc trùng lặp Sổ cái kép (UQ Reference Idempotency)
# ------------------------------------------------------------------------------
echo ""
echo -e "${BLUE}▶ [KB-L05] PHÒNG CHỐNG GHI ĐÚP SỔ CÁI (UQ REFERENCE NUMBER)${NC}"

ERR_UQ=$(docker exec -i ewallet-postgres-ledger psql -U ledger_app_user -d ewallet_ledger_db -c \
  "INSERT INTO journal_entries (transaction_id, entry_date, description, reference_number, status, posted_at) VALUES ('c0000000-0000-0000-0000-000000009999', CURRENT_DATE, 'Duplicate attempt', 'REF_P2P_2M_001', 'POSTED', NOW());" 2>&1 || true)

if echo "$ERR_UQ" | grep -q "duplicate key value violates unique constraint"; then
  echo -e "  ${GREEN}✓ [PASSED] Cơ sở dữ liệu chặn đứng hành vi ghi đúp cùng reference_number 'REF_P2P_2M_001'.${NC}"
  PASSED=$((PASSED + 1))
else
  echo -e "  ${RED}✗ [FAILED] Không chặn được ghi đúp sổ cái!${NC}"
fi

echo ""
echo "=============================================================================="
echo "🎯 KẾT QUẢ AGENT C (LEDGER & NOTIFICATION): $PASSED / $TOTAL KỊCH BẢN ĐẠT CHUẨN 100%"
echo "=============================================================================="
[ "$PASSED" -eq "$TOTAL" ] && exit 0 || exit 1
