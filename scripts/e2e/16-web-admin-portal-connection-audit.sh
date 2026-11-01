#!/usr/bin/env bash
# ==============================================================================
# 🏛️ SEN HỒNG CORE BANKING — TOÀN DIỆN KIỂM SOÁT KẾT NỐI WEB QUẢN TRỊ VIÊN
# Kịch bản E2E kiểm chứng 100% kết nối giữa Web Quản trị (:5173) và Backend Gateway (:8080)
# ==============================================================================

set -eo pipefail

PORTAL_URL="${PORTAL_URL:-http://localhost:5173}"
GATEWAY_URL="${GATEWAY_URL:-http://localhost:8080}"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BLUE}${BOLD}"
echo "=============================================================================="
echo "🌐 BÁO CÁO AUDIT CHUYÊN SÂU: KẾT NỐI TOÀN DIỆN WEB QUẢN TRỊ VIÊN (PORT :5173)"
echo "   Proxy downstream: API Gateway :8080 | 6 Microservices + 5 Databases"
echo "=============================================================================="
echo -e "${NC}"

# ------------------------------------------------------------------------------
# 1. KIỂM TRA WEB DEV SERVER & PROXY ROUTING
# ------------------------------------------------------------------------------
echo -e "${YELLOW}▶ [AUDIT-01] KIỂM TRA SẴN SÀNG CỦA WEB QUẢN TRỊ & PROXY VITE${NC}"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "${PORTAL_URL}/" || echo "000")
if [ "$HTTP_CODE" != "200" ]; then
    echo -e "${RED}❌ Web Quản trị không phản hồi tại ${PORTAL_URL} (HTTP ${HTTP_CODE})!${NC}"
    exit 1
fi
echo -e "  • Web Quản trị đang phục vụ tại: ${PORTAL_URL} (HTTP 200 OK)"
echo -e "  ${GREEN}✓ [PASSED] AUDIT-01: Web Dev Server Vite đang hoạt động ổn định!${NC}\n"

# ------------------------------------------------------------------------------
# 2. XÁC THỰC CÁN BỘ & CẤP TOKEN JWT (TELLER & MANAGER)
# ------------------------------------------------------------------------------
echo -e "${YELLOW}▶ [AUDIT-02] XÁC THỰC CÁN BỘ & CẤP TOKEN JWT (TELLER & MANAGER)${NC}"

# 2.1. Đăng nhập Teller
TELLER_LOGIN_RESP=$(curl -s -X POST "${PORTAL_URL}/api/v1/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"username": "teller1", "password": "DemoPass#2026!"}')

TELLER_TOKEN=$(echo "$TELLER_LOGIN_RESP" | python3 -c 'import sys, json; print(json.load(sys.stdin).get("data", {}).get("token", ""))')
TELLER_NAME=$(echo "$TELLER_LOGIN_RESP" | python3 -c 'import sys, json; print(json.load(sys.stdin).get("data", {}).get("fullName", ""))')
TELLER_ID=$(echo "$TELLER_LOGIN_RESP" | python3 -c 'import sys, json; print(json.load(sys.stdin).get("data", {}).get("userId", ""))')

if [ -z "$TELLER_TOKEN" ]; then
    echo -e "${RED}❌ Lỗi đăng nhập Teller qua Web Proxy! Phản hồi: ${TELLER_LOGIN_RESP}${NC}"
    exit 1
fi
echo -e "  • Giao dịch viên: ${BOLD}${TELLER_NAME}${NC} (ID: ${TELLER_ID})"

# 2.2. Đăng nhập Manager
MANAGER_LOGIN_RESP=$(curl -s -X POST "${PORTAL_URL}/api/v1/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"username": "manager1", "password": "DemoPass#2026!"}')

MANAGER_TOKEN=$(echo "$MANAGER_LOGIN_RESP" | python3 -c 'import sys, json; print(json.load(sys.stdin).get("data", {}).get("token", ""))')
MANAGER_NAME=$(echo "$MANAGER_LOGIN_RESP" | python3 -c 'import sys, json; print(json.load(sys.stdin).get("data", {}).get("fullName", ""))')
MANAGER_ID=$(echo "$MANAGER_LOGIN_RESP" | python3 -c 'import sys, json; print(json.load(sys.stdin).get("data", {}).get("userId", ""))')

if [ -z "$MANAGER_TOKEN" ]; then
    echo -e "${RED}❌ Lỗi đăng nhập Manager qua Web Proxy! Phản hồi: ${MANAGER_LOGIN_RESP}${NC}"
    exit 1
fi
echo -e "  • Kiểm soát viên: ${BOLD}${MANAGER_NAME}${NC} (ID: ${MANAGER_ID})"
echo -e "  ${GREEN}✓ [PASSED] AUDIT-02: Đăng nhập & phân quyền cán bộ qua Proxy 5173 thành công!${NC}\n"

# ------------------------------------------------------------------------------
# 3. KÉT QUỸ TIỀN MẶT & NẠP TIỀN TẠI QUẦY (MAKER AUTO-APPROVE <= 50M)
# ------------------------------------------------------------------------------
echo -e "${YELLOW}▶ [AUDIT-03] KÉT QUỸ TIỀN MẶT & NẠP TIỀN TẠI QUẦY (<= 50,000,000 VND)${NC}"

# 3.1. Đọc báo cáo két quỹ
VAULT_RESP=$(curl -s -X GET "${PORTAL_URL}/api/v1/cash/vault-summary" \
    -H "Authorization: Bearer ${TELLER_TOKEN}")

echo "$VAULT_RESP" | python3 -c '
import sys, json
data = json.load(sys.stdin).get("data", {})
cur = float(data.get("currentBalance", 0))
tot = float(data.get("totalCashIn", 0))
cnt = data.get("successCount", 0)
print(f"  • Két quỹ hiện tại: {cur:,.2f} VND (Tổng thu: +{tot:,.2f} VND, {cnt} GD thành công)")
'

# 3.2. Nạp tiền mặt tại quầy 5,000,000 VND cho Alice Nguyen (0901234567)
IDEM_DEP="idem_audit_5m_$(date +%s)_$RANDOM"
CREATE_DEP_RESP=$(curl -s -X POST "${PORTAL_URL}/api/v1/cash/deposits" \
    -H "Authorization: Bearer ${TELLER_TOKEN}" \
    -H "Content-Type: application/json" \
    -H "Idempotency-Key: ${IDEM_DEP}" \
    -d "{
        \"accountNumber\": \"0901234567\",
        \"customerName\": \"Alice Nguyen\",
        \"amount\": 5000000,
        \"currency\": \"VND\",
        \"branchId\": \"BR_Q1\",
        \"makerId\": \"${TELLER_ID}\",
        \"note\": \"Nop tien mat kiem thu audit Web Portal\",
        \"idempotencyKey\": \"${IDEM_DEP}\"
    }")

echo "$CREATE_DEP_RESP" | python3 -c '
import sys, json
data = json.load(sys.stdin)
if not data.get("success", False):
    print("❌ Lỗi nạp tiền mặt tại quầy:", data.get("message"))
    sys.exit(1)
dep = data.get("data", {})
code = dep.get("depositCode")
status = dep.get("status")
amt = float(dep.get("amount", 0))
print(f"  • Lập lệnh nạp {amt:,.2f} VND thành công! Mã: {code} | Trạng thái: {status}")
assert status == "COMPLETED"
'
echo -e "  ${GREEN}✓ [PASSED] AUDIT-03: Nạp tiền quầy tự động duyệt <= 50M thành công!${NC}\n"

# ------------------------------------------------------------------------------
# 4. MAKER-CHECKER DUYỆT GIAO DỊCH LỚN (> 50,000,000 VND)
# ------------------------------------------------------------------------------
echo -e "${YELLOW}▶ [AUDIT-04] NGUYÊN TẮC 4 MẮT (MAKER-CHECKER): LỆNH NẠP 80,000,000 VND${NC}"

# 4.1. Teller lập lệnh nạp 80M (> 50M -> Chờ duyệt PENDING_APPROVAL)
IDEM_80M="idem_audit_80m_$(date +%s)_$RANDOM"
DEP_80M_RESP=$(curl -s -X POST "${PORTAL_URL}/api/v1/cash/deposits" \
    -H "Authorization: Bearer ${TELLER_TOKEN}" \
    -H "Content-Type: application/json" \
    -H "Idempotency-Key: ${IDEM_80M}" \
    -d "{
        \"accountNumber\": \"0909876543\",
        \"customerName\": \"Bob Tran\",
        \"amount\": 80000000,
        \"currency\": \"VND\",
        \"branchId\": \"BR_Q1\",
        \"makerId\": \"${TELLER_ID}\",
        \"note\": \"Nop tien mat so luong lon can Kiem soat vien duyet\",
        \"idempotencyKey\": \"${IDEM_80M}\"
    }")

DEP_80M_ID=$(echo "$DEP_80M_RESP" | python3 -c '
import sys, json
data = json.load(sys.stdin).get("data", {})
status = data.get("status")
dep_id = data.get("id")
print(f"  • Lệnh nạp 80M: Trạng thái={status} (Chờ Manager phê duyệt)")
assert status == "PENDING_APPROVAL"
print(dep_id)
' | tail -n 1)

# 4.2. Kiểm tra chặn vi phạm Maker == Checker (Four-Eyes Principle)
VIOLATION_RESP=$(curl -s -X POST "${PORTAL_URL}/api/v1/cash/deposits/${DEP_80M_ID}/approve" \
    -H "Authorization: Bearer ${TELLER_TOKEN}" \
    -H "Content-Type: application/json" \
    -H "X-User-Role: ROLE_MANAGER" \
    -d "{
        \"checkerId\": \"${TELLER_ID}\",
        \"role\": \"ROLE_MANAGER\"
    }")

echo "$VIOLATION_RESP" | python3 -c '
import sys, json
data = json.load(sys.stdin)
if data.get("success", True) == False or "vi phạm" in data.get("message", "").lower() or "violation" in data.get("message", "").lower():
    print("  • Hệ thống đã chặn đứng Maker tự duyệt lệnh của chính mình (Maker != Checker)")
else:
    print("❌ Lỗi: Hệ thống không chặn được Maker tự duyệt!")
    sys.exit(1)
'

# 4.3. Manager phê duyệt lệnh hợp lệ
APPROVE_RESP=$(curl -s -X POST "${PORTAL_URL}/api/v1/cash/deposits/${DEP_80M_ID}/approve" \
    -H "Authorization: Bearer ${MANAGER_TOKEN}" \
    -H "Content-Type: application/json" \
    -H "X-User-Role: ROLE_MANAGER" \
    -d "{
        \"checkerId\": \"${MANAGER_ID}\",
        \"role\": \"ROLE_MANAGER\"
    }")

echo "$APPROVE_RESP" | python3 -c '
import sys, json
data = json.load(sys.stdin)
if not data.get("success", False):
    print("❌ Lỗi phê duyệt lệnh nạp 80M:", data.get("message"))
    sys.exit(1)
dep = data.get("data", {})
status = dep.get("status")
checker = dep.get("checkerName", dep.get("checkerId"))
print(f"  • Kiểm soát viên phê duyệt thành công: Trạng thái={status} | Checker={checker}")
assert status == "COMPLETED"
'
echo -e "  ${GREEN}✓ [PASSED] AUDIT-04: Quy chuẩn Maker-Checker hoạt động nghiêm ngặt và chuẩn xác!${NC}\n"

# ------------------------------------------------------------------------------
# 5. ĐỐI SOÁT BẤT BIẾN SỔ CÁI KÉP (DELTA = 0.00 VND)
# ------------------------------------------------------------------------------
echo -e "${YELLOW}▶ [AUDIT-05] ĐỐI SOÁT BẤT BIẾN SỔ CÁI KÉP QUA WEB PROXY${NC}"
LEDGER_RECON_RESP=$(curl -s -X GET "${PORTAL_URL}/api/v1/ledger/accounts/balance-check" \
    -H "Authorization: Bearer ${TELLER_TOKEN}")

echo "$LEDGER_RECON_RESP" | python3 -c '
import sys, json
data = json.load(sys.stdin).get("data", {})
debit = float(data.get("totalDebit", 0))
credit = float(data.get("totalCredit", 0))
delta = abs(debit - credit)
balanced = data.get("balanced", False)
print(f"  • Tổng Nợ (Debit):  {debit:,.2f} VND")
print(f"  • Tổng Có (Credit): {credit:,.2f} VND")
print(f"  • Sai lệch (Delta): {delta:,.2f} VND")
print(f"  • Trạng thái cân bằng: {balanced}")
assert delta == 0.0
assert balanced == True
'

# Kiểm tra danh sách chứng từ ghi sổ
JOURNAL_RESP=$(curl -s -X GET "${PORTAL_URL}/api/v1/ledger/entries" \
    -H "Authorization: Bearer ${TELLER_TOKEN}")

echo "$JOURNAL_RESP" | python3 -c '
import sys, json
entries = json.load(sys.stdin).get("data", [])
print(f"  • Tổng số chứng từ ghi sổ trong sổ cái: {len(entries)} chứng từ")
assert len(entries) > 0
'
echo -e "  ${GREEN}✓ [PASSED] AUDIT-05: Sổ cái kép bảo toàn tuyệt đối: Delta = 0.00 VND!${NC}\n"

# ------------------------------------------------------------------------------
# 6. BỘ LỌC TÀI KHOẢN KHÁCH HÀNG & AML LOCK/UNLOCK
# ------------------------------------------------------------------------------
echo -e "${YELLOW}▶ [AUDIT-06] BỘ LỌC TÀI KHOẢN KHÁCH HÀNG & KIỂM SOÁT KHÓA VÍ (AML)${NC}"

# 6.1. Tra cứu danh mục
ACCOUNTS_RESP=$(curl -s -X GET "${PORTAL_URL}/api/v1/wallets/admin/accounts" \
    -H "Authorization: Bearer ${MANAGER_TOKEN}")

TARGET_WALLET_ID=$(echo "$ACCOUNTS_RESP" | python3 -c '
import sys, json
accounts = json.load(sys.stdin).get("data", [])
print(f"  • Tổng số tài khoản khách hàng hiển thị: {len(accounts)}")
for a in accounts:
    cn = a.get("customerName")
    pn = a.get("phoneNumber")
    bal = float(a.get("balance", 0))
    st = a.get("status")
    print(f"    - {cn} ({pn}): {bal:,.2f} VND | Trạng thái: {st}")
if accounts:
    print(accounts[0].get("walletId", accounts[0].get("id", "")))
' | tail -n 1)

# 6.2. Thử nghiệm khóa ví phòng chống rửa tiền AML
LOCK_RESP=$(curl -s -X POST "${PORTAL_URL}/api/v1/wallets/admin/accounts/${TARGET_WALLET_ID}/status?status=BLOCKED" \
    -H "Authorization: Bearer ${MANAGER_TOKEN}")

echo "$LOCK_RESP" | python3 -c '
import sys, json
data = json.load(sys.stdin)
msg = data.get("message")
st = data.get("data", {}).get("status")
print(f"  • Thao tác khóa ví: {msg} | Status: {st}")
assert st == "BLOCKED"
'

# 6.3. Mở khóa ví lại về ACTIVE
UNLOCK_RESP=$(curl -s -X POST "${PORTAL_URL}/api/v1/wallets/admin/accounts/${TARGET_WALLET_ID}/status?status=ACTIVE" \
    -H "Authorization: Bearer ${MANAGER_TOKEN}")

echo "$UNLOCK_RESP" | python3 -c '
import sys, json
data = json.load(sys.stdin)
msg = data.get("message")
st = data.get("data", {}).get("status")
print(f"  • Thao tác mở khóa ví: {msg} | Status: {st}")
assert st == "ACTIVE"
'
echo -e "  ${GREEN}✓ [PASSED] AUDIT-06: Bộ lọc và quyền khóa/mở khóa tài khoản đạt 100%!${NC}\n"

# ------------------------------------------------------------------------------
# 7. CHUYỂN TIỀN P2P QUA PROXY WEB QUẢN TRỊ
# ------------------------------------------------------------------------------
echo -e "${YELLOW}▶ [AUDIT-07] CHUYỂN TIỀN P2P VÍ ĐIỆN TỬ QUA PROXY WEB QUẢN TRỊ${NC}"

# 7.1. Tra cứu ví người nhận (0901234567)
REC_RESP=$(curl -s -X GET "${PORTAL_URL}/api/v1/wallets/recipient-info?phoneNumber=0901234567" \
    -H "Authorization: Bearer ${TELLER_TOKEN}")

ALICE_UID=$(echo "$REC_RESP" | python3 -c 'import sys, json; print(json.load(sys.stdin).get("data", {}).get("ownerId", ""))')

# 7.2. Tra cứu ví người gửi (0909876543)
SENDER_RESP=$(curl -s -X GET "${PORTAL_URL}/api/v1/wallets/recipient-info?phoneNumber=0909876543" \
    -H "Authorization: Bearer ${TELLER_TOKEN}")

BOB_UID=$(echo "$SENDER_RESP" | python3 -c 'import sys, json; print(json.load(sys.stdin).get("data", {}).get("ownerId", ""))')

echo "  • Người gửi: Bob Tran (${BOB_UID})"
echo "  • Người nhận: Alice Nguyen (${ALICE_UID})"

IDEM_P2P="idem_audit_p2p_$(date +%s)_$RANDOM"
P2P_RESP=$(curl -s -X POST "${PORTAL_URL}/api/v1/payments/transfer" \
    -H "Authorization: Bearer ${TELLER_TOKEN}" \
    -H "Content-Type: application/json" \
    -H "Idempotency-Key: ${IDEM_P2P}" \
    -d "{
        \"sourceUserId\": \"${BOB_UID}\",
        \"targetUserId\": \"${ALICE_UID}\",
        \"amount\": 100000,
        \"currency\": \"VND\",
        \"note\": \"Chuyen tien P2P audit Web Quan Tri\",
        \"idempotencyKey\": \"${IDEM_P2P}\"
    }")

echo "$P2P_RESP" | python3 -c '
import sys, json
data = json.load(sys.stdin)
if not data.get("success", False):
    print("❌ Lỗi chuyển tiền P2P:", data.get("message"))
    sys.exit(1)
tx = data.get("data", {})
tx_id = tx.get("transactionId")
st = tx.get("status")
print(f"  • Chuyển tiền P2P thành công: Mã={tx_id} | Trạng thái={st}")
assert st == "SUCCESS"
'
echo -e "  ${GREEN}✓ [PASSED] AUDIT-07: Chuyển tiền P2P qua Web Proxy thành công mượt mà!${NC}\n"

echo -e "${GREEN}${BOLD}"
echo "=============================================================================="
echo "🎉 TỔNG KẾT BÁO CÁO AUDIT: TOÀN BỘ 7/7 KỊCH BẢN KẾT NỐI WEB QUẢN TRỊ ĐẠT 100%!"
echo "   Hệ thống sẵn sàng vận hành thực tế tại: ${PORTAL_URL}"
echo "=============================================================================="
echo -e "${NC}"

