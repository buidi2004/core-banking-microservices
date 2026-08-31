#!/bin/bash
set -e

BASE_URL="http://localhost:8080/api/v1"
USER_A_PHONE="090"$(date +%s | cut -c4-10)
USER_A_PASS="Password123!"
USER_B_PHONE="091"$(date +%s | cut -c4-10)
USER_B_PASS="Password123!"

echo "=== 1. Register User A ($USER_A_PHONE) ==="
curl -s -X POST "$BASE_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d "{\"phoneNumber\":\"$USER_A_PHONE\", \"password\":\"$USER_A_PASS\"}" 

echo "=== 2. Login User A ==="
LOGIN_A_RESP=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"phoneNumber\":\"$USER_A_PHONE\", \"password\":\"$USER_A_PASS\", \"deviceId\":\"dev1\"}")
TOKEN_A=$(echo $LOGIN_A_RESP | jq -r '.data.accessToken')

echo "=== 2.5 Set User A PIN ==="
curl -s -X POST "$BASE_URL/users/pin/set" \
  -H "Authorization: Bearer $TOKEN_A" \
  -H "Content-Type: application/json" \
  -d "{\"pin\":\"123456\"}" > /dev/null

echo "=== 3. Get User A Wallet ID ==="
WALLET_A_INFO=$(curl -s -X GET "$BASE_URL/wallets/recipient-info?phoneNumber=$USER_A_PHONE" \
  -H "Authorization: Bearer $TOKEN_A")
WALLET_A_ID=$(echo $WALLET_A_INFO | jq -r '.data.walletId')
echo "User A Wallet ID: $WALLET_A_ID"

echo "=== 4. Deposit 10,000,000 to User A ==="
REQ_ID_DEP=$(uuidgen)
curl -s -X POST "$BASE_URL/wallets/deposit" \
  -H "Authorization: Bearer $TOKEN_A" \
  -H "Content-Type: application/json" \
  -d "{\"requestId\":\"$REQ_ID_DEP\", \"walletId\":\"$WALLET_A_ID\", \"amount\":10000000, \"currency\":\"VND\"}" 

echo "=== 5. Register User B ($USER_B_PHONE) ==="
curl -s -X POST "$BASE_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d "{\"phoneNumber\":\"$USER_B_PHONE\", \"password\":\"$USER_B_PASS\"}" 

echo "=== 6. Login User B ==="
LOGIN_B_RESP=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"phoneNumber\":\"$USER_B_PHONE\", \"password\":\"$USER_B_PASS\", \"deviceId\":\"dev2\"}")
TOKEN_B=$(echo $LOGIN_B_RESP | jq -r '.data.accessToken')

echo "=== 7. Get User B Wallet ID ==="
WALLET_B_INFO=$(curl -s -X GET "$BASE_URL/wallets/recipient-info?phoneNumber=$USER_B_PHONE" \
  -H "Authorization: Bearer $TOKEN_B")
WALLET_B_ID=$(echo $WALLET_B_INFO | jq -r '.data.walletId')
echo "User B Wallet ID: $WALLET_B_ID"

echo "=== 8. Transfer 5,000,000 from User A to User B ==="
REQ_ID_TRANS=$(uuidgen)
TRANS_RESP=$(curl -s -X POST "$BASE_URL/wallets/transfer/init" \
  -H "Authorization: Bearer $TOKEN_A" \
  -H "Content-Type: application/json" \
  -d "{\"requestId\":\"$REQ_ID_TRANS\", \"sourceWalletId\":\"$WALLET_A_ID\", \"targetWalletId\":\"$WALLET_B_ID\", \"amount\":5000000, \"currency\":\"VND\", \"note\":\"Chuyen tien E2E Test\"}")

TX_ID=$(echo $TRANS_RESP | jq -r '.data.transactionId')
echo "Transaction ID: $TX_ID"

echo "=== 9. Confirm Transfer ==="
curl -s -X POST "$BASE_URL/wallets/transfer/$TX_ID/confirm?pin=123456" \
  -H "Authorization: Bearer $TOKEN_A" \
  -H "Content-Type: application/json" \
  -d "{}" 

echo "Waiting for RabbitMQ consumers (3s)..."
sleep 3

echo "=== 10. Check Ledger ==="
# We check DB directly for the journal entries
docker exec -i wallet-postgres psql -U walletuser -d walletdb -c "SELECT description, amount, entry_type FROM journal_entries je JOIN ledger_postings lp ON je.id = lp.journal_entry_id WHERE je.transaction_id = '$TX_ID';"

echo "=== 11. Check User A Balance ==="
WALLET_A_FINAL=$(curl -s -X GET "$BASE_URL/wallets/$WALLET_A_ID" -H "Authorization: Bearer $TOKEN_A")
echo $WALLET_A_FINAL | jq -r '.data.balance'

echo "=== 12. Check User B Balance ==="
WALLET_B_FINAL=$(curl -s -X GET "$BASE_URL/wallets/$WALLET_B_ID" -H "Authorization: Bearer $TOKEN_B")
echo $WALLET_B_FINAL | jq -r '.data.balance'

echo "=== Done ==="
