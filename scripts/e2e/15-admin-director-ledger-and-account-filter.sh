#!/usr/bin/env bash
# ==============================================================================
# 🏛️ SEN HỒNG CORE BANKING - KIỂM THỬ E2E DỮ LIỆU THẬT
# KỊCH BẢN: QUẢN TRỊ SỔ CÁI KÉP & BỘ LỌC TÀI KHOẢN CHO ADMIN / GIÁM ĐỐC
# ==============================================================================
# Mục tiêu kiểm thử:
#   1. Giám đốc/Admin tra cứu Sổ Cái Kép (Double-Entry Ledger):
#      - Đối soát toàn sổ: Tổng Nợ = Tổng Có, Delta = 0.00 VND (balance-check)
#      - Tổng hợp phát sinh Nợ TK 1011 / Có TK 4211 (summary)
#      - Danh sách tài khoản Sổ Cái Kép (accounts)
#      - Danh sách chứng từ ghi sổ (journal entries)
#   2. Bộ lọc tài khoản cho Admin / Giám đốc (Account Filter):
#      - Lọc theo từ khóa: SĐT / Tên khách hàng / Mã ví
#      - Lọc theo trạng thái: ACTIVE / BLOCKED
#      - Lọc theo khoảng số dư: minBalance / maxBalance
#   3. Quyền quản trị Giám đốc: Khóa (LOCK/BLOCK) và Mở khóa (UNLOCK/ACTIVE) tài khoản ví
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Gateway Base URL
GATEWAY_URL="${GATEWAY_URL:-http://localhost:8080}"

# ANSI Colors
BOLD='\033[1m'
NC='\033[0m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'

echo -e "${CYAN}${BOLD}"
echo "=============================================================================="
echo "🏛️  KIỂM THỬ E2E: SỔ CÁI KÉP & BỘ LỌC TÀI KHOẢN CHO ADMIN / GIÁM ĐỐC"
echo "    Cổng vào: API Gateway :8080 | Microservices + Database-per-service"
echo "=============================================================================="
echo -e "${NC}"

# ------------------------------------------------------------------------------
# BƯỚC 0: TẠO TOKEN CHO GIÁM ĐỐC (ROLE_MANAGER / ADMIN)
# ------------------------------------------------------------------------------
echo -e "${BLUE}▶ [AD-00] KHỞI TẠO TOKEN XÁC THỰC GIÁM ĐỐC (MANAGER1)${NC}"
bash "$SCRIPT_DIR/generate-staff-tokens.sh" > /dev/null 2>&1
source "$SCRIPT_DIR/.staff_tokens.env"

if [ -z "${MANAGER1_TOKEN:-}" ]; then
    echo -e "${RED}❌ Không lấy được token Giám đốc!${NC}"
    exit 1
fi
echo -e "  • Token Giám đốc: ${MANAGER1_TOKEN:0:20}... (ROLE_MANAGER)"
echo -e "  ${GREEN}✓ [PASSED] Khởi tạo phiên làm việc Giám đốc thành công!${NC}\n"

# ------------------------------------------------------------------------------
# KỊCH BẢN 1: ĐỐI SOÁT SỔ CÁI KÉP BẢO TOÀN (LEDGER BALANCE RECONCILIATION)
# ------------------------------------------------------------------------------
echo -e "${BLUE}▶ [AD-01] ĐỐI SOÁT SỔ CÁI KÉP TOÀN DIỆN (DELTA = 0.00 VND)${NC}"

BALANCE_CHECK_RESP=$(curl -s -X GET "${GATEWAY_URL}/api/v1/ledger/accounts/balance-check" \
    -H "Authorization: Bearer ${MANAGER1_TOKEN}")

echo "$BALANCE_CHECK_RESP" | python3 -c '
import sys, json
data = json.load(sys.stdin)
if not data.get("success", False) and data.get("code") != 200:
    print("❌ Lỗi API balance-check:", data)
    sys.exit(1)
payload = data.get("data", {})
balanced = payload.get("balanced", False)
total_debit = float(payload.get("totalDebit", 0))
total_credit = float(payload.get("totalCredit", 0))
delta = float(payload.get("delta", abs(total_debit - total_credit)))
print(f"  • Tổng Nợ (Debit):   {total_debit:,.2f} VND")
print(f"  • Tổng Có (Credit):  {total_credit:,.2f} VND")
print(f"  • Sai lệch (Delta):  {delta:,.2f} VND")
print(f"  • Trạng thái:        Balanced = {balanced}")
if not balanced or delta != 0.0:
    print("❌ Sổ cái bị lệch delta != 0!")
    sys.exit(1)
'
echo -e "  ${GREEN}✓ [PASSED] AD-01: Định luật bất biến kế toán bảo toàn tuyệt đối: Delta = 0.00 VND!${NC}\n"

# ------------------------------------------------------------------------------
# KỊCH BẢN 2: TỔNG PHÁT SINH SỔ CÁI & DANH SÁCH CHỨNG TỪ (JOURNAL ENTRIES)
# ------------------------------------------------------------------------------
echo -e "${BLUE}▶ [AD-02] TỔNG PHÁT SINH SỔ CÁI VÀ CHỨNG TỪ GHI SỔ (JOURNAL ENTRIES)${NC}"

CASH_SUMMARY_RESP=$(curl -s -X GET "${GATEWAY_URL}/api/v1/ledger/cash-summary" \
    -H "Authorization: Bearer ${MANAGER1_TOKEN}")

echo "$CASH_SUMMARY_RESP" | python3 -c '
import sys, json
data = json.load(sys.stdin)
payload = data.get("data", {})
debit_1011 = float(payload.get("debit1011", 0))
credit_4211 = float(payload.get("credit4211", 0))
total_entries = payload.get("totalEntries", 0)
total_postings = payload.get("totalPostings", 0)
print(f"  • Nợ TK 1011 (Quỹ tiền mặt): {debit_1011:,.2f} VND")
print(f"  • Có TK 4211 (Ví khách hàng): {credit_4211:,.2f} VND")
print(f"  • Tổng số chứng từ ghi sổ:   {total_entries} chứng từ")
print(f"  • Tổng số bút toán hạch toán: {total_postings} bút toán")
if total_entries <= 0:
    print("❌ Không có chứng từ ghi sổ nào!")
    sys.exit(1)
'

# Kiểm tra danh sách chứng từ
ENTRIES_RESP=$(curl -s -X GET "${GATEWAY_URL}/api/v1/ledger/entries" \
    -H "Authorization: Bearer ${MANAGER1_TOKEN}")

echo "$ENTRIES_RESP" | python3 -c '
import sys, json
data = json.load(sys.stdin)
entries = data.get("data", [])
print(f"  • Đã tải {len(entries)} chứng từ ghi sổ chi tiết từ Sổ cái kép")
if len(entries) > 0:
    first = entries[0]
    tx_id = first.get("transactionId", "")
    st = first.get("status", "")
    print(f"  • Chứng từ mẫu: Mã tx={tx_id}, status={st}")
'
echo -e "  ${GREEN}✓ [PASSED] AD-02: Truy vấn tổng hợp phát sinh và danh sách chứng từ thành công!${NC}\n"

# ------------------------------------------------------------------------------
# KỊCH BẢN 3: GIÁM ĐỐC TRA CỨU TOÀN BỘ DANH MỤC TÀI KHOẢN VÍ KHÁCH HÀNG
# ------------------------------------------------------------------------------
echo -e "${BLUE}▶ [AD-03] GIÁM ĐỐC TRA CỨU DANH MỤC TOÀN BỘ TÀI KHOẢN KHÁCH HÀNG${NC}"

ACCOUNTS_RESP=$(curl -s -X GET "${GATEWAY_URL}/api/v1/wallets/admin/accounts" \
    -H "Authorization: Bearer ${MANAGER1_TOKEN}")

echo "$ACCOUNTS_RESP" | python3 -c '
import sys, json
data = json.load(sys.stdin)
if not data.get("success", False):
    print("❌ Lỗi API danh mục tài khoản:", data.get("message"))
    sys.exit(1)
accounts = data.get("data", [])
print(f"  • Tổng số tài khoản khách hàng tìm thấy trong hệ thống: {len(accounts)}")
if len(accounts) == 0:
    print("❌ Không tìm thấy tài khoản nào!")
    sys.exit(1)
for acc in accounts[:3]:
    an = acc.get("accountNumber")
    cn = acc.get("customerName")
    pn = acc.get("phoneNumber")
    bal = float(acc.get("balance", 0))
    st = acc.get("status")
    print(f"    - Ví: {an} | Tên: {cn} | SĐT: {pn} | Số dư: {bal:,.2f} VND | Trạng thái: {st}")
'
echo -e "  ${GREEN}✓ [PASSED] AD-03: Lấy danh mục tài khoản khách hàng cho Giám đốc thành công!${NC}\n"

# ------------------------------------------------------------------------------
# KỊCH BẢN 4: BỘ LỌC TÀI KHOẢN NÂNG CAO (KEYWORD, STATUS, SỐ DƯ)
# ------------------------------------------------------------------------------
echo -e "${BLUE}▶ [AD-04] BỘ LỌC TÀI KHOẢN: TỪ KHÓA, TRẠNG THÁI & KHOẢNG SỐ DƯ${NC}"

# 4.1. Lọc theo từ khóa (Số điện thoại của Alice: 0901234567)
FILTER_PHONE_RESP=$(curl -s -X GET "${GATEWAY_URL}/api/v1/wallets/admin/accounts?keyword=0901234567" \
    -H "Authorization: Bearer ${MANAGER1_TOKEN}")

echo "$FILTER_PHONE_RESP" | python3 -c '
import sys, json
data = json.load(sys.stdin)
accounts = data.get("data", [])
print(f"  • Kết quả lọc keyword=0901234567: {len(accounts)} tài khoản")
if len(accounts) == 0:
    print("❌ Không tìm thấy Alice theo số điện thoại!")
    sys.exit(1)
assert "0901234567" in accounts[0].get("phoneNumber", "")
name = accounts[0].get("customerName")
acc_no = accounts[0].get("accountNumber")
print(f"    -> Đúng tài khoản: {name} ({acc_no})")
'

# 4.2. Lọc theo trạng thái ACTIVE
FILTER_ACTIVE_RESP=$(curl -s -X GET "${GATEWAY_URL}/api/v1/wallets/admin/accounts?status=ACTIVE" \
    -H "Authorization: Bearer ${MANAGER1_TOKEN}")

echo "$FILTER_ACTIVE_RESP" | python3 -c '
import sys, json
data = json.load(sys.stdin)
accounts = data.get("data", [])
print(f"  • Kết quả lọc status=ACTIVE: {len(accounts)} tài khoản đang hoạt động")
for acc in accounts:
    if acc.get("status") != "ACTIVE":
        an = acc.get("accountNumber")
        st = acc.get("status")
        print(f"❌ Tài khoản {an} có trạng thái {st} không phải ACTIVE!")
        sys.exit(1)
'

# 4.3. Lọc theo khoảng số dư tối thiểu (minBalance = 10,000,000 VND)
FILTER_BALANCE_RESP=$(curl -s -X GET "${GATEWAY_URL}/api/v1/wallets/admin/accounts?minBalance=10000000" \
    -H "Authorization: Bearer ${MANAGER1_TOKEN}")

echo "$FILTER_BALANCE_RESP" | python3 -c '
import sys, json
data = json.load(sys.stdin)
accounts = data.get("data", [])
print(f"  • Kết quả lọc minBalance=10,000,000 VND: {len(accounts)} tài khoản")
for acc in accounts:
    bal = float(acc.get("balance", 0))
    an = acc.get("accountNumber")
    cn = acc.get("customerName")
    if bal < 10000000:
        print(f"❌ Tài khoản {an} có số dư {bal} < 10,000,000!")
        sys.exit(1)
    print(f"    - {cn}: {bal:,.2f} VND >= 10M")
'
echo -e "  ${GREEN}✓ [PASSED] AD-04: Bộ lọc tài khoản đa tiêu chí hoạt động chính xác 100%!${NC}\n"

# ------------------------------------------------------------------------------
# KỊCH BẢN 5: QUẢN TRỊ VIÊN KHÓA VÀ MỞ KHÓA TÀI KHOẢN (LOCK & UNLOCK)
# ------------------------------------------------------------------------------
echo -e "${BLUE}▶ [AD-05] QUYỀN GIÁM ĐỐC: KHÓA VÀ MỞ KHÓA TÀI KHOẢN VÍ (MAKER-CHECKER AML)${NC}"

# Lấy 1 tài khoản ví để thử nghiệm khóa/mở khóa
TARGET_WALLET_ID=$(echo "$ACCOUNTS_RESP" | python3 -c '
import sys, json
accounts = json.load(sys.stdin).get("data", [])
for acc in accounts:
    if acc.get("status") == "ACTIVE":
        print(acc.get("walletId", acc.get("id", "")))
        break
')

echo "  • Tài khoản ví mục tiêu: ${TARGET_WALLET_ID}"

# 5.1. Khóa tài khoản ví
LOCK_RESP=$(curl -s -X POST "${GATEWAY_URL}/api/v1/wallets/admin/accounts/${TARGET_WALLET_ID}/status?status=BLOCKED" \
    -H "Authorization: Bearer ${MANAGER1_TOKEN}")

echo "$LOCK_RESP" | python3 -c '
import sys, json
data = json.load(sys.stdin)
if not data.get("success", False):
    print("❌ Lỗi khóa tài khoản ví:", data.get("message"))
    sys.exit(1)
msg = data.get("message")
print(f"  • Phản hồi khóa tài khoản: {msg}")
assert data.get("data", {}).get("status") == "BLOCKED"
'

# 5.2. Mở khóa lại tài khoản ví về ACTIVE
UNLOCK_RESP=$(curl -s -X POST "${GATEWAY_URL}/api/v1/wallets/admin/accounts/${TARGET_WALLET_ID}/status?status=ACTIVE" \
    -H "Authorization: Bearer ${MANAGER1_TOKEN}")

echo "$UNLOCK_RESP" | python3 -c '
import sys, json
data = json.load(sys.stdin)
if not data.get("success", False):
    print("❌ Lỗi mở khóa tài khoản ví:", data.get("message"))
    sys.exit(1)
msg = data.get("message")
print(f"  • Phản hồi mở khóa tài khoản: {msg}")
assert data.get("data", {}).get("status") == "ACTIVE"
'

echo -e "  ${GREEN}✓ [PASSED] AD-05: Khóa và Mở khóa tài khoản bởi Giám đốc thành công an toàn!${NC}\n"

echo -e "${GREEN}${BOLD}"
echo "=============================================================================="
echo "🎉 TỔNG KẾT: TOÀN BỘ 5/5 KỊCH BẢN QUẢN TRỊ SỔ CÁI & BỘ LỌC TÀI KHOẢN ĐẠT 100%!"
echo "=============================================================================="
echo -e "${NC}"
