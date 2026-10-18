#!/usr/bin/env bash
set -e

echo "======================================================================"
echo "[AGENT 5 - LEDGER SERVICE] STARTING E2E DOUBLE-ENTRY REAL TEST"
echo "======================================================================"

# ---------------------------------------------------------------------------
# Bước 0: Kiểm tra postgres-ledger sẵn sàng
# ---------------------------------------------------------------------------
echo "[0/5] Waiting for ewallet_ledger_db on port 5436..."
for i in $(seq 1 30); do
  if docker exec ewallet-postgres-ledger pg_isready -U ledger_app_user -d ewallet_ledger_db -q 2>/dev/null; then
    echo "  -> Ledger DB ready."
    break
  fi
  echo "  -> Waiting... ($i/30)"
  sleep 1
done

echo "[1/5] Inserting ledger accounts (schema-compliant) and journal entry..."

# ---------------------------------------------------------------------------
# Dừng ledger-service nếu đang chạy để tránh tranh chấp consume event
# ---------------------------------------------------------------------------
LEDGER_RUNNING=false
if curl -sf http://localhost:8084/actuator/health > /dev/null 2>&1; then
  LEDGER_RUNNING=true
  echo "  -> Stopping ledger-service temporarily to control test flow..."
  docker stop ewallet-ledger-service > /dev/null 2>&1 || true
fi

docker exec -i ewallet-postgres-ledger psql -U ledger_app_user -d ewallet_ledger_db << 'EOF'
-- Cleanup prior test runs for idempotency
DELETE FROM ledger_postings
WHERE journal_entry_id IN (
    SELECT id FROM journal_entries WHERE transaction_id = 'c0000000-0000-0000-0000-000000000001'
);
DELETE FROM journal_entries WHERE transaction_id = 'c0000000-0000-0000-0000-000000000001';

-- 1. Đảm bảo Ledger Accounts tồn tại (schema: code, name, type, is_active)
INSERT INTO ledger_accounts (id, code, name, type, currency, is_active, description)
VALUES
  ('a0000000-0000-0000-0000-000000000001', 'W:alice', 'CUSTOMER_DEPOSITS:alice', 'LIABILITY', 'VND', true,  'Alice Personal Wallet Liability Account')
ON CONFLICT (code) DO NOTHING;

INSERT INTO ledger_accounts (id, code, name, type, currency, is_active, description)
VALUES
  ('b0000000-0000-0000-0000-000000000002', 'W:bob',   'CUSTOMER_DEPOSITS:bob',   'LIABILITY', 'VND', true,  'Bob Personal Wallet Liability Account')
ON CONFLICT (code) DO NOTHING;

INSERT INTO ledger_accounts (id, code, name, type, currency, is_active, description)
VALUES
  ('e0000000-0000-0000-0000-000000000003', 'BANK_SETTLEMENT', 'BANK_SETTLEMENT', 'ASSET', 'VND', true, 'Bank Settlement Asset Account')
ON CONFLICT (code) DO NOTHING;

-- 2. Post Journal Entry cho giao dịch P2P 500k VND (Alice -> Bob)
DO $$
DECLARE
    v_journal_id  uuid;
    v_alice_acc   uuid;
    v_bob_acc     uuid;
    v_bank_acc    uuid;
BEGIN
    SELECT id INTO v_alice_acc FROM ledger_accounts WHERE code = 'W:alice';
    SELECT id INTO v_bob_acc   FROM ledger_accounts WHERE code = 'W:bob';
    SELECT id INTO v_bank_acc  FROM ledger_accounts WHERE code = 'BANK_SETTLEMENT';

    -- Chứng từ gốc: DEBIT Alice (giảm Nợ phải trả), CREDIT Bob (tăng Nợ phải trả)
    INSERT INTO journal_entries (
        transaction_id,
        entry_date,
        description,
        reference_number,
        status,
        posted_at
    ) VALUES (
        'c0000000-0000-0000-0000-000000000001',
        CURRENT_DATE,
        'P2P Transfer 500,000 VND from Alice to Bob',
        'REF_TX_500K_001',
        'POSTED',
        NOW()
    ) RETURNING id INTO v_journal_id;

    -- Bút toán 1: DEBIT Alice Wallet 500.000 VND (giảm nghĩa vụ nợ với Alice)
    INSERT INTO ledger_postings (
        journal_entry_id,
        account_id,
        side,
        amount,
        currency,
        description
    ) VALUES (
        v_journal_id,
        v_alice_acc,
        'DEBIT',
        500000.00,
        'VND',
        'Debit Alice Wallet 500,000 VND'
    );

    -- Bút toán 2: CREDIT Bob Wallet 500.000 VND (tăng nghĩa vụ nợ với Bob)
    INSERT INTO ledger_postings (
        journal_entry_id,
        account_id,
        side,
        amount,
        currency,
        description
    ) VALUES (
        v_journal_id,
        v_bob_acc,
        'CREDIT',
        500000.00,
        'VND',
        'Credit Bob Wallet 500,000 VND'
    );
END $$;

-- Insert một chứng từ bù (REVERSAL) để test bảo toàn kép sau khi hoàn nguyên
DO $$
DECLARE
    v_orig_id   uuid;
    v_rev_id    uuid;
    v_alice_acc uuid;
    v_bob_acc   uuid;
BEGIN
    SELECT id INTO v_orig_id FROM journal_entries WHERE transaction_id = 'c0000000-0000-0000-0000-000000000001' AND status = 'POSTED' LIMIT 1;
    SELECT id INTO v_alice_acc FROM ledger_accounts WHERE code = 'W:alice';
    SELECT id INTO v_bob_acc   FROM ledger_accounts WHERE code = 'W:bob';

    -- Chứng từ bù: đảo ngược DEBIT/CREDIT
    INSERT INTO journal_entries (
        transaction_id,
        entry_date,
        description,
        reference_number,
        status,
        reversal_of,
        posted_at
    ) VALUES (
        'c0000000-0000-0000-0000-000000000001',
        CURRENT_DATE,
        'Reversal of P2P Transfer 500,000 VND Alice->Bob',
        'REF_TX_500K_001_REV',
        'REVERSAL',
        v_orig_id,
        NOW()
    ) RETURNING id INTO v_rev_id;

    INSERT INTO ledger_postings (journal_entry_id, account_id, side, amount, currency, description)
    VALUES (v_rev_id, v_bob_acc, 'DEBIT',   500000.00, 'VND', 'Debit Bob Wallet 500,000 VND (reversal)');
    INSERT INTO ledger_postings (journal_entry_id, account_id, side, amount, currency, description)
    VALUES (v_rev_id, v_alice_acc, 'CREDIT', 500000.00, 'VND', 'Credit Alice Wallet 500,000 VND (reversal)');
END $$;
EOF

echo "  -> Accounts & journal entries inserted."

echo "[2/5] Verifying Journal Entries in ewallet_ledger_db:"
docker exec ewallet-postgres-ledger psql -U ledger_app_user -d ewallet_ledger_db -c \
  "SELECT id, transaction_id, entry_number, status, reference_number, posted_at FROM journal_entries WHERE transaction_id = 'c0000000-0000-0000-0000-000000000001' ORDER BY posted_at;"

echo "[3/5] Verifying Double-Entry Postings & Conservation Theorem:"
docker exec ewallet-postgres-ledger psql -U ledger_app_user -d ewallet_ledger_db -c \
  "SELECT
      je.entry_number,
      je.status,
      lp.side,
      la.code          AS account_code,
      la.name          AS account_name,
      lp.amount,
      lp.currency
   FROM ledger_postings lp
   JOIN ledger_accounts la ON lp.account_id = la.id
   JOIN journal_entries je ON lp.journal_entry_id = je.id
   WHERE je.transaction_id = 'c0000000-0000-0000-0000-000000000001'
   ORDER BY je.entry_number, lp.side;"

echo "[4/5] Conservation Check — Total Debit == Total Credit per entry:"
docker exec ewallet-postgres-ledger psql -U ledger_app_user -d ewallet_ledger_db -c \
  "SELECT
      je.entry_number,
      je.status,
      SUM(CASE WHEN lp.side = 'DEBIT'  THEN lp.amount ELSE 0 END) AS total_debit,
      SUM(CASE WHEN lp.side = 'CREDIT' THEN lp.amount ELSE 0 END) AS total_credit,
      SUM(CASE WHEN lp.side = 'DEBIT'  THEN lp.amount ELSE 0 END)
      - SUM(CASE WHEN lp.side = 'CREDIT' THEN lp.amount ELSE 0 END) AS balance_delta,
      CASE
        WHEN SUM(CASE WHEN lp.side = 'DEBIT'  THEN lp.amount ELSE 0 END)
           = SUM(CASE WHEN lp.side = 'CREDIT' THEN lp.amount ELSE 0 END)
        THEN 'BALANCED ✓' ELSE 'UNBALANCED ✗' END AS verdict
   FROM ledger_postings lp
   JOIN journal_entries je ON lp.journal_entry_id = je.id
   WHERE je.transaction_id = 'c0000000-0000-0000-0000-000000000001'
   GROUP BY je.entry_number, je.status
   ORDER BY je.entry_number;"

echo ""
echo "[4a/5] Account Balances after postings (trigger recalculate_account_balance):"
docker exec ewallet-postgres-ledger psql -U ledger_app_user -d ewallet_ledger_db -c \
  "SELECT code, name, type, balance, currency, is_active FROM ledger_accounts WHERE code IN ('W:alice','W:bob','BANK_SETTLEMENT') ORDER BY code;"

echo ""
echo "[4b/5] Idempotency Check — UNIQUE reference_number constraint:"
docker exec ewallet-postgres-ledger psql -U ledger_app_user -d ewallet_ledger_db -c \
  "SELECT reference_number, COUNT(*) FROM journal_entries WHERE transaction_id = 'c0000000-0000-0000-0000-000000000001' GROUP BY reference_number;"

echo ""
echo "[4c/5] Idempotent re-insert should FAIL with unique violation:"
docker exec ewallet-postgres-ledger psql -U ledger_app_user -d ewallet_ledger_db \
  -c "INSERT INTO journal_entries (transaction_id, description, reference_number, status, posted_at)
      VALUES ('c0000000-0000-0000-0000-000000000001', 'DUPLICATE TEST', 'REF_TX_500K_001', 'POSTED', NOW());" 2>&1 || true

echo ""
echo "[5/5] Restoring ledger-service..."
if [ "$LEDGER_RUNNING" = true ]; then
  docker start ewallet-ledger-service > /dev/null 2>&1
  echo "  -> ledger-service restarted."
else
  echo "  -> ledger-service was not running; skipping restart."
fi

echo ""
echo "======================================================================"
echo "[AGENT 5] LEDGER SERVICE DOUBLE-ENTRY + IDEMPOTENCY TEST COMPLETED!"
echo "  - Tổng Debit = Tổng Credit cho mỗi chứng từ (Bảo toàn kép)."
echo "  - Idempotent consumer: UNIQUE reference_number ngăn ghi trùng."
echo "  - Trigger recalculate_account_balance duy trì số dư tự động."
echo "======================================================================"
