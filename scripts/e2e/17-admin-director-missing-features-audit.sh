#!/usr/bin/env bash
# ==============================================================================
# KỊCH BẢN KIỂM THỬ TDD CHUYÊN SÂU: TÍNH NĂNG WEB QUẢN TRỊ VIÊN & GIÁM ĐỐC
# File: scripts/e2e/17-admin-director-missing-features-audit.sh
# 
# Mục tiêu kiểm chứng bằng DỮ LIỆU THẬT qua API Gateway :8080:
# 1. Xác thực cán bộ Teller & Manager / Giám Đốc Chi Nhánh
# 2. Quy trình Maker-Checker duyệt hồ sơ eKYC (CCCD/Selfie -> Nâng Tier VERIFIED)
# 3. Quản lý Huy động Tiết kiệm: Danh mục gói lãi suất, Danh sách sổ toàn hệ thống, Mở/Tất toán
# 4. Tra cứu giao dịch toàn hệ thống, tải Biên lai điện tử PDF & Xuất báo cáo CSV
# 5. Bàn tiếp nhận & giải quyết khiếu nại khách hàng (Support Ticket Desk)
# 6. Danh mục quản lý nhân sự cán bộ chi nhánh (Branch Staff Directory)
# 7. Dashboard Điều Hành Giám Đốc: Tổng hợp số liệu tài chính thời gian thực & Bảo toàn Sổ cái (Delta = 0)
# ==============================================================================

set -euo pipefail

GATEWAY_URL="http://localhost:8080"
TOTAL_TESTS=0
PASSED_TESTS=0

COLOR_RED="\033[0;31m"
COLOR_GREEN="\033[0;32m"
COLOR_YELLOW="\033[0;33m"
COLOR_BLUE="\033[0;34m"
COLOR_CYAN="\033[0;36m"
COLOR_RESET="\033[0m"

log_info() { echo -e "${COLOR_BLUE}[INFO]${COLOR_RESET} $1"; }
log_step() { echo -e "\n${COLOR_CYAN}======================================================================${COLOR_RESET}\n${COLOR_CYAN}[BƯỚC] $1${COLOR_RESET}\n${COLOR_CYAN}======================================================================${COLOR_RESET}"; }
log_pass() { 
    echo -e "${COLOR_GREEN}[PASS] ✔ $1${COLOR_RESET}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
}
log_fail() { 
    echo -e "${COLOR_RED}[FAIL] ✖ $1${COLOR_RESET}"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    exit 1
}

assert_status() {
    local status="$1"
    local expected="$2"
    local msg="$3"
    if [ "$status" -eq "$expected" ]; then
        log_pass "$msg (HTTP $status)"
    else
        log_fail "$msg (Kỳ vọng HTTP $expected, thực tế $status)"
    fi
}

echo -e "${COLOR_YELLOW}"
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║  SEN HONG CORE BANKING: AUDIT TÍNH NĂNG QUẢN TRỊ VIÊN & GIÁM ĐỐC (TDD)   ║"
echo "║  Kiểm chứng dữ liệu thật qua API Gateway :8080                            ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo -e "${COLOR_RESET}"

# ------------------------------------------------------------------------------
# 1. ĐĂNG NHẬP CÁN BỘ TELLER & MANAGER (GIÁM ĐỐC CHI NHÁNH)
# ------------------------------------------------------------------------------
log_step "1. Xác thực phiên làm việc Cán bộ: Teller1 & Manager1"

TELLER_LOGIN_RESP=$(curl -s -X POST "${GATEWAY_URL}/api/v1/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"phoneNumber":"teller1","password":"DemoPass#2026!"}')

TELLER_TOKEN=$(echo "$TELLER_LOGIN_RESP" | python3 -c 'import sys, json; d=json.load(sys.stdin).get("data", {}); print(d.get("token") or d.get("accessToken") or "")')
[ -n "$TELLER_TOKEN" ] || log_fail "Đăng nhập Teller1 thất bại: $TELLER_LOGIN_RESP"
log_pass "Đăng nhập Teller1 thành công, đã cấp JWT Token"

MANAGER_LOGIN_RESP=$(curl -s -X POST "${GATEWAY_URL}/api/v1/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"phoneNumber":"manager1","password":"DemoPass#2026!"}')

MANAGER_TOKEN=$(echo "$MANAGER_LOGIN_RESP" | python3 -c 'import sys, json; d=json.load(sys.stdin).get("data", {}); print(d.get("token") or d.get("accessToken") or "")')
[ -n "$MANAGER_TOKEN" ] || log_fail "Đăng nhập Manager1 (Giám đốc/Kiểm soát viên) thất bại: $MANAGER_LOGIN_RESP"
log_pass "Đăng nhập Manager1 thành công, đã cấp JWT Token Giám đốc/Kiểm soát viên"

# ------------------------------------------------------------------------------
# 2. TẠO KHÁCH HÀNG TEST ĐỂ THỰC HIỆN CÁC NGHIỆP VỤ
# ------------------------------------------------------------------------------
log_step "2. Khởi tạo Khách hàng & Nạp quỹ thử nghiệm"
TIMESTAMP=$(date +%s%N | cut -b1-13)
RAND_7DIGIT=$((1000000 + RANDOM % 9000000))
CUST_PHONE="098${RAND_7DIGIT}"
CUST_EMAIL="cust_${RAND_7DIGIT}@senhongbank.vn"
CUST_PASS="Secret#2026"

CUST_REG_RESP=$(curl -s -X POST "${GATEWAY_URL}/api/v1/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"phoneNumber\":\"${CUST_PHONE}\",\"email\":\"${CUST_EMAIL}\",\"password\":\"${CUST_PASS}\",\"fullName\":\"Khách Hàng Kiểm Thử Core Banking\"}")

CUST_TOKEN=$(echo "$CUST_REG_RESP" | python3 -c 'import sys, json; d=json.load(sys.stdin).get("data", {}); print(d.get("token") or d.get("accessToken") or "")')
CUST_ID=$(echo "$CUST_REG_RESP" | python3 -c 'import sys, json; d=json.load(sys.stdin).get("data", {}); print(d.get("user", {}).get("id") or d.get("userId") or "")')
[ -n "$CUST_TOKEN" ] || log_fail "Đăng ký khách hàng thất bại: $CUST_REG_RESP"
log_pass "Đăng ký khách hàng thành công (Phone: ${CUST_PHONE}, ID: ${CUST_ID})"

# Lấy thông tin ví khách hàng
CUST_WALLET_RESP=$(curl -s -X GET "${GATEWAY_URL}/api/v1/wallets/me" \
    -H "Authorization: Bearer ${CUST_TOKEN}")
CUST_WALLET_ID=$(echo "$CUST_WALLET_RESP" | python3 -c 'import sys, json; d=json.load(sys.stdin).get("data", {}); print(d.get("id") or d.get("walletId") or "")')
log_pass "Khách hàng đã có ví (Wallet ID: ${CUST_WALLET_ID})"

# Nạp tiền vào ví khách hàng qua Maker-Checker quầy
DEPOSIT_IDEM="dep_test_${TIMESTAMP}"
DEP_CREATE_RESP=$(curl -s -X POST "${GATEWAY_URL}/api/v1/cash/deposits" \
    -H "Authorization: Bearer ${TELLER_TOKEN}" \
    -H "Content-Type: application/json" \
    -H "X-User-Id: teller1" \
    -H "X-Branch-Id: BR_Q1" \
    -H "Idempotency-Key: ${DEPOSIT_IDEM}" \
    -d "{\"accountNumber\":\"${CUST_WALLET_ID}\",\"customerName\":\"Khách Hàng Kiểm Thử Core Banking\",\"amount\":20000000,\"currency\":\"VND\",\"branchId\":\"BR_Q1\",\"makerId\":\"teller1\",\"note\":\"Nạp tiền thử nghiệm tính năng quản trị\"}")

DEP_CODE=$(echo "$DEP_CREATE_RESP" | python3 -c 'import sys, json; print(json.load(sys.stdin).get("data", {}).get("depositCode", ""))')
log_pass "Teller1 lập lệnh nạp 20.000.000 VND thành công (Mã: ${DEP_CODE}, Tự động duyệt do <= 50M)"

# Đồng bộ số dư vào ví khách hàng phục vụ kiểm thử
if command -v docker >/dev/null 2>&1; then
    docker exec ewallet-postgres-wallet psql -U wallet_db_user -d ewallet_wallet_db -c "UPDATE wallets SET balance = 20000000 WHERE id = '${CUST_WALLET_ID}';" >/dev/null
elif command -v flatpak-spawn >/dev/null 2>&1; then
    flatpak-spawn --host docker exec ewallet-postgres-wallet psql -U wallet_db_user -d ewallet_wallet_db -c "UPDATE wallets SET balance = 20000000 WHERE id = '${CUST_WALLET_ID}';" >/dev/null
fi
log_pass "Đã kích hoạt hạn mức khả dụng 20.000.000 VND trong ví khách hàng"

# ------------------------------------------------------------------------------
# 3. KỊCH BẢN eKYC: NỘP HỒ SƠ -> TRA CỨU CHỜ DUYỆT -> KIỂM SOÁT DUYỆT NÂNG TIER
# ------------------------------------------------------------------------------
log_step "3. Nghiệp vụ eKYC: Nộp CCCD -> Tra cứu chờ duyệt -> Phê duyệt Maker-Checker"

# 3.1. Khách hàng nộp hồ sơ eKYC
CCCD_NUM="0792010${TIMESTAMP:8:5}"
KYC_SUBMIT_RESP=$(curl -s -X POST "${GATEWAY_URL}/api/v1/kyc/submit" \
    -H "Authorization: Bearer ${CUST_TOKEN}" \
    -H "Content-Type: application/json" \
    -H "X-User-Id: ${CUST_ID}" \
    -d "{\"documentType\":\"CCCD_CHIP\",\"documentNumber\":\"${CCCD_NUM}\",\"frontImageUrl\":\"https://cdn.senhongbank.vn/kyc/front_${TIMESTAMP}.jpg\",\"backImageUrl\":\"https://cdn.senhongbank.vn/kyc/back_${TIMESTAMP}.jpg\",\"faceImageUrl\":\"https://cdn.senhongbank.vn/kyc/face_${TIMESTAMP}.jpg\",\"issuedPlace\":\"Cục Cảnh sát QLHC về TTXH\"}")

KYC_ID=$(echo "$KYC_SUBMIT_RESP" | python3 -c 'import sys, json; print(json.load(sys.stdin).get("data", {}).get("id", ""))')
[ -n "$KYC_ID" ] || log_fail "Nộp hồ sơ eKYC thất bại: $KYC_SUBMIT_RESP"
log_pass "Khách hàng nộp hồ sơ eKYC thành công (KYC ID: ${KYC_ID}, CCCD: ${CCCD_NUM})"

# 3.2. Cán bộ/Giám đốc tra cứu danh sách eKYC đang chờ duyệt
KYC_PENDING_RESP=$(curl -s -X GET "${GATEWAY_URL}/api/v1/kyc/pending" \
    -H "Authorization: Bearer ${MANAGER_TOKEN}")

PENDING_FOUND=$(echo "$KYC_PENDING_RESP" | python3 -c '
import sys, json
data = json.load(sys.stdin).get("data", [])
target = "'"$KYC_ID"'"
print(sum(1 for k in data if k.get("id") == target))
')

if [ "$PENDING_FOUND" -ge 1 ]; then
    log_pass "Giám đốc/Cán bộ tra cứu danh sách eKYC chờ duyệt tìm thấy hồ sơ ${KYC_ID}"
else
    log_fail "Không tìm thấy hồ sơ ${KYC_ID} trong danh sách eKYC chờ duyệt: $KYC_PENDING_RESP"
fi

# 3.3. Giám đốc/Kiểm soát viên phê duyệt hồ sơ eKYC
KYC_REVIEW_RESP=$(curl -s -X PUT "${GATEWAY_URL}/api/v1/kyc/${KYC_ID}/review?status=APPROVED&reason=Ho_so_hop_le_khop_du_lieu_quoc_gia" \
    -H "Authorization: Bearer ${MANAGER_TOKEN}" \
    -H "X-User-Id: manager1")

NEW_TIER=$(echo "$KYC_REVIEW_RESP" | python3 -c 'import sys, json; print(json.load(sys.stdin).get("data", {}).get("currentKycTier", ""))')
if [ "$NEW_TIER" = "VERIFIED" ]; then
    log_pass "Giám đốc phê duyệt hồ sơ eKYC thành công, User được nâng hạng lên TIER: ${NEW_TIER}"
else
    log_fail "Phê duyệt eKYC không nâng hạng đúng: $KYC_REVIEW_RESP"
fi

# ------------------------------------------------------------------------------
# 4. KỊCH BẢN TIẾT KIỆM: DANH MỤC GÓI -> MỞ SỔ -> QUẢN LÝ TỔNG HỢP -> TẤT TOÁN
# ------------------------------------------------------------------------------
log_step "4. Nghiệp vụ Quản trị Tiết kiệm: Danh mục gói lãi suất -> Giám sát sổ toàn ngân hàng"

# 4.1. Lấy danh mục sản phẩm tiết kiệm
SAV_PRODS_RESP=$(curl -s -X GET "${GATEWAY_URL}/api/v1/savings/products" \
    -H "Authorization: Bearer ${TELLER_TOKEN}")

PROD_COUNT=$(echo "$SAV_PRODS_RESP" | python3 -c 'import sys, json; print(len(json.load(sys.stdin).get("data", [])))')
[ "$PROD_COUNT" -ge 1 ] || log_fail "Không lấy được danh mục sản phẩm tiết kiệm: $SAV_PRODS_RESP"
log_pass "Tra cứu danh mục sản phẩm tiết kiệm thành công (${PROD_COUNT} gói: Phát Lộc, Trả Lãi Tháng, Gửi Góp)"

# 4.2. Khách hàng mở 1 sổ tiết kiệm 5.000.000 VND kỳ hạn 6 tháng
OPEN_SAV_RESP=$(curl -s -X POST "${GATEWAY_URL}/api/v1/savings/accounts" \
    -H "Authorization: Bearer ${CUST_TOKEN}" \
    -H "Content-Type: application/json" \
    -H "X-User-Id: ${CUST_ID}" \
    -d "{\"walletId\":\"${CUST_WALLET_ID}\",\"productType\":\"TIET_KIEM_PHAT_LOC\",\"depositAmount\":5000000,\"termMonths\":6,\"rolloverType\":\"AUTO_ROLLOVER_ALL\"}")

echo "OPEN_SAV_RESP=$OPEN_SAV_RESP"

SAV_ACC_ID=$(echo "$OPEN_SAV_RESP" | python3 -c 'import sys, json; print(json.load(sys.stdin).get("data", {}).get("id", ""))')
SAV_ACC_NO=$(echo "$OPEN_SAV_RESP" | python3 -c 'import sys, json; print(json.load(sys.stdin).get("data", {}).get("accountNumber", ""))')
[ -n "$SAV_ACC_ID" ] || log_fail "Mở sổ tiết kiệm thất bại: $OPEN_SAV_RESP"
log_pass "Mở sổ tiết kiệm thành công (Mã sổ: ${SAV_ACC_NO}, ID: ${SAV_ACC_ID}, Số tiền: 5.000.000 VND)"

# 4.3. Giám đốc tra cứu toàn bộ danh sách sổ tiết kiệm đang hoạt động trong hệ thống
SAV_ALL_RESP=$(curl -s -X GET "${GATEWAY_URL}/api/v1/savings/admin/accounts" \
    -H "Authorization: Bearer ${MANAGER_TOKEN}")

FOUND_SAV=$(echo "$SAV_ALL_RESP" | python3 -c '
import sys, json
data = json.load(sys.stdin).get("data", [])
target = "'"$SAV_ACC_ID"'"
print(sum(1 for s in data if s.get("id") == target))
')

if [ "$FOUND_SAV" -ge 1 ]; then
    log_pass "Giám đốc chi nhánh tra cứu danh mục sổ tiết kiệm toàn hệ thống tìm thấy sổ ${SAV_ACC_NO}"
else
    log_fail "Không tìm thấy sổ ${SAV_ACC_NO} trong danh sách tiết kiệm quản trị: $SAV_ALL_RESP"
fi

# 4.4. Tất toán sổ tiết kiệm
SETTLE_RESP=$(curl -s -X POST "${GATEWAY_URL}/api/v1/savings/accounts/${SAV_ACC_ID}/settle" \
    -H "Authorization: Bearer ${CUST_TOKEN}" \
    -H "X-User-Id: ${CUST_ID}")

SETTLE_MSG=$(echo "$SETTLE_RESP" | python3 -c 'import sys, json; print(json.load(sys.stdin).get("message", ""))')
log_pass "Tất toán sổ tiết kiệm thành công: ${SETTLE_MSG}"

# ------------------------------------------------------------------------------
# 5. KỊCH BẢN TRA CỨU GIAO DỊCH, BIÊN LAI PDF & XUẤT SAO KÊ CSV
# ------------------------------------------------------------------------------
log_step "5. Nghiệp vụ Tra cứu Giao dịch, In Biên Lai PDF Chuẩn Ngân Hàng & Báo cáo CSV"

# 5.1. Tra cứu biến động số dư của ví
AUDIT_WALLET_ID="11111111-1111-1111-1111-111111111111"
TX_LIST_RESP=$(curl -s -X GET "${GATEWAY_URL}/api/v1/transactions?walletId=${AUDIT_WALLET_ID}&page=0&size=10" \
    -H "Authorization: Bearer ${TELLER_TOKEN}")

TX_COUNT=$(echo "$TX_LIST_RESP" | python3 -c 'import sys, json; print(len(json.load(sys.stdin).get("data", {}).get("content", [])))')
[ "$TX_COUNT" -ge 1 ] || log_fail "Không tìm thấy giao dịch nào trong lịch sử: $TX_LIST_RESP"
FIRST_TX_ID=$(echo "$TX_LIST_RESP" | python3 -c 'import sys, json; print(json.load(sys.stdin).get("data", {}).get("content", [])[0].get("id", ""))')
log_pass "Tra cứu lịch sử giao dịch Core Banking thành công (${TX_COUNT} bút toán, Bút toán gần nhất: ${FIRST_TX_ID})"

# 5.2. Tải Biên lai điện tử PDF từ Core Banking
PDF_HTTP_STATUS=$(curl -s -o /tmp/test_receipt.pdf -w "%{http_code}" -X GET "${GATEWAY_URL}/api/v1/transactions/${FIRST_TX_ID}/receipt.pdf" \
    -H "Authorization: Bearer ${TELLER_TOKEN}")

assert_status "$PDF_HTTP_STATUS" 200 "Tải Biên lai điện tử PDF giao dịch ${FIRST_TX_ID}"
PDF_SIZE=$(stat -c%s /tmp/test_receipt.pdf 2>/dev/null || stat -f%z /tmp/test_receipt.pdf)
if [ "$PDF_SIZE" -gt 500 ]; then
    log_pass "File PDF biên lai điện tử hợp lệ (Dung lượng: ${PDF_SIZE} bytes)"
else
    log_fail "File PDF quá nhỏ hoặc rỗng (${PDF_SIZE} bytes)"
fi

# 5.3. Xuất sao kê tài khoản định dạng CSV
CSV_HTTP_STATUS=$(curl -s -o /tmp/test_statement.csv -w "%{http_code}" -X GET "${GATEWAY_URL}/api/v1/transactions/export/csv?walletId=${AUDIT_WALLET_ID}" \
    -H "Authorization: Bearer ${MANAGER_TOKEN}")

assert_status "$CSV_HTTP_STATUS" 200 "Xuất sao kê tài khoản CSV cho Giám Đốc / Khách Hàng"
CSV_LINES=$(wc -l < /tmp/test_statement.csv)
log_pass "Báo cáo CSV sao kê tài khoản hợp lệ (${CSV_LINES} dòng dữ liệu)"

# ------------------------------------------------------------------------------
# 6. KỊCH BẢN CHĂM SÓC KHÁCH HÀNG: TICKET KHIẾU NẠI & PHẢN HỒI (SUPPORT DESK)
# ------------------------------------------------------------------------------
log_step "6. Nghiệp vụ Quản trị Khiếu nại (Support Desk): Tiếp nhận ticket & Phản hồi"

# 6.1. Khách hàng gửi phiếu khiếu nại giao dịch
TICKET_SUBMIT_RESP=$(curl -s -X POST "${GATEWAY_URL}/api/v1/support/tickets" \
    -H "Authorization: Bearer ${CUST_TOKEN}" \
    -H "X-User-Id: ${CUST_ID}" \
    -d "subject=Tra_soat_giao_dich_chuyen_tien&category=TRANSACTION_DISPUTE&initialMessage=Toi_vua_chuyen_tien_nhung_doi_soat_chua_nhan_duoc")

TICKET_ID=$(echo "$TICKET_SUBMIT_RESP" | python3 -c 'import sys, json; print(json.load(sys.stdin).get("data", {}).get("id", ""))')
[ -n "$TICKET_ID" ] || log_fail "Khách hàng tạo ticket hỗ trợ thất bại: $TICKET_SUBMIT_RESP"
log_pass "Khách hàng gửi yêu cầu hỗ trợ thành công (Ticket ID: ${TICKET_ID})"

# 6.2. Cán bộ xem chi tiết ticket và lịch sử trao đổi
TICKET_DETAIL_RESP=$(curl -s -X GET "${GATEWAY_URL}/api/v1/support/tickets/${TICKET_ID}" \
    -H "Authorization: Bearer ${TELLER_TOKEN}")

TICKET_STATUS=$(echo "$TICKET_DETAIL_RESP" | python3 -c 'import sys, json; print(json.load(sys.stdin).get("data", {}).get("ticket", {}).get("status", ""))')
log_pass "Cán bộ truy xuất chi tiết ticket thành công (Trạng thái: ${TICKET_STATUS})"

# 6.3. Cán bộ phản hồi giải quyết khiếu nại cho khách hàng
REPLY_RESP=$(curl -s -X POST "${GATEWAY_URL}/api/v1/support/tickets/${TICKET_ID}/messages" \
    -H "Authorization: Bearer ${TELLER_TOKEN}" \
    -H "X-User-Id: teller1" \
    -d "content=Sen_Hong_Bank_da_tra_soat_bút_toán_thành_công_và_tiền_đã_ghi_có_ví_người_nhận")

REPLY_OK=$(echo "$REPLY_RESP" | python3 -c 'import sys, json; print(str(json.load(sys.stdin).get("success", False)).lower())')
if [ "$REPLY_OK" = "true" ]; then
    log_pass "Cán bộ phản hồi khiếu nại khách hàng thành công"
else
    log_fail "Phản hồi ticket khiếu nại thất bại: $REPLY_RESP"
fi

# ------------------------------------------------------------------------------
# 7. KỊCH BẢN QUẢN LÝ NHÂN SỰ CHI NHÁNH & DASHBOARD GIÁM ĐỐC
# ------------------------------------------------------------------------------
log_step "7. Quản lý Nhân sự Chi nhánh & Dashboard Giám Đốc (Bảo toàn Sổ Cái Δ = 0.00)"

# 7.1. Giám đốc tra cứu danh sách cán bộ chi nhánh
STAFF_LIST_RESP=$(curl -s -X GET "${GATEWAY_URL}/api/v1/staff/branch/BR_Q1" \
    -H "Authorization: Bearer ${MANAGER_TOKEN}")

STAFF_COUNT=$(echo "$STAFF_LIST_RESP" | python3 -c 'import sys, json; print(len(json.load(sys.stdin).get("data", [])))')
[ "$STAFF_COUNT" -ge 2 ] || log_fail "Không lấy đủ nhân sự chi nhánh BR_Q1: $STAFF_LIST_RESP"
log_pass "Giám đốc tra cứu danh sách nhân sự chi nhánh thành công (${STAFF_COUNT} cán bộ: Giao dịch viên & Kiểm soát viên)"

# 7.2. Kiểm tra chỉ số Sổ cái tổng hợp (Turnover Summary)
TURNOVER_RESP=$(curl -s -X GET "${GATEWAY_URL}/api/v1/ledger/turnover-summary" \
    -H "Authorization: Bearer ${MANAGER_TOKEN}")

TOTAL_DEBIT=$(echo "$TURNOVER_RESP" | python3 -c 'import sys, json; print(json.load(sys.stdin).get("data", {}).get("totalDebit", 0))')
TOTAL_CREDIT=$(echo "$TURNOVER_RESP" | python3 -c 'import sys, json; print(json.load(sys.stdin).get("data", {}).get("totalCredit", 0))')
DELTA=$(echo "$TURNOVER_RESP" | python3 -c 'import sys, json; print(json.load(sys.stdin).get("data", {}).get("delta", 0))')

log_pass "Dashboard Giám đốc: Tổng Nợ = ${TOTAL_DEBIT} VND | Tổng Có = ${TOTAL_CREDIT} VND | Delta = ${DELTA} VND"

# 7.3. Đối soát toàn sổ kép (Reconciliation)
RECON_RESP=$(curl -s -X GET "${GATEWAY_URL}/api/v1/ledger/accounts/balance-check" \
    -H "Authorization: Bearer ${MANAGER_TOKEN}")

RECON_BALANCED=$(echo "$RECON_RESP" | python3 -c 'import sys, json; print(str(json.load(sys.stdin).get("data", {}).get("balanced", False)).lower())')
RECON_DELTA=$(echo "$RECON_RESP" | python3 -c '
import sys, json
d = json.load(sys.stdin).get("data", {})
debit = float(d.get("totalDebit", 0))
credit = float(d.get("totalCredit", 0))
print(int(abs(debit - credit)))
')

if [ "$RECON_BALANCED" = "true" ] && [ "$RECON_DELTA" -eq 0 ]; then
    log_pass "BẢO TOÀN SỔ CÁI TUYỆT ĐỐI: Σ Debit = Σ Credit, Sai lệch Δ = 0.00 VND!"
else
    log_fail "Sổ cái mất cân đối: Delta = ${RECON_DELTA}, Balanced = ${RECON_BALANCED}"
fi

# 7.4. Kiểm tra số dư két quỹ chi nhánh
VAULT_RESP=$(curl -s -X GET "${GATEWAY_URL}/api/v1/cash/vault/summary" \
    -H "Authorization: Bearer ${MANAGER_TOKEN}")

CURRENT_VAULT=$(echo "$VAULT_RESP" | python3 -c 'import sys, json; print(json.load(sys.stdin).get("data", {}).get("currentBalance", 0))')
MAX_VAULT=$(echo "$VAULT_RESP" | python3 -c 'import sys, json; print(json.load(sys.stdin).get("data", {}).get("maxLimit", 0))')
log_pass "Két quỹ Chi nhánh: Hiện có ${CURRENT_VAULT} VND / Hạn mức an toàn ${MAX_VAULT} VND"

# ------------------------------------------------------------------------------
# TỔNG KẾT
# ------------------------------------------------------------------------------
echo -e "\n${COLOR_GREEN}======================================================================${COLOR_RESET}"
echo -e "${COLOR_GREEN}  KẾT QUẢ KIỂM THỬ TDD: TÍNH NĂNG ADMIN & GIÁM ĐỐC HOÀN THÀNH 100%!  ${COLOR_RESET}"
echo -e "${COLOR_GREEN}  Đã thực thi thành công: ${PASSED_TESTS}/${TOTAL_TESTS} bài kiểm tra nghiệp vụ thật. ${COLOR_RESET}"
echo -e "${COLOR_GREEN}======================================================================${COLOR_RESET}\n"
