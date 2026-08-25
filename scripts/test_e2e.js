const BASE_URL = "http://localhost:8080/api/v1";

async function safeFetch(url, options) {
  try {
    const res = await fetch(url, options);
    return await res.json();
  } catch (e) {
    return { success: false, message: e.message };
  }
}

async function runTest() {
  console.log("=========================================================");
  console.log("🔥 MULTI-SCENARIO E2E TEST SCRIPT");
  console.log("=========================================================\n");

  const SENDER_PHONE = "0988111222";
  const RECEIVER_PHONE = "0977333444";
  const PASSWORD = "SecurePassword123";

  // 1. SETUP
  let senderLogin = await safeFetch(`${BASE_URL}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ phoneNumber: SENDER_PHONE, password: PASSWORD })
  });
  if (!senderLogin.data) {
     // Re-register if DB dropped
     await safeFetch(`${BASE_URL}/auth/register`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ phoneNumber: SENDER_PHONE, password: PASSWORD })});
     senderLogin = await safeFetch(`${BASE_URL}/auth/login`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ phoneNumber: SENDER_PHONE, password: PASSWORD })});
  }
  const SENDER_TOKEN = senderLogin.data.accessToken;

  let receiverLogin = await safeFetch(`${BASE_URL}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ phoneNumber: RECEIVER_PHONE, password: PASSWORD })
  });
  if (!receiverLogin.data) {
     await safeFetch(`${BASE_URL}/auth/register`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ phoneNumber: RECEIVER_PHONE, password: PASSWORD })});
     receiverLogin = await safeFetch(`${BASE_URL}/auth/login`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ phoneNumber: RECEIVER_PHONE, password: PASSWORD })});
  }
  const RECEIVER_TOKEN = receiverLogin.data.accessToken;

  await safeFetch(`${BASE_URL}/users/pin/set`, { method: 'POST', headers: { 'Authorization': `Bearer ${SENDER_TOKEN}`, 'Content-Type': 'application/json' }, body: JSON.stringify({ pin: '123456' })});
  
  const senderInfo = await safeFetch(`${BASE_URL}/wallets/recipient-info?phoneNumber=${SENDER_PHONE}`, { headers: { 'Authorization': `Bearer ${SENDER_TOKEN}` }});
  const SENDER_WALLET_ID = senderInfo.data.walletId;
  const receiverInfo = await safeFetch(`${BASE_URL}/wallets/recipient-info?phoneNumber=${RECEIVER_PHONE}`, { headers: { 'Authorization': `Bearer ${SENDER_TOKEN}` }});
  const RECEIVER_WALLET_ID = receiverInfo.data.walletId;

  console.log("✅ Setup Complete. Running Scenarios...\n");

  // --- SCENARIO 1: INSUFFICIENT BALANCE ---
  console.log("▶️ SCENARIO 1: Chuyển tiền vượt quá số dư (Insufficient Balance)");
  const initFailRes = await safeFetch(`${BASE_URL}/wallets/transfer/init`, {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${SENDER_TOKEN}`, 'Content-Type': 'application/json', 'Idempotency-Key': 'req-sc1' },
    body: JSON.stringify({ requestId: 'req-sc1', sourceWalletId: SENDER_WALLET_ID, targetWalletId: RECEIVER_WALLET_ID, amount: 999999999, currency: "VND" })
  });
  console.log(`   [RESULT]: ${initFailRes.message || initFailRes.errorCode}`);
  if (!initFailRes.success) console.log("   ✅ Pass: BE correctly blocked insufficient balance.\n");

  // --- SCENARIO 2: INVALID PIN ---
  console.log("▶️ SCENARIO 2: Nhập sai mã PIN (Invalid PIN)");
  const initS2Res = await safeFetch(`${BASE_URL}/wallets/transfer/init`, {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${SENDER_TOKEN}`, 'Content-Type': 'application/json', 'Idempotency-Key': 'req-sc2' },
    body: JSON.stringify({ requestId: 'req-sc2', sourceWalletId: SENDER_WALLET_ID, targetWalletId: RECEIVER_WALLET_ID, amount: 10000, currency: "VND" })
  });
  const tx2Id = initS2Res.data?.transactionId;
  const confirmS2Res = await safeFetch(`${BASE_URL}/wallets/transfer/${tx2Id}/confirm?pin=999999`, {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${SENDER_TOKEN}`, 'Content-Type': 'application/json' }
  });
  console.log(`   [RESULT]: ${confirmS2Res.message || confirmS2Res.errorCode}`);
  if (!confirmS2Res.success && confirmS2Res.message.includes('Invalid PIN')) console.log("   ✅ Pass: BE blocked wrong PIN.\n");

  // --- SCENARIO 3: SELF TRANSFER ---
  console.log("▶️ SCENARIO 3: Tự chuyển tiền cho chính mình (Self Transfer)");
  const initS3Res = await safeFetch(`${BASE_URL}/wallets/transfer/init`, {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${SENDER_TOKEN}`, 'Content-Type': 'application/json', 'Idempotency-Key': 'req-sc3' },
    body: JSON.stringify({ requestId: 'req-sc3', sourceWalletId: SENDER_WALLET_ID, targetWalletId: SENDER_WALLET_ID, amount: 10000, currency: "VND" })
  });
  console.log(`   [RESULT]: ${initS3Res.message || initS3Res.errorCode}`);
  if (!initS3Res.success) console.log("   ✅ Pass: BE prevented self-transfer.\n");

  // --- SCENARIO 4: WITHDRAW (HAPPY PATH) ---
  console.log("▶️ SCENARIO 4: Rút tiền từ ví (Withdraw)");
  // 1. Verify PIN to get pinToken
  const pinVerifyRes = await safeFetch(`${BASE_URL}/users/pin/verify`, {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${SENDER_TOKEN}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ pin: '123456' })
  });
  const pinToken = pinVerifyRes.data;
  
  if (!pinToken) {
    console.log(`   ❌ Fail: Could not get pinToken. ${pinVerifyRes.message}\n`);
  } else {
    const WITHDRAW_REQ = "req-wd-" + Date.now();
    const withdrawRes = await safeFetch(`${BASE_URL}/wallets/withdraw`, {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${SENDER_TOKEN}`, 'Idempotency-Key': WITHDRAW_REQ, 'Content-Type': 'application/json' },
      body: JSON.stringify({ requestId: WITHDRAW_REQ, walletId: SENDER_WALLET_ID, amount: 500000, currency: "VND", bankAccountId: "mock-bank-123", pinToken: pinToken })
    });
    if (withdrawRes.success) console.log("   ✅ Pass: BE successfully processed withdrawal of 500,000 VND.\n");
    else console.log(`   ❌ Fail: ${withdrawRes.message}\n`);
  }

  // --- SCENARIO 5: TRANSACTION HISTORY CHECK ---
  console.log("▶️ SCENARIO 5: Truy vấn lịch sử giao dịch (History)");
  const historyRes = await safeFetch(`${BASE_URL}/transactions?walletId=${SENDER_WALLET_ID}`, {
    headers: { 'Authorization': `Bearer ${SENDER_TOKEN}` }
  });
  if (historyRes.success && historyRes.data.length > 0) {
    const latestTx = historyRes.data[0];
    console.log(`   ✅ Pass: BE returned ${historyRes.data.length} transactions. Latest: ${latestTx.type} - ${latestTx.amount} VND.\n`);
  } else {
    console.log(`   ❌ Fail: History fetch failed or empty.\n`);
  }

  // --- SCENARIO 6: BRUTE FORCE LOGIN PREVENTION ---
  console.log("▶️ SCENARIO 6: Tấn công dò mật khẩu (Brute-force Login)");
  let bruteRes;
  for (let i = 1; i <= 6; i++) {
    bruteRes = await safeFetch(`${BASE_URL}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ phoneNumber: "0999999999", password: "wrongpassword" })
    });
    if (i === 5) {
      console.log(`   [Attempt 5]: ${bruteRes.message}`);
    }
  }
  if (bruteRes.message && bruteRes.message.includes('khóa')) {
    console.log("   ✅ Pass: BE successfully locked the account after 5 failed attempts.\n");
  } else {
    console.log(`   ❌ Fail: Account was not locked. Last message: ${bruteRes.message}\n`);
  }

}

runTest().catch(console.error);
