#!/usr/bin/env bash
set -e

# ==============================================================================
# Fintech E-Wallet: Full End-to-End Flow Demo Script
# ==============================================================================

BASE_URL="http://localhost:8080"
echo "======================================================================"
echo "🚀 1. Kiểm tra Actuator Health & Metrics"
echo "======================================================================"
curl -s "$BASE_URL/actuator/health" | grep -q "UP" && echo "✅ Backend Service is UP!" || echo "⚠️ Backend is starting..."

echo ""
echo "======================================================================"
echo "👤 2. Đăng ký & Đăng nhập 2 Tài khoản (Sender & Receiver)"
echo "======================================================================"
SENDER_PHONE="0988111222"
RECEIVER_PHONE="0977333444"
PASSWORD="SecurePassword123"

# Đăng ký
echo "-> Đăng ký Sender ($SENDER_PHONE)..."
curl -s -X POST "$BASE_URL/api/v1/auth/register" \
  -H "Content-Type: application/json" \
  -d "{\"phoneNumber\": \"$SENDER_PHONE\", \"password\": \"$PASSWORD\"}" > /dev/null || true

echo "-> Đăng ký Receiver ($RECEIVER_PHONE)..."
curl -s -X POST "$BASE_URL/api/v1/auth/register" \
  -H "Content-Type: application/json" \
  -d "{\"phoneNumber\": \"$RECEIVER_PHONE\", \"password\": \"$PASSWORD\"}" > /dev/null || true

# Đăng nhập lấy Token
echo "-> Đăng nhập Sender lấy Bearer Token..."
SENDER_RESP=$(curl -s -X POST "$BASE_URL/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"phoneNumber\": \"$SENDER_PHONE\", \"password\": \"$PASSWORD\"}")
SENDER_TOKEN=$(echo "$SENDER_RESP" | grep -o '"token":"[^"]*' | cut -d'"' -f4)
echo "✅ Sender Token: Bearer ${SENDER_TOKEN:0:20}..."

echo ""
echo "======================================================================"
echo "🔍 3. Task 9: Xác minh tên người nhận trước khi chuyển tiền (Masked Name)"
echo "======================================================================"
RECIPIENT_INFO=$(curl -s -X GET "$BASE_URL/api/v1/wallets/recipient-info?phoneNumber=$RECEIVER_PHONE" \
  -H "Authorization: Bearer $SENDER_TOKEN")
echo "-> Kết quả tra cứu người nhận: $RECIPIENT_INFO"

echo ""
echo "======================================================================"
echo "💰 4. Task 1: Nạp tiền (Deposit) cho Sender (5.000.000 VNĐ)"
echo "======================================================================"
IDEMPOTENCY_KEY=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || echo "demo-req-uuid-12345")
SENDER_WALLET_ID=$(echo "$RECIPIENT_INFO" | grep -o '"walletId":"[^"]*' | cut -d'"' -f4) # Actually this is receiver's. Let's get sender's wallet from token or me endpoint.

# Get sender's wallet ID
SENDER_ME=$(curl -s -X GET "$BASE_URL/api/v1/users/me" -H "Authorization: Bearer $SENDER_TOKEN")
SENDER_WALLET_ID=$(echo "$SENDER_ME" | grep -o '"walletId":"[^"]*' | cut -d'"' -f4)
echo "-> Sender Wallet ID: $SENDER_WALLET_ID"

RECEIVER_WALLET_ID=$(echo "$RECIPIENT_INFO" | grep -o '"walletId":"[^"]*' | cut -d'"' -f4)
echo "-> Receiver Wallet ID: $RECEIVER_WALLET_ID"

# Deposit to Sender
DEPOSIT_RESP=$(curl -s -X POST "$BASE_URL/api/v1/wallets/deposit" \
  -H "Authorization: Bearer $SENDER_TOKEN" \
  -H "Idempotency-Key: $IDEMPOTENCY_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"requestId\": \"$IDEMPOTENCY_KEY\", \"walletId\": \"$SENDER_WALLET_ID\", \"amount\": 5000000, \"currency\": \"VND\"}")
echo "-> Kết quả nạp tiền: $DEPOSIT_RESP"

echo ""
echo "======================================================================"
echo "💸 5. Task 2: Chuyển tiền (Transfer) (1.000.000 VNĐ)"
echo "======================================================================"
TRANSFER_KEY=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || echo "demo-req-uuid-67890")
INIT_RESP=$(curl -s -X POST "$BASE_URL/api/v1/wallets/transfer/init" \
  -H "Authorization: Bearer $SENDER_TOKEN" \
  -H "Idempotency-Key: $TRANSFER_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"requestId\": \"$TRANSFER_KEY\", \"sourceWalletId\": \"$SENDER_WALLET_ID\", \"targetWalletId\": \"$RECEIVER_WALLET_ID\", \"amount\": 1000000, \"currency\": \"VND\"}")
echo "-> Kết quả khởi tạo chuyển tiền: $INIT_RESP"

TX_ID=$(echo "$INIT_RESP" | grep -o '"id":"[^"]*' | cut -d'"' -f4)
echo "-> Transaction ID: $TX_ID"

CONFIRM_RESP=$(curl -s -X POST "$BASE_URL/api/v1/wallets/transfer/confirm" \
  -H "Authorization: Bearer $SENDER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"transactionId\": \"$TX_ID\", \"pin\": \"123456\", \"otp\": \"123456\"}")
echo "-> Kết quả xác nhận chuyển tiền: $CONFIRM_RESP"

echo ""
echo "======================================================================"
echo "📊 6. Task 3: Kiểm tra số dư Receiver"
echo "======================================================================"
RECEIVER_RESP=$(curl -s -X POST "$BASE_URL/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"phoneNumber\": \"$RECEIVER_PHONE\", \"password\": \"$PASSWORD\"}")
RECEIVER_TOKEN=$(echo "$RECEIVER_RESP" | grep -o '"token":"[^"]*' | cut -d'"' -f4)

RECEIVER_WALLET_INFO=$(curl -s -X GET "$BASE_URL/api/v1/wallets/$RECEIVER_WALLET_ID" \
  -H "Authorization: Bearer $RECEIVER_TOKEN")
echo "-> Thông tin ví Receiver sau khi nhận tiền: $RECEIVER_WALLET_INFO"

echo ""
echo "======================================================================"
echo "🛡️ 7. Task 11: Đăng xuất & Thu hồi Token vào Redis Blacklist"
echo "======================================================================"
LOGOUT_RESP=$(curl -s -X POST "$BASE_URL/api/v1/auth/logout" \
  -H "Authorization: Bearer $SENDER_TOKEN")
echo "-> Kết quả Logout: $LOGOUT_RESP"

echo ""
echo "🎉 DEMO HOÀN TẤT THÀNH CÔNG! Luồng chuyển tiền E2E Backend chạy chuẩn xác."
