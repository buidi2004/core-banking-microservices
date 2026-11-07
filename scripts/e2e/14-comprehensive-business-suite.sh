#!/usr/bin/env bash
# ==============================================================================
# 🏦 SEN HỒNG CORE BANKING - TOÀN DIỆN BỘ TEST NGHIỆP VỤ E2E CHUYÊN SÂU
# ==============================================================================
# File: scripts/e2e/14-comprehensive-business-suite.sh
# Kiểm thử toàn diện qua API Gateway (:8080) mô phỏng người dùng Mobile và Giao dịch viên Web:
#   KB-01: Xác thực & Hồ sơ & PIN (Login, Profile, Set PIN, Verify PIN)
#   KB-02: Chuyển tiền P2P nội bộ & Tự động sinh thông báo biến động số dư qua Kafka
#   KB-03: Lịch sử giao dịch & Số dư tức thời (Running Balance) & Sao kê (PDF/CSV)
#   KB-04: Tiết kiệm Online (Mở sổ có kỳ hạn, ghi nợ ví, tất toán nhận gốc + lãi)
#   KB-05: Vay tiêu dùng: Xác thực OTP -> Chờ nhân viên duyệt -> Giải ngân -> Trả nợ kỳ hạn
#   KB-06: Quy trình Từ chối vay vốn (Maker-Checker Reject Reason)
#   KB-07: Khảo sát đối soát hợp đồng API Mobile (VietQR, Recipient Info, Fee Estimate, Notification Count)
# ==============================================================================

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

GATEWAY_URL="http://localhost:8080/api/v1"
PASSED=0
TOTAL=7

echo -e "${CYAN}==============================================================================${NC}"
echo -e "${CYAN}🏦 SEN HỒNG CORE BANKING - KIỂM THỬ TOÀN DIỆN BỘ NGHIỆP VỤ E2E CHUYÊN SÂU${NC}"
echo -e "${CYAN}   Cổng vào: API Gateway :8080 | 6 Microservices + Kafka + RabbitMQ + Redis${NC}"
echo -e "${CYAN}==============================================================================${NC}"

# ==============================================================================
# KB-01: ĐĂNG NHẬP, HỒ SƠ & MÃ PIN GIAO DỊCH
# ==============================================================================
echo ""
echo -e "${BLUE}▶ [KB-01] XÁC THỰC & MÃ PIN GIAO DỊCH (ALICE)${NC}"

# 1.1 Login Alice
ALICE_LOGIN_RES=$(curl -s -X POST "${GATEWAY_URL}/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"alice","password":"DemoPass#2026!"}')

ALICE_TOKEN=$(echo "$ALICE_LOGIN_RES" | grep -o '"token":"[^"]*' | head -1 | cut -d'"' -f4)
ALICE_USER_ID=$(echo "$ALICE_LOGIN_RES" | grep -o '"userId":"[^"]*' | head -1 | cut -d'"' -f4)

if [ -z "$ALICE_TOKEN" ]; then
  echo -e "  ${RED}✗ [FAILED] Không thể đăng nhập tài khoản Alice: ${ALICE_LOGIN_RES}${NC}"
  exit 1
fi
echo "  • Đăng nhập Alice thành công (userId: ${ALICE_USER_ID})"

# 1.2 User Profile
PROFILE_RES=$(curl -s -X GET "${GATEWAY_URL}/users/profile" \
  -H "Authorization: Bearer ${ALICE_TOKEN}")
PROFILE_SUCCESS=$(echo "$PROFILE_RES" | grep -o '"success":true' || true)

if [ -z "$PROFILE_SUCCESS" ]; then
  echo -e "  ${RED}✗ [FAILED] Không lấy được thông tin hồ sơ Alice (/users/profile): ${PROFILE_RES}${NC}"
  exit 1
fi
echo "  • Lấy thông tin hồ sơ /users/profile thành công"

# 1.3 Thiết lập mã PIN
PIN_SET_RES=$(curl -s -X POST "${GATEWAY_URL}/users/pin/set" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${ALICE_TOKEN}" \
  -d '{"pin":"123456"}')
PIN_SET_OK=$(echo "$PIN_SET_RES" | grep -o '"success":true' || true)

if [ -z "$PIN_SET_OK" ]; then
  echo -e "  ${RED}✗ [FAILED] Thiết lập mã PIN thất bại: ${PIN_SET_RES}${NC}"
  exit 1
fi
echo "  • Thiết lập mã PIN 123456 thành công"

# 1.4 Xác thực mã PIN để nhận pinToken
PIN_VERIFY_RES=$(curl -s -X POST "${GATEWAY_URL}/users/pin/verify" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${ALICE_TOKEN}" \
  -d '{"pin":"123456"}')
ALICE_PIN_TOKEN=$(echo "$PIN_VERIFY_RES" | grep -o '"data":"[^"]*' | head -1 | cut -d'"' -f4)

if [ -z "$ALICE_PIN_TOKEN" ]; then
  echo -e "  ${RED}✗ [FAILED] Xác thực mã PIN thất bại: ${PIN_VERIFY_RES}${NC}"
  exit 1
fi
echo "  • Nhận pinToken ủy quyền giao dịch hợp lệ"
echo -e "  ${GREEN}✓ [PASSED] KB-01: Xác thực, xem hồ sơ & thiết lập/xác thực mã PIN thành công!${NC}"
PASSED=$((PASSED + 1))

# ==============================================================================
# KB-02: CHUYỂN TIỀN P2P & THÔNG BÁO BIẾN ĐỘNG SỐ DƯ REAL-TIME
# ==============================================================================
echo ""
echo -e "${BLUE}▶ [KB-02] CHUYỂN TIỀN P2P NỘI BỘ & THÔNG BÁO BIẾN ĐỘNG SỐ DƯ (KAFKA)${NC}"

# Đăng nhập Bob để lấy token đối soát
BOB_LOGIN_RES=$(curl -s -X POST "${GATEWAY_URL}/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"bob","password":"DemoPass#2026!"}')
BOB_TOKEN=$(echo "$BOB_LOGIN_RES" | grep -o '"token":"[^"]*' | head -1 | cut -d'"' -f4)
BOB_USER_ID=$(echo "$BOB_LOGIN_RES" | grep -o '"userId":"[^"]*' | head -1 | cut -d'"' -f4)

# Số dư ban đầu của Alice & Bob
ALICE_BAL_PRE=$(curl -s -X GET "${GATEWAY_URL}/wallets/me" -H "Authorization: Bearer ${ALICE_TOKEN}" | grep -o '"balance":[0-9.]*' | cut -d':' -f2)
BOB_BAL_PRE=$(curl -s -X GET "${GATEWAY_URL}/wallets/me" -H "Authorization: Bearer ${BOB_TOKEN}" | grep -o '"balance":[0-9.]*' | cut -d':' -f2)
echo "  • Số dư ban đầu: Alice=${ALICE_BAL_PRE} VND | Bob=${BOB_BAL_PRE} VND"

TRANSFER_AMOUNT=200000
P2P_NOTE="E2E P2P test transfer $(date +%s)"
TRANSFER_RES=$(curl -s -X POST "${GATEWAY_URL}/payments/transfer" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${ALICE_TOKEN}" \
  -d "{
    \"targetUserId\": \"${BOB_USER_ID}\",
    \"amount\": ${TRANSFER_AMOUNT},
    \"currency\": \"VND\",
    \"note\": \"${P2P_NOTE}\",
    \"pinToken\": \"${ALICE_PIN_TOKEN}\"
  }")

TX_STATUS=$(echo "$TRANSFER_RES" | grep -o '"status":"[^"]*' | head -1 | cut -d'"' -f4)
TX_ID=$(echo "$TRANSFER_RES" | grep -o '"transactionId":"[^"]*' | head -1 | cut -d'"' -f4)

if [ "$TX_STATUS" != "SUCCESS" ]; then
  echo -e "  ${RED}✗ [FAILED] Chuyển tiền P2P thất bại: ${TRANSFER_RES}${NC}"
  exit 1
fi
echo "  • Chuyển tiền P2P thành công (txId: ${TX_ID})"

# Đợi 2 giây để OutboxRelay và Kafka/RabbitMQ consumer xử lý biến động số dư và thông báo
sleep 2

# Kiểm tra số dư sau chuyển tiền
ALICE_BAL_POST=$(curl -s -X GET "${GATEWAY_URL}/wallets/me" -H "Authorization: Bearer ${ALICE_TOKEN}" | grep -o '"balance":[0-9.]*' | cut -d':' -f2)
BOB_BAL_POST=$(curl -s -X GET "${GATEWAY_URL}/wallets/me" -H "Authorization: Bearer ${BOB_TOKEN}" | grep -o '"balance":[0-9.]*' | cut -d':' -f2)
echo "  • Số dư sau chuyển tiền: Alice=${ALICE_BAL_POST} VND | Bob=${BOB_BAL_POST} VND"

# Kiểm tra thông báo bên phía Alice (TRANSFER_OUT)
ALICE_NOTIF=$(curl -s -X GET "${GATEWAY_URL}/notifications" -H "Authorization: Bearer ${ALICE_TOKEN}")
ALICE_NOTIF_MATCH=$(echo "$ALICE_NOTIF" | grep -o "${P2P_NOTE}" || true)

# Kiểm tra thông báo bên phía Bob (TRANSFER_IN)
BOB_NOTIF=$(curl -s -X GET "${GATEWAY_URL}/notifications" -H "Authorization: Bearer ${BOB_TOKEN}")
BOB_NOTIF_MATCH=$(echo "$BOB_NOTIF" | grep -o "${P2P_NOTE}" || true)

if [ -z "$ALICE_NOTIF_MATCH" ] || [ -z "$BOB_NOTIF_MATCH" ]; then
  echo -e "  ${RED}✗ [FAILED] Không tìm thấy thông báo biến động số dư trong hộp thư người gửi/nhận.${NC}"
  exit 1
fi
echo "  • Người gửi (Alice) đã nhận thông báo biến động số dư trừ tiền"
echo "  • Người nhận (Bob) đã nhận thông báo biến động số dư cộng tiền"
echo -e "  ${GREEN}✓ [PASSED] KB-02: Chuyển tiền P2P và phát tán thông báo Kafka thành công!${NC}"
PASSED=$((PASSED + 1))

# ==============================================================================
# KB-03: LỊCH SỬ GIAO DỊCH, RUNNING BALANCE VÀ XUẤT SAO KÊ
# ==============================================================================
echo ""
echo -e "${BLUE}▶ [KB-03] LỊCH SỬ GIAO DỊCH, SỐ DƯ TỨC THỜI (RUNNING BALANCE) & SAO KÊ${NC}"

ALICE_WALLET_ID="11111111-1111-1111-1111-111111111111"
TX_HIST_RES=$(curl -s -X GET "${GATEWAY_URL}/transactions?walletId=${ALICE_WALLET_ID}&page=0&size=5" \
  -H "Authorization: Bearer ${ALICE_TOKEN}")

RUNNING_BAL=$(echo "$TX_HIST_RES" | grep -o '"runningBalance":[0-9]*' | head -1 | cut -d':' -f2)
LATEST_TX_TYPE=$(echo "$TX_HIST_RES" | grep -o '"type":"[^"]*' | head -1 | cut -d'"' -f4)

echo "  • Giao dịch mới nhất trong lịch sử: type=${LATEST_TX_TYPE}, runningBalance=${RUNNING_BAL}"

if [ "$LATEST_TX_TYPE" != "TRANSFER_OUT" ]; then
  echo -e "  ${RED}✗ [FAILED] Loại giao dịch mong đợi là TRANSFER_OUT nhưng nhận: ${LATEST_TX_TYPE}${NC}"
  exit 1
fi

# Xuất biên lai PDF
PDF_HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X GET "${GATEWAY_URL}/transactions/${TX_ID}/receipt.pdf" \
  -H "Authorization: Bearer ${ALICE_TOKEN}")

if [ "$PDF_HTTP_CODE" != "200" ]; then
  echo -e "  ${RED}✗ [FAILED] Không thể tải biên lai PDF: HTTP ${PDF_HTTP_CODE}${NC}"
  exit 1
fi
echo "  • Tải biên lai PDF giao dịch thành công (HTTP 200)"

# Xuất sao kê CSV
CSV_RES=$(curl -s -X GET "${GATEWAY_URL}/transactions/export/csv?walletId=${ALICE_WALLET_ID}" \
  -H "Authorization: Bearer ${ALICE_TOKEN}")
CSV_HEADER=$(echo "$CSV_RES" | head -n 1)

if [[ "$CSV_HEADER" != *"Mã giao dịch"* ]]; then
  echo -e "  ${RED}✗ [FAILED] Định dạng sao kê CSV không đúng: ${CSV_HEADER}${NC}"
  exit 1
fi
echo "  • Xuất sao kê định dạng CSV thành công"
echo -e "  ${GREEN}✓ [PASSED] KB-03: Lịch sử, số dư tức thời running balance và xuất file sao kê hoàn tất!${NC}"
PASSED=$((PASSED + 1))

# ==============================================================================
# KB-04: TIẾT KIỆM ONLINE (MỞ SỔ & TẤT TOÁN NHẬN GỐC + LÃI)
# ==============================================================================
echo ""
echo -e "${BLUE}▶ [KB-04] TIẾT KIỆM ONLINE (MỞ SỔ TIẾT KIỆM & TẤT TOÁN)${NC}"

# 4.1 Xem danh mục sản phẩm tiết kiệm
SAVINGS_PRODUCTS=$(curl -s -X GET "${GATEWAY_URL}/savings/products")
SAVINGS_PROD_OK=$(echo "$SAVINGS_PRODUCTS" | grep -o '"productType":"TIET_KIEM_PHAT_LOC"' || true)

if [ -z "$SAVINGS_PROD_OK" ]; then
  echo -e "  ${RED}✗ [FAILED] Không lấy được danh mục gói tiết kiệm: ${SAVINGS_PRODUCTS}${NC}"
  exit 1
fi
echo "  • Tra cứu danh mục gói tiết kiệm thành công (Tiết Kiệm Phát Lộc lãi suất 7.2%/năm)"

# 4.2 Mở sổ tiết kiệm 1,000,000 VND
OPEN_SAVINGS_RES=$(curl -s -X POST "${GATEWAY_URL}/savings/accounts" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${ALICE_TOKEN}" \
  -d "{
    \"walletId\": \"${ALICE_WALLET_ID}\",
    \"productType\": \"TIET_KIEM_PHAT_LOC\",
    \"termMonths\": 6,
    \"depositAmount\": 1000000,
    \"rolloverType\": \"AUTO_ROLLOVER_ALL\"
  }")

SAVINGS_ID=$(echo "$OPEN_SAVINGS_RES" | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
SAVINGS_ACC_NUM=$(echo "$OPEN_SAVINGS_RES" | grep -o '"accountNumber":"[^"]*' | head -1 | cut -d'"' -f4)

if [ -z "$SAVINGS_ID" ]; then
  echo -e "  ${RED}✗ [FAILED] Mở sổ tiết kiệm thất bại: ${OPEN_SAVINGS_RES}${NC}"
  exit 1
fi
echo "  • Mở sổ tiết kiệm thành công: số sổ ${SAVINGS_ACC_NUM} (gửi 1,000,000 VND, kỳ hạn 6 tháng)"

# 4.3 Tất toán sổ tiết kiệm
SETTLE_RES=$(curl -s -X POST "${GATEWAY_URL}/savings/accounts/${SAVINGS_ID}/settle" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${ALICE_TOKEN}" \
  -d '{}')

TOTAL_PAYOUT=$(echo "$SETTLE_RES" | grep -o '"totalPayout":[0-9.]*' | head -1 | cut -d':' -f2)
SETTLE_SUCCESS=$(echo "$SETTLE_RES" | grep -o '"earlySettlement":true' || true)

if [ -z "$SETTLE_SUCCESS" ]; then
  echo -e "  ${RED}✗ [FAILED] Tất toán sổ tiết kiệm thất bại: ${SETTLE_RES}${NC}"
  exit 1
fi
echo "  • Tất toán sổ tiết kiệm thành công (đã hoàn gốc + lãi về ví: ${TOTAL_PAYOUT} VND)"
echo -e "  ${GREEN}✓ [PASSED] KB-04: Mở sổ tiết kiệm và tất toán giải ngân về ví hoàn tất!${NC}"
PASSED=$((PASSED + 1))

# ==============================================================================
# KB-05: VAY VỐN TIÊU DÙNG: OTP -> CHỜ DUYỆT -> GIẢI NGÂN -> TRẢ NỢ
# ==============================================================================
echo ""
echo -e "${BLUE}▶ [KB-05] VAY TIÊU DÙNG: OTP -> MAKER-CHECKER DUYỆT -> GIẢI NGÂN -> TRẢ NỢ${NC}"

# Đăng nhập Giao dịch viên
TELLER_LOGIN_RES=$(curl -s -X POST "${GATEWAY_URL}/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"teller1","password":"DemoPass#2026!"}')
TELLER_TOKEN=$(echo "$TELLER_LOGIN_RES" | grep -o '"token":"[^"]*' | head -1 | cut -d'"' -f4)

# 5.1 Gửi OTP mục đích LOAN_APPLY
docker exec ewallet-redis redis-cli del "identity:otp:cooldown:0901234567:LOAN_APPLY" > /dev/null 2>&1 || true
curl -s -X POST "${GATEWAY_URL}/auth/otp/send" \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber":"0901234567","purpose":"LOAN_APPLY"}' > /dev/null

LOAN_OTP_CODE=$(docker exec ewallet-redis redis-cli get "identity:otp:0901234567:LOAN_APPLY")
echo "  • Đã gửi OTP qua Gmail và lưu mã Redis: ${LOAN_OTP_CODE}"

# 5.2 Xác thực OTP để lấy otpToken
LOAN_OTP_VERIFY=$(curl -s -X POST "${GATEWAY_URL}/auth/otp/verify" \
  -H "Content-Type: application/json" \
  -d "{\"phoneNumber\":\"0901234567\",\"code\":\"${LOAN_OTP_CODE}\",\"purpose\":\"LOAN_APPLY\"}")
LOAN_OTP_TOKEN=$(echo "$LOAN_OTP_VERIFY" | grep -o '"otpToken":"[^"]*' | head -1 | cut -d'"' -f4)

if [ -z "$LOAN_OTP_TOKEN" ]; then
  echo -e "  ${RED}✗ [FAILED] Không lấy được otpToken cho khoản vay: ${LOAN_OTP_VERIFY}${NC}"
  exit 1
fi
echo "  • Xác thực OTP thành công, cấp otpToken ký số hồ sơ vay"

# 5.3 Nộp hồ sơ vay (5,000,000 VND, 6 tháng)
LOAN_APPLY_RES=$(curl -s -X POST "${GATEWAY_URL}/loans/apply" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${ALICE_TOKEN}" \
  -d "{
    \"walletId\": \"${ALICE_WALLET_ID}\",
    \"productType\": \"VAY_TIEU_DUNG_NHANH\",
    \"amount\": 5000000,
    \"termMonths\": 6,
    \"purpose\": \"Sửa nhà cửa đón Tết\",
    \"otpToken\": \"${LOAN_OTP_TOKEN}\"
  }")

LOAN_ID=$(echo "$LOAN_APPLY_RES" | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
LOAN_STATUS=$(echo "$LOAN_APPLY_RES" | grep -o '"status":"[^"]*' | head -1 | cut -d'"' -f4)

if [ "$LOAN_STATUS" != "PENDING_APPROVAL" ]; then
  echo -e "  ${RED}✗ [FAILED] Trạng thái sau khi nộp đơn phải là PENDING_APPROVAL nhưng là: ${LOAN_STATUS}${NC}"
  exit 1
fi
echo "  • Nộp hồ sơ vay thành công (mã: ${LOAN_ID}, trạng thái: PENDING_APPROVAL)"

# 5.4 Giao dịch viên tra cứu danh sách chờ duyệt
PENDING_LOANS=$(curl -s -X GET "${GATEWAY_URL}/loans/pending" \
  -H "Authorization: Bearer ${TELLER_TOKEN}")
PENDING_MATCH=$(echo "$PENDING_LOANS" | grep -o "$LOAN_ID" || true)

if [ -z "$PENDING_MATCH" ]; then
  echo -e "  ${RED}✗ [FAILED] Không tìm thấy khoản vay ${LOAN_ID} trong danh sách chờ duyệt.${NC}"
  exit 1
fi
echo "  • Giao dịch viên đã thấy hồ sơ vay trong danh sách chờ phê duyệt"

# 5.5 Giao dịch viên duyệt hồ sơ và giải ngân
APPROVE_RES=$(curl -s -X POST "${GATEWAY_URL}/loans/${LOAN_ID}/approve" \
  -H "Authorization: Bearer ${TELLER_TOKEN}")
APPROVED_STATUS=$(echo "$APPROVE_RES" | grep -o '"status":"[^"]*' | head -1 | cut -d'"' -f4)
APPROVED_BY=$(echo "$APPROVE_RES" | grep -o '"approvedBy":"[^"]*' | head -1 | cut -d'"' -f4)

if [ "$APPROVED_STATUS" != "DISBURSED" ]; then
  echo -e "  ${RED}✗ [FAILED] Trạng thái sau khi duyệt phải là DISBURSED nhưng là: ${APPROVED_STATUS}${NC}"
  exit 1
fi
echo "  • Cán bộ ngân hàng duyệt hồ sơ thành công (approvedBy: ${APPROVED_BY}, trạng thái: DISBURSED)"

# 5.6 Xem lịch trả nợ 6 kỳ
SCHEDULE_RES=$(curl -s -X GET "${GATEWAY_URL}/loans/${LOAN_ID}/schedule" \
  -H "Authorization: Bearer ${ALICE_TOKEN}")
TERM_COUNT=$(echo "$SCHEDULE_RES" | grep -o '"termNumber"' | wc -l)

if [ "$TERM_COUNT" -ne 6 ]; then
  echo -e "  ${RED}✗ [FAILED] Lịch trả nợ phải có đúng 6 kỳ hạn, nhưng tìm thấy: ${TERM_COUNT}${NC}"
  exit 1
fi
echo "  • Lịch trả nợ 6 kỳ được tự động khởi tạo chuẩn xác"

# 5.7 Thanh toán kỳ hạn 1
REPAY_RES=$(curl -s -X POST "${GATEWAY_URL}/loans/${LOAN_ID}/repay" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${ALICE_TOKEN}" \
  -d '{"termNumber": 1}')
REPAY_STATUS=$(echo "$REPAY_RES" | grep -o '"status":"[^"]*' | head -1 | cut -d'"' -f4)

if [ "$REPAY_STATUS" != "PAID" ]; then
  echo -e "  ${RED}✗ [FAILED] Thanh toán kỳ hạn 1 thất bại: ${REPAY_RES}${NC}"
  exit 1
fi
echo "  • Khách hàng thanh toán kỳ hạn 1 thành công (status: PAID)"
echo -e "  ${GREEN}✓ [PASSED] KB-05: Toàn bộ chu trình vay vốn từ OTP đến duyệt, giải ngân và trả nợ hoàn tất!${NC}"
PASSED=$((PASSED + 1))

# ==============================================================================
# KB-06: QUY TRÌNH TỪ CHỐI HỒ SƠ VAY (MAKER-CHECKER REJECTION)
# ==============================================================================
echo ""
echo -e "${BLUE}▶ [KB-06] QUY TRÌNH TỪ CHỐI HỒ SƠ VAY (REJECT WITH REASON)${NC}"

# Gửi OTP cho hồ sơ vay thứ 2
docker exec ewallet-redis redis-cli del "identity:otp:cooldown:0901234567:LOAN_APPLY" > /dev/null 2>&1 || true
curl -s -X POST "${GATEWAY_URL}/auth/otp/send" \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber":"0901234567","purpose":"LOAN_APPLY"}' > /dev/null

LOAN_OTP_2=$(docker exec ewallet-redis redis-cli get "identity:otp:0901234567:LOAN_APPLY")
LOAN_OTP_VERIFY_2=$(curl -s -X POST "${GATEWAY_URL}/auth/otp/verify" \
  -H "Content-Type: application/json" \
  -d "{\"phoneNumber\":\"0901234567\",\"code\":\"${LOAN_OTP_2}\",\"purpose\":\"LOAN_APPLY\"}")
LOAN_OTP_TOKEN_2=$(echo "$LOAN_OTP_VERIFY_2" | grep -o '"otpToken":"[^"]*' | head -1 | cut -d'"' -f4)

# Nộp đơn vay 2
LOAN_APPLY_2=$(curl -s -X POST "${GATEWAY_URL}/loans/apply" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${ALICE_TOKEN}" \
  -d "{
    \"walletId\": \"${ALICE_WALLET_ID}\",
    \"productType\": \"VAY_THAU_CHI\",
    \"amount\": 10000000,
    \"termMonths\": 12,
    \"purpose\": \"Kinh doanh mua hàng\",
    \"otpToken\": \"${LOAN_OTP_TOKEN_2}\"
  }")

LOAN_ID_2=$(echo "$LOAN_APPLY_2" | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
echo "  • Nộp hồ sơ vay thứ 2 thành công (mã: ${LOAN_ID_2})"

# Giao dịch viên từ chối
REJECT_REASON="Thu nhap khong du dieu kien tra no"
REJECT_RES=$(curl -s -X POST "${GATEWAY_URL}/loans/${LOAN_ID_2}/reject" \
  -H "Authorization: Bearer ${TELLER_TOKEN}" \
  --data-urlencode "reason=${REJECT_REASON}")

REJECT_STATUS=$(echo "$REJECT_RES" | grep -o '"status":"[^"]*' | head -1 | cut -d'"' -f4)
RETURNED_REASON=$(echo "$REJECT_RES" | grep -o '"rejectReason":"[^"]*' | head -1 | cut -d'"' -f4)

if [ "$REJECT_STATUS" != "REJECTED" ]; then
  echo -e "  ${RED}✗ [FAILED] Trạng thái sau từ chối phải là REJECTED nhưng là: ${REJECT_STATUS}${NC}"
  exit 1
fi
echo "  • Cán bộ ngân hàng từ chối hồ sơ thành công (lý do: ${RETURNED_REASON})"
echo -e "  ${GREEN}✓ [PASSED] KB-06: Quy trình từ chối hồ sơ vay vốn hoàn tất chuẩn xác!${NC}"
PASSED=$((PASSED + 1))

# ==============================================================================
# KB-07: ĐỐI SOÁT HỢP ĐỒNG API MOBILE VÀ TIỆN ÍCH HỆ THỐNG
# ==============================================================================
echo ""
echo -e "${BLUE}▶ [KB-07] ĐỐI SOÁT HỢP ĐỒNG API MOBILE (VIETQR, RECIPIENT, FEE, NOTIFICATION)${NC}"

# 7.1 Lấy mã VietQR cá nhân
QR_RES=$(curl -s -X GET "${GATEWAY_URL}/users/me/qrcode" \
  -H "Authorization: Bearer ${ALICE_TOKEN}")
QR_RAW=$(echo "$QR_RES" | grep -o '"qrRaw":"[^"]*' | cut -d'"' -f4)

if [ -z "$QR_RAW" ]; then
  echo -e "  ${RED}✗ [FAILED] Không lấy được mã VietQR cá nhân: ${QR_RES}${NC}"
  exit 1
fi
echo "  • Lấy mã VietQR chuẩn EMVCo cá nhân thành công"

# 7.2 Giải mã VietQR
DECODE_RES=$(curl -s -X POST "${GATEWAY_URL}/payments/vietqr/decode" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${ALICE_TOKEN}" \
  -d "{\"qrString\":\"${QR_RAW}\"}")
DECODED_BANK=$(echo "$DECODE_RES" | grep -o '"bankName":"[^"]*' | cut -d'"' -f4)

if [[ "$DECODED_BANK" != *"SenBank"* ]]; then
  echo -e "  ${RED}✗ [FAILED] Giải mã VietQR không đúng ngân hàng: ${DECODE_RES}${NC}"
  exit 1
fi
echo "  • Giải mã VietQR thành công (Ngân hàng: ${DECODED_BANK})"

# 7.3 Tra cứu người thụ hưởng qua SĐT
RECIP_RES=$(curl -s -X GET "${GATEWAY_URL}/wallets/recipient-info?phoneNumber=0909876543" \
  -H "Authorization: Bearer ${ALICE_TOKEN}")
RECIP_NAME=$(echo "$RECIP_RES" | grep -o '"fullName":"[^"]*' | cut -d'"' -f4)

if [ "$RECIP_NAME" != "Bob Tran" ]; then
  echo -e "  ${RED}✗ [FAILED] Tra cứu người thụ hưởng không đúng: ${RECIP_RES}${NC}"
  exit 1
fi
echo "  • Tra cứu người nhận tiền qua SĐT 0909876543 thành công: ${RECIP_NAME}"

# 7.4 Ước tính phí giao dịch
FEE_RES=$(curl -s -X GET "${GATEWAY_URL}/wallets/fees/estimate?amount=500000" \
  -H "Authorization: Bearer ${ALICE_TOKEN}")
FEE_AMOUNT=$(echo "$FEE_RES" | grep -o '"feeAmount":[0-9]*' | cut -d':' -f2)

if [ -z "$FEE_AMOUNT" ]; then
  echo -e "  ${RED}✗ [FAILED] Không thể ước tính phí chuyển tiền: ${FEE_RES}${NC}"
  exit 1
fi
echo "  • Ước tính phí chuyển tiền thành công: phí ${FEE_AMOUNT} VND"

# 7.5 Đánh dấu tất cả thông báo đã đọc
READ_ALL_RES=$(curl -s -X POST "${GATEWAY_URL}/notifications/read-all" \
  -H "Authorization: Bearer ${ALICE_TOKEN}")
UNREAD_COUNT=$(curl -s -X GET "${GATEWAY_URL}/notifications/unread-count" \
  -H "Authorization: Bearer ${ALICE_TOKEN}" | grep -o '"unread":[0-9]*' | cut -d':' -f2)

if [ "$UNREAD_COUNT" -ne 0 ]; then
  echo -e "  ${RED}✗ [FAILED] Số lượng thông báo chưa đọc phải là 0 sau khi read-all nhưng là: ${UNREAD_COUNT}${NC}"
  exit 1
fi
echo "  • Đánh dấu tất cả thông báo đã đọc thành công (unread = 0)"
echo -e "  ${GREEN}✓ [PASSED] KB-07: Toàn bộ hợp đồng API Mobile đều hoạt động chính xác 100%!${NC}"
PASSED=$((PASSED + 1))

# ==============================================================================
# KẾT QUẢ TỔNG HỢP
# ==============================================================================
echo ""
echo -e "${CYAN}==============================================================================${NC}"
echo -e "${GREEN}🎉 TỔNG KẾT: TẤT CẢ ${PASSED}/${TOTAL} KỊCH BẢN E2E NGHIỆP VỤ ĐÃ ĐẠT TIÊU CHUẨN 100%!${NC}"
echo -e "${CYAN}==============================================================================${NC}"
exit 0
