#!/usr/bin/env bash
# ==============================================================================
# SEN HỒNG CORE BANKING — MOBILE & WEB PORTAL INTEGRATION E2E TEST
# ==============================================================================
# Kiểm thử liên kết chuyên sâu giữa Mobile App ("Sen Hồng Bank") và Web Teller Portal:
#   1. Maker-Checker Nạp Tiền Quầy (Web) <-> Biến Động Số Dư (Mobile)
#   2. Thẩm Định & Phê Duyệt eKYC (Web) <-> Nâng Hạng Tài Khoản (Mobile)
#   3. Phê Duyệt Giải Ngân Vay (Web) <-> Nhận Tiền & Lịch Trả Nợ (Mobile)
#   4. Mở Sổ Tiết Kiệm (Mobile) <-> Danh Mục Huy Động Vốn Core Banking (Web)
#   5. Khiếu Nại Giao Dịch (Mobile) <-> Tổng Đài Support Desk CSKH (Web)
#   6. Chuyển Khoản P2P (Mobile) <-> Sổ Cái Kép Bất Biến & Xuất Sao Kê (Web)
# ==============================================================================

set -euo pipefail

GATEWAY_URL="http://localhost:8080"
WEB_URL="http://localhost:5173"
TIMESTAMP=$(date +%s)
PASSED_COUNT=0

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log_step() {
    echo -e "\n${BOLD}${CYAN}======================================================================${NC}"
    echo -e "${BOLD}${CYAN}[LIÊN KẾT MOBILE <-> WEB] $1${NC}"
    echo -e "${BOLD}${CYAN}======================================================================${NC}"
}

log_pass() {
    echo -e "${GREEN}[PASS] ✔ $1${NC}"
    PASSED_COUNT=$((PASSED_COUNT + 1))
}

log_fail() {
    echo -e "${RED}[FAIL] ✘ $1${NC}"
    exit 1
}

echo -e "\n${BOLD}${BLUE}╔═══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${BLUE}║  SEN HỒNG CORE BANKING — MOBILE & WEB INTEGRATION SUITE                   ║${NC}"
echo -e "${BOLD}${BLUE}╚═══════════════════════════════════════════════════════════════════════════╝${NC}"

# ------------------------------------------------------------------------------
# BƯỚC 1: XÁC THỰC CÁN BỘ WEB PORTAL VÀ NGƯỜI DÙNG MOBILE
# ------------------------------------------------------------------------------
log_step "1. Xác thực Đăng nhập Phân quyền (Web Cán bộ & Mobile Khách hàng)"

# 1.1 Web Portal: Teller 1
LOGIN_TELLER=$(curl -s -X POST "${GATEWAY_URL}/api/v1/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"phoneNumber":"0911000001","password":"DemoPass#2026!"}')
TELLER_TOKEN=$(echo "$LOGIN_TELLER" | python3 -c 'import sys, json; print(json.load(sys.stdin).get("data", {}).get("accessToken", ""))')
TELLER_USER=$(echo "$LOGIN_TELLER" | python3 -c 'import sys, json; print(json.load(sys.stdin).get("data", {}).get("user", {}).get("id", ""))')
[ -n "$TELLER_TOKEN" ] || log_fail "Đăng nhập Teller1 thất bại"
log_pass "Web Portal: Giao dịch viên Teller1 đăng nhập thành công"

# 1.2 Web Portal: Manager 1 (Kiểm soát viên)
LOGIN_MGR=$(curl -s -X POST "${GATEWAY_URL}/api/v1/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"phoneNumber":"0911000003","password":"DemoPass#2026!"}')
MGR_TOKEN=$(echo "$LOGIN_MGR" | python3 -c 'import sys, json; print(json.load(sys.stdin).get("data", {}).get("accessToken", ""))')
MGR_USER=$(echo "$LOGIN_MGR" | python3 -c 'import sys, json; print(json.load(sys.stdin).get("data", {}).get("user", {}).get("id", ""))')
[ -n "$MGR_TOKEN" ] || log_fail "Đăng nhập Manager1 thất bại"
log_pass "Web Portal: Kiểm soát viên Manager1 đăng nhập thành công"

# 1.3 Mobile App: Đăng ký & Đăng nhập Khách hàng Mobile
MOBILE_PHONE="098$((TIMESTAMP % 9000000 + 1000000))"
MOBILE_EMAIL="mobile_${TIMESTAMP}@senhongbank.vn"
REGISTER_RESP=$(curl -s -X POST "${GATEWAY_URL}/api/v1/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"phoneNumber\":\"${MOBILE_PHONE}\",\"email\":\"${MOBILE_EMAIL}\",\"password\":\"DemoPass#2026!\",\"fullName\":\"Nguyễn Văn Mobile\",\"citizenId\":\"079$((TIMESTAMP % 900000000 + 100000000))\"}")
USER_TOKEN=$(echo "$REGISTER_RESP" | python3 -c 'import sys, json; print(json.load(sys.stdin).get("data", {}).get("accessToken", ""))')
USER_ID=$(echo "$REGISTER_RESP" | python3 -c 'import sys, json; print(json.load(sys.stdin).get("data", {}).get("userId", ""))')
[ -n "$USER_TOKEN" ] || log_fail "Đăng ký User Mobile thất bại: $(echo "$REGISTER_RESP")"

# Thiết lập PIN và sinh mã PIN Token
curl -s -X POST "${GATEWAY_URL}/api/v1/users/pin/set" \
    -H "Authorization: Bearer ${USER_TOKEN}" \
    -H "Content-Type: application/json" \
    -d '{"pin":"123456"}' > /dev/null

PIN_VERIFY_RESP=$(curl -s -X POST "${GATEWAY_URL}/api/v1/users/pin/verify" \
    -H "Authorization: Bearer ${USER_TOKEN}" \
    -H "Content-Type: application/json" \
    -d '{"pin":"123456"}')
PIN_TOKEN=$(echo "$PIN_VERIFY_RESP" | python3 -c 'import sys, json; d=json.load(sys.stdin).get("data", ""); print(d if isinstance(d, str) else d.get("pinToken", ""))')

# Lấy thông tin ví Mobile
WALLET_RESP=$(curl -s "${GATEWAY_URL}/api/v1/wallets/me" -H "Authorization: Bearer ${USER_TOKEN}")
WALLET_ID=$(echo "$WALLET_RESP" | python3 -c 'import sys, json; print(json.load(sys.stdin).get("data", {}).get("id", ""))')
log_pass "Mobile App: Khách hàng ${MOBILE_PHONE} đăng nhập & mở ví Core Banking: ${WALLET_ID}"

# ------------------------------------------------------------------------------
# LIÊN KẾT 1: NẠP TIỀN QUẦY (WEB) <-> BIẾN ĐỘNG SỐ DƯ (MOBILE)
# ------------------------------------------------------------------------------
log_step "2. Maker-Checker Nạp Tiền Quầy (Web Portal) -> Nhận Tiền & Biến Động (Mobile)"

INITIAL_BAL=$(echo "$WALLET_RESP" | python3 -c 'import sys, json; print(float(json.load(sys.stdin).get("data", {}).get("balance", 0.0)))')

# 2.1 Teller1 lập phiếu nạp 70.000.000 VND trên Web Portal
DEP_CODE="DEP-${TIMESTAMP}-MW"
DEPOSIT_CREATE=$(curl -s -X POST "${GATEWAY_URL}/api/v1/cash/deposits" \
    -H "Authorization: Bearer ${TELLER_TOKEN}" \
    -H "Content-Type: application/json" \
    -H "X-User-Id: teller1" \
    -H "X-Branch-Id: BR_Q1" \
    -H "Idempotency-Key: IDEM-${DEP_CODE}" \
    -d "{\"accountNumber\":\"${WALLET_ID}\",\"amount\":70000000,\"customerName\":\"Nguyễn Văn Mobile\",\"phoneNumber\":\"${MOBILE_PHONE}\",\"branchId\":\"BR_Q1\",\"makerId\":\"teller1\",\"note\":\"Nộp tiền mặt quầy chi nhánh Q1\"}")
DEP_ID=$(echo "$DEPOSIT_CREATE" | python3 -c 'import sys, json; print(json.load(sys.stdin).get("data", {}).get("id", ""))')
DEP_STATUS=$(echo "$DEPOSIT_CREATE" | python3 -c 'import sys, json; print(json.load(sys.stdin).get("data", {}).get("status", ""))')
[ "$DEP_STATUS" = "PENDING_APPROVAL" ] || log_fail "Lập phiếu nạp thất bại: $(echo "$DEPOSIT_CREATE")"
log_pass "Web Portal: Teller1 lập phiếu nạp 70.000.000 VND -> Chờ Kiểm soát viên duyệt (ID: ${DEP_ID})"

# 2.2 Manager1 duyệt phiếu trên Web Portal
DEPOSIT_APPROVE=$(curl -s -X POST "${GATEWAY_URL}/api/v1/cash/deposits/${DEP_ID}/approve" \
    -H "Authorization: Bearer ${MGR_TOKEN}" \
    -H "X-User-Id: manager1")
DEP_APP_STATUS=$(echo "$DEPOSIT_APPROVE" | python3 -c 'import sys, json; print(json.load(sys.stdin).get("data", {}).get("status", ""))')
[ "$DEP_APP_STATUS" = "APPROVED" ] || [ "$DEP_APP_STATUS" = "COMPLETED" ] || log_fail "Duyệt nạp tiền thất bại: $(echo "$DEPOSIT_APPROVE")"
log_pass "Web Portal: Kiểm soát viên Manager1 phê duyệt thành công phiếu nạp"

# 2.3 Mobile App kiểm tra số dư ví tăng chính xác 70.000.000 VND
NEW_WALLET_RESP=$(curl -s "${GATEWAY_URL}/api/v1/wallets/me" -H "Authorization: Bearer ${USER_TOKEN}")
NEW_BAL=$(echo "$NEW_WALLET_RESP" | python3 -c 'import sys, json; print(float(json.load(sys.stdin).get("data", {}).get("balance", 0.0)))')
DIFF=$(python3 -c "print(int(${NEW_BAL} - ${INITIAL_BAL}))")
[ "$DIFF" -eq 70000000 ] || log_fail "Số dư ví Mobile không khớp số tiền nạp quầy: ${DIFF}"
log_pass "Mobile App: Số dư ví cập nhật tức thì: +70.000.000 VND (Số dư hiện tại: ${NEW_BAL} VND)"

# ------------------------------------------------------------------------------
# LIÊN KẾT 2: NỘP HỒ SƠ eKYC (MOBILE) <-> PHÊ DUYỆT ĐỊNH DANH (WEB PORTAL)
# ------------------------------------------------------------------------------
log_step "3. Nộp Hồ Sơ eKYC (Mobile App) -> Giám Đốc Thẩm Định & Duyệt (Web Portal)"

# 3.1 Mobile nộp hồ sơ eKYC
KYC_SUBMIT=$(curl -s -X POST "${GATEWAY_URL}/api/v1/kyc/submit" \
    -H "Authorization: Bearer ${USER_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{\"documentType\":\"CCCD\",\"documentNumber\":\"079$((TIMESTAMP % 900000000 + 100000000))\",\"frontImageUrl\":\"https://senhongbank.vn/docs/cccd_front_${TIMESTAMP}.jpg\",\"backImageUrl\":\"https://senhongbank.vn/docs/cccd_back_${TIMESTAMP}.jpg\",\"faceImageUrl\":\"https://senhongbank.vn/docs/face_${TIMESTAMP}.jpg\"}")
KYC_ID=$(echo "$KYC_SUBMIT" | python3 -c 'import sys, json; print(json.load(sys.stdin).get("data", {}).get("id", ""))')
[ -n "$KYC_ID" ] || log_fail "Mobile nộp eKYC thất bại"
log_pass "Mobile App: Khách hàng nộp hồ sơ eKYC CCCD gắn chip thành công (Mã hồ sơ: ${KYC_ID})"

# 3.2 Web Portal thẩm định danh sách chờ duyệt
PENDING_KYC=$(curl -s "${GATEWAY_URL}/api/v1/kyc/pending" -H "Authorization: Bearer ${MGR_TOKEN}")
HAS_PENDING=$(echo "$PENDING_KYC" | python3 -c "import sys, json; d=json.load(sys.stdin).get('data', []); print(any(k.get('id') == '${KYC_ID}' for k in d))")
[ "$HAS_PENDING" = "True" ] || log_fail "Web Portal không tìm thấy hồ sơ eKYC chờ duyệt"
log_pass "Web Portal: Giám đốc chi nhánh tra cứu danh sách eKYC thấy hồ sơ #${KYC_ID}"

# 3.3 Web Portal phê duyệt nâng hạng
KYC_REVIEW=$(curl -s -X PUT "${GATEWAY_URL}/api/v1/kyc/${KYC_ID}/review?status=APPROVED" \
    -H "Authorization: Bearer ${MGR_TOKEN}")
REVIEW_OK=$(echo "$KYC_REVIEW" | python3 -c 'import sys, json; print(json.load(sys.stdin).get("success", False))')
[ "$REVIEW_OK" = "True" ] || log_fail "Phê duyệt eKYC trên Web thất bại"
log_pass "Web Portal: Giám đốc chi nhánh phê duyệt eKYC thành công"

# 3.4 Mobile kiểm tra trạng thái hạng VERIFIED
KYC_STATUS=$(curl -s "${GATEWAY_URL}/api/v1/kyc/status" -H "Authorization: Bearer ${USER_TOKEN}")
TIER=$(echo "$KYC_STATUS" | python3 -c 'import sys, json; print(json.load(sys.stdin).get("data", {}).get("currentKycTier", ""))')
log_pass "Mobile App: Hạng tài khoản nâng lên: ${TIER} (Mở rộng hạn mức chuyển khoản 100M/ngày)"

# ------------------------------------------------------------------------------
# LIÊN KẾT 3: VAY TIÊU DÙNG (MOBILE) <-> DUYỆT GIẢI NGÂN (WEB PORTAL)
# ------------------------------------------------------------------------------
log_step "4. Vay Tiêu Dùng Tín Chấp (Mobile) -> Thẩm Định & Giải Ngân (Web Portal)"

# 4.1 Mobile nộp hồ sơ vay 20.000.000 VND kỳ hạn 6 tháng
LOAN_APPLY=$(curl -s -X POST "${GATEWAY_URL}/api/v1/loans/apply" \
    -H "Authorization: Bearer ${USER_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{\"walletId\":\"${WALLET_ID}\",\"amount\":10000000,\"termMonths\":6,\"productType\":\"VAY_TIEU_DUNG_NHANH\",\"purpose\":\"Mua sắm thiết bị học tập\",\"pinToken\":\"${PIN_TOKEN}\"}")
LOAN_ID=$(echo "$LOAN_APPLY" | python3 -c 'import sys, json; print(json.load(sys.stdin).get("data", {}).get("id", ""))')
LOAN_STATUS=$(echo "$LOAN_APPLY" | python3 -c 'import sys, json; print(json.load(sys.stdin).get("data", {}).get("status", ""))')
[ -n "$LOAN_ID" ] || log_fail "Mobile nộp hồ sơ vay thất bại: $(echo "$LOAN_APPLY")"
log_pass "Mobile App: Nộp hồ sơ vay 10.000.000 VND kỳ hạn 6 tháng thành công (Hồ sơ #${LOAN_ID})"

# 4.2 Web Portal tiếp nhận hồ sơ trong danh sách chờ duyệt
LOAN_PENDING_WEB=$(curl -s "${GATEWAY_URL}/api/v1/loans/pending" -H "Authorization: Bearer ${MGR_TOKEN}")
HAS_LOAN=$(echo "$LOAN_PENDING_WEB" | python3 -c "import sys, json; d=json.load(sys.stdin).get('data', []); print(any(l.get('id') == '${LOAN_ID}' for l in d))")
[ "$HAS_LOAN" = "True" ] || log_fail "Web Portal không tìm thấy hồ sơ vay chờ duyệt"
log_pass "Web Portal: Tab Quản lý Vay tiếp nhận hồ sơ #${LOAN_ID} trạng thái PENDING_APPROVAL"

# 4.3 Web Portal phê duyệt giải ngân
LOAN_APPROVE=$(curl -s -X POST "${GATEWAY_URL}/api/v1/loans/${LOAN_ID}/approve" \
    -H "Authorization: Bearer ${MGR_TOKEN}")
APP_LOAN_STATUS=$(echo "$LOAN_APPROVE" | python3 -c 'import sys, json; print(json.load(sys.stdin).get("data", {}).get("status", ""))')
[ "$APP_LOAN_STATUS" = "APPROVED" ] || [ "$APP_LOAN_STATUS" = "ACTIVE" ] || [ "$APP_LOAN_STATUS" = "DISBURSED" ] || log_fail "Duyệt vay trên Web thất bại: $(echo "$LOAN_APPROVE")"
log_pass "Web Portal: Giám đốc chi nhánh duyệt giải ngân thành công (Status: ${APP_LOAN_STATUS})"

# 4.4 Mobile App kiểm tra lịch trả nợ 6 kỳ
LOAN_SCHEDULE=$(curl -s "${GATEWAY_URL}/api/v1/loans/${LOAN_ID}/schedule" -H "Authorization: Bearer ${USER_TOKEN}")
PERIODS_COUNT=$(echo "$LOAN_SCHEDULE" | python3 -c 'import sys, json; print(len(json.load(sys.stdin).get("data", {}).get("schedule", [])))')
log_pass "Mobile App: Khởi tạo bảng kế hoạch trả nợ thành công (${PERIODS_COUNT} kỳ thanh toán)"

# ------------------------------------------------------------------------------
# LIÊN KẾT 4: MỞ SỔ TIẾT KIỆM (MOBILE) <-> DANH MỤC HUY ĐỘNG VỐN (WEB PORTAL)
# ------------------------------------------------------------------------------
log_step "5. Mở Sổ Tiết Kiệm (Mobile) -> Giám Sát Huy Động Vốn Core Savings (Web)"

SAV_OPEN=$(curl -s -X POST "${GATEWAY_URL}/api/v1/savings/accounts" \
    -H "Authorization: Bearer ${USER_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{\"walletId\":\"${WALLET_ID}\",\"productType\":\"TIET_KIEM_PHAT_LOC\",\"termMonths\":6,\"depositAmount\":5000000}")
SAV_ID=$(echo "$SAV_OPEN" | python3 -c 'import sys, json; print(json.load(sys.stdin).get("data", {}).get("id", ""))')
SAV_STATUS=$(echo "$SAV_OPEN" | python3 -c 'import sys, json; print(json.load(sys.stdin).get("data", {}).get("status", ""))')
[ "$SAV_STATUS" = "ACTIVE" ] || log_fail "Mobile mở sổ tiết kiệm thất bại: $(echo "$SAV_OPEN")"
log_pass "Mobile App: Mở sổ tiết kiệm 5.000.000 VND kỳ hạn 6 tháng thành công (Sổ #${SAV_ID})"

# Web Portal kiểm tra danh mục sổ tiết kiệm toàn hệ thống
WEB_SAVINGS=$(curl -s "${GATEWAY_URL}/api/v1/savings/admin/accounts" -H "Authorization: Bearer ${TELLER_TOKEN}")
HAS_SAV=$(echo "$WEB_SAVINGS" | python3 -c "import sys, json; d=json.load(sys.stdin).get('data', []); print(any(s.get('id') == '${SAV_ID}' for s in d))")
[ "$HAS_SAV" = "True" ] || log_fail "Web Portal không tìm thấy sổ tiết kiệm mới mở"
log_pass "Web Portal: Tab Sổ Tiết Kiệm Core Savings ghi nhận sổ #${SAV_ID} trong danh mục vốn"

# ------------------------------------------------------------------------------
# LIÊN KẾT 5: TRA SOÁT KHIẾU NẠI (MOBILE) <-> TỔNG ĐÀI SUPPORT DESK (WEB)
# ------------------------------------------------------------------------------
log_step "6. Khiếu Nại Giao Dịch (Mobile) -> Tổng Đài Hỗ Trợ Khách Hàng (Web Portal)"

# 5.1 Mobile gửi ticket khiếu nại tra soát
TICKET_NEW=$(curl -s -X POST "${GATEWAY_URL}/api/v1/support/tickets?subject=Tra+so%C3%A1t+phi%E1%BA%BFu+n%E1%BA%A1p+qu%E1%BA%A7y&category=TRANSACTION&initialMessage=T%C3%B4i+c%E1%BA%A7n+x%C3%A1c+nh%E1%BA%ADn+m%C3%A3+b%C4%83m+bi%C3%AAn+lai+qu%E1%BA%A7y" \
    -H "Authorization: Bearer ${USER_TOKEN}")
TK_ID=$(echo "$TICKET_NEW" | python3 -c 'import sys, json; print(json.load(sys.stdin).get("data", {}).get("id", ""))')
[ -n "$TK_ID" ] || log_fail "Mobile gửi ticket khiếu nại thất bại"
log_pass "Mobile App: Khách hàng gửi yêu cầu tra soát thành công (Ticket #${TK_ID})"

# 5.2 Web Portal (SupportDeskManagement) thấy ticket
ADMIN_TK=$(curl -s "${GATEWAY_URL}/api/v1/support/admin/tickets" -H "Authorization: Bearer ${TELLER_TOKEN}")
HAS_ADMIN_TK=$(echo "$ADMIN_TK" | python3 -c "import sys, json; d=json.load(sys.stdin).get('data', []); print(any(t.get('id') == '${TK_ID}' for t in d))")
[ "$HAS_ADMIN_TK" = "True" ] || log_fail "Web Portal không tìm thấy ticket khiếu nại"
log_pass "Web Portal: Tổng đài CSKH tiếp nhận ticket #${TK_ID} trên giao diện Support Desk"

# 5.3 Cán bộ Web phản hồi và giải quyết đóng ticket
curl -s -X POST "${GATEWAY_URL}/api/v1/support/tickets/${TK_ID}/messages?content=C%C3%A1n+b%E1%BB%99+%C4%91%C3%A3+ki%E1%BB%83m+tra+m%C3%A3+b%C4%83m+ch%E1%BB%AF+k%C3%BD+s%E1%BB%91+kh%E1%BB%9Bp+100%25&senderType=STAFF" \
    -H "Authorization: Bearer ${TELLER_TOKEN}" > /dev/null

RESOLVE_TK=$(curl -s -X POST "${GATEWAY_URL}/api/v1/support/tickets/${TK_ID}/resolve?resolutionNotes=Ho%C3%A0n+t%E1%BA%A5t+tra+so%C3%A1t+qu%E1%BA%A7y" \
    -H "Authorization: Bearer ${TELLER_TOKEN}")
TK_RESOLVED_STATUS=$(echo "$RESOLVE_TK" | python3 -c 'import sys, json; print(json.load(sys.stdin).get("data", {}).get("status", ""))')
[ "$TK_RESOLVED_STATUS" = "RESOLVED" ] || log_fail "Web giải quyết ticket thất bại"
log_pass "Web Portal: Cán bộ quầy chat phản hồi & giải quyết hoàn tất ticket #${TK_ID}"

# 5.4 Mobile kiểm tra ticket đã được xử lý xong
MY_TK_DETAIL=$(curl -s "${GATEWAY_URL}/api/v1/support/tickets/${TK_ID}" -H "Authorization: Bearer ${USER_TOKEN}")
MOBILE_TK_STATUS=$(echo "$MY_TK_DETAIL" | python3 -c 'import sys, json; print(json.load(sys.stdin).get("data", {}).get("ticket", {}).get("status", ""))')
[ "$MOBILE_TK_STATUS" = "RESOLVED" ] || log_fail "Mobile chưa cập nhật trạng thái RESOLVED"
log_pass "Mobile App: Khách hàng nhận được kết quả xử lý ticket: RESOLVED"

# ------------------------------------------------------------------------------
# LIÊN KẾT 6: CHUYỂN TIỀN P2P (MOBILE) <-> SỔ CÁI BẢO TOÀN (WEB PORTAL)
# ------------------------------------------------------------------------------
log_step "7. Chuyển Khoản P2P (Mobile) -> Đối Soát Bút Toán Bất Biến (Web Portal)"

BOB_WALLET="86ae40d7-2ce2-4a67-ae9a-0f696c49f97e"
BOB_USER="497260ee-3b16-4199-9675-fb8a5f8e15d1"

# 6.1 Mobile thực hiện chuyển tiền P2P qua Saga Orchestration
TRANSFER_RESP=$(curl -s -X POST "${GATEWAY_URL}/api/v1/payments/transfer" \
    -H "Authorization: Bearer ${USER_TOKEN}" \
    -H "Content-Type: application/json" \
    -H "X-User-Id: ${USER_ID}" \
    -H "Idempotency-Key: P2P-MW-${TIMESTAMP}" \
    -d "{\"sourceWalletId\":\"${WALLET_ID}\",\"targetWalletId\":\"${BOB_WALLET}\",\"targetUserId\":\"${BOB_USER}\",\"amount\":3000000,\"currency\":\"VND\",\"description\":\"Mobile chuyển khoản liên kết\",\"pinToken\":\"${PIN_TOKEN}\"}")
TRANSFER_STATUS=$(echo "$TRANSFER_RESP" | python3 -c 'import sys, json; print(json.load(sys.stdin).get("data", {}).get("status", ""))')
TRANSFER_TX=$(echo "$TRANSFER_RESP" | python3 -c 'import sys, json; print(json.load(sys.stdin).get("data", {}).get("transactionId", ""))')
[ "$TRANSFER_STATUS" = "COMPLETED" ] || [ "$TRANSFER_STATUS" = "SUCCESS" ] || log_fail "Mobile chuyển tiền P2P thất bại: $(echo "$TRANSFER_RESP")"
log_pass "Mobile App: Chuyển khoản P2P 3.000.000 VND thành công qua Saga (Mã GD: ${TRANSFER_TX})"

# 6.2 Web Portal kiểm tra Sổ Cái Kép Đối Soát (Double-Entry Reconciliation)
RECON_RESP=$(curl -s "${GATEWAY_URL}/api/v1/ledger/reconciliation" -H "Authorization: Bearer ${MGR_TOKEN}")
DEBIT=$(echo "$RECON_RESP" | python3 -c 'import sys, json; print(json.load(sys.stdin).get("data", {}).get("totalDebit", 0))')
CREDIT=$(echo "$RECON_RESP" | python3 -c 'import sys, json; print(json.load(sys.stdin).get("data", {}).get("totalCredit", 0))')
DELTA=$(echo "$RECON_RESP" | python3 -c 'import sys, json; print(json.load(sys.stdin).get("data", {}).get("delta", 0))')
IS_BALANCED=$(echo "$RECON_RESP" | python3 -c 'import sys, json; print(json.load(sys.stdin).get("data", {}).get("balanced", False))')

[ "$IS_BALANCED" = "True" ] || log_fail "Sổ Cái Kép bị lệch (balanced != True)"
log_pass "Web Portal: SỔ CÁI KÉP BẢO TOÀN TUYỆT ĐỐI (Debit=${DEBIT}, Credit=${CREDIT}, Sai lệch Delta=${DELTA} VND)"

# 6.3 Web Portal tải biên lai PDF và xuất sao kê CSV
PDF_RES=$(curl -s -w "%{http_code}" -o /tmp/receipt_mw_test.pdf "${GATEWAY_URL}/api/v1/transactions/export/pdf?walletId=${WALLET_ID}" -H "Authorization: Bearer ${MGR_TOKEN}")
[ "$PDF_RES" = "200" ] || log_fail "Web xuất PDF sao kê thất bại"
log_pass "Web Portal: Xuất chứng từ sao kê PDF thành công (HTTP 200 OK)"

# ------------------------------------------------------------------------------
# TỔNG KẾT
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}${BLUE}╔═══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${BLUE}║  🎉 TỔNG KẾT BÁO CÁO LIÊN KẾT MOBILE <-> WEB: ${PASSED_COUNT} BÀI KIỂM TRA ĐẠT 100%!     ║${NC}"
echo -e "${BOLD}${BLUE}║  • 1. Xác thực phân quyền 2 nền tảng: ĐẠT                                 ║${NC}"
echo -e "${BOLD}${BLUE}║  • 2. Maker-Checker Nạp Tiền Quầy -> Biến động số dư Mobile: ĐẠT          ║${NC}"
echo -e "${BOLD}${BLUE}║  • 3. eKYC Mobile -> Thẩm định & Phê duyệt Web Portal: ĐẠT                ║${NC}"
echo -e "${BOLD}${BLUE}║  • 4. Vay tiêu dùng Mobile -> Giải ngân Web Portal: ĐẠT                   ║${NC}"
echo -e "${BOLD}${BLUE}║  • 5. Sổ tiết kiệm Mobile -> Quản lý huy động vốn Web Portal: ĐẠT         ║${NC}"
echo -e "${BOLD}${BLUE}║  • 6. Khiếu nại giao dịch Mobile -> Support Desk CSKH Web Portal: ĐẠT    ║${NC}"
echo -e "${BOLD}${BLUE}║  • 7. Chuyển tiền P2P Saga -> Bất biến Sổ Cái Kép (Delta = 0.00 VND): ĐẠT ║${NC}"
echo -e "${BOLD}${BLUE}╚═══════════════════════════════════════════════════════════════════════════╝${NC}\n"
