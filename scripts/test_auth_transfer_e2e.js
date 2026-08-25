const BASE_URL = "http://localhost:8080/api/v1";

async function safeFetch(url, options) {
  try {
    const res = await fetch(url, options);
    return await res.json();
  } catch (e) {
    return { success: false, message: e.message };
  }
}

function generateRandomPhone() {
  return "09" + Math.floor(Math.random() * 100000000).toString().padStart(8, '0');
}

async function runTest() {
  console.log("=========================================================");
  console.log("🔥 CHUYÊN SÂU E2E: LUỒNG ĐĂNG NHẬP / ĐĂNG KÝ & CHUYỂN TIỀN");
  console.log("=========================================================\n");

  const PHONE_1 = generateRandomPhone();
  const PHONE_2 = generateRandomPhone();
  const PASSWORD = "SecurePassword123!";

  console.log(`[SETUP] Generated Test Phones: Sender=${PHONE_1}, Receiver=${PHONE_2}\n`);

  // --- 1. LUỒNG ĐĂNG KÝ (REGISTER FLOW) ---
  console.log("▶️ KỊCH BẢN 1: Đăng ký tài khoản mới (Happy Path)");
  const reg1 = await safeFetch(`${BASE_URL}/auth/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ phoneNumber: PHONE_1, password: PASSWORD })
  });
  if (reg1.success && reg1.data.accessToken) {
    console.log("   ✅ Pass: Đăng ký thành công, nhận được accessToken & refreshToken.");
  } else {
    console.log(`   ❌ Fail: ${reg1.message || JSON.stringify(reg1)}`);
  }

  console.log("\n▶️ KỊCH BẢN 2: Đăng ký lại với số điện thoại đã tồn tại (Conflict)");
  const regDup = await safeFetch(`${BASE_URL}/auth/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ phoneNumber: PHONE_1, password: PASSWORD })
  });
  if (!regDup.success && (regDup.message.includes('exists') || regDup.message.includes('tồn tại'))) {
    console.log("   ✅ Pass: Hệ thống chặn đăng ký trùng lặp.");
  } else {
    console.log(`   ❌ Fail (Hoặc cảnh báo): ${regDup.message}`);
  }

  // --- 2. LUỒNG ĐĂNG NHẬP (LOGIN FLOW) ---
  console.log("\n▶️ KỊCH BẢN 3: Đăng nhập sai mật khẩu (Unauthorized)");
  const loginFail = await safeFetch(`${BASE_URL}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ phoneNumber: PHONE_1, password: "WrongPassword" })
  });
  if (!loginFail.success) {
    console.log("   ✅ Pass: Hệ thống chặn đăng nhập sai mật khẩu.");
  } else {
    console.log(`   ❌ Fail: Đăng nhập sai mật khẩu lại thành công?`);
  }

  console.log("\n▶️ KỊCH BẢN 4: Đăng nhập tài khoản không tồn tại (Not Found)");
  const loginNotExist = await safeFetch(`${BASE_URL}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ phoneNumber: "0999999999", password: PASSWORD })
  });
  if (!loginNotExist.success) {
    console.log("   ✅ Pass: Hệ thống chặn tài khoản không tồn tại.");
  } else {
    console.log(`   ❌ Fail: Đăng nhập tài khoản không tồn tại lại thành công?`);
  }

  console.log("\n▶️ KỊCH BẢN 5: Đăng nhập thành công (Happy Path)");
  const loginSuccess = await safeFetch(`${BASE_URL}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ phoneNumber: PHONE_1, password: PASSWORD })
  });
  let token1 = "";
  if (loginSuccess.success && loginSuccess.data.accessToken) {
    console.log("   ✅ Pass: Đăng nhập thành công, nhận được Tokens.");
    token1 = loginSuccess.data.accessToken;
  } else {
    console.log(`   ❌ Fail: ${loginSuccess.message}`);
    return;
  }

  // Đăng ký tài khoản thứ 2 để làm người nhận tiền
  console.log("\n[SETUP] Đăng ký tài khoản Người Nhận...");
  const reg2 = await safeFetch(`${BASE_URL}/auth/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ phoneNumber: PHONE_2, password: PASSWORD })
  });
  let token2 = reg2.data.accessToken;

  // Lấy Wallet ID của cả 2
  const info1 = await safeFetch(`${BASE_URL}/wallets/recipient-info?phoneNumber=${PHONE_1}`, { headers: { 'Authorization': `Bearer ${token1}` }});
  const info2 = await safeFetch(`${BASE_URL}/wallets/recipient-info?phoneNumber=${PHONE_2}`, { headers: { 'Authorization': `Bearer ${token1}` }});
  const wallet1 = info1.data.walletId;
  const wallet2 = info2.data.walletId;

  // Cài mã PIN cho Sender
  await safeFetch(`${BASE_URL}/users/pin/set`, { method: 'POST', headers: { 'Authorization': `Bearer ${token1}`, 'Content-Type': 'application/json' }, body: JSON.stringify({ pin: '111111' })});

  // --- 3. LUỒNG CHUYỂN TIỀN (TRANSFER FLOW) ---
  console.log("\n▶️ KỊCH BẢN 6: Chuyển tiền khi số dư bằng 0 (Insufficient Balance)");
  const transferInitFail = await safeFetch(`${BASE_URL}/wallets/transfer/init`, {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${token1}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ requestId: Date.now().toString(), sourceWalletId: wallet1, targetWalletId: wallet2, amount: 50000, currency: "VND" })
  });
  if (!transferInitFail.success) {
    console.log("   ✅ Pass: Hệ thống chặn chuyển tiền vì không đủ số dư.");
  } else {
    console.log("   ❌ Fail: Không đủ số dư mà vẫn init được transfer.");
  }

  console.log("\n▶️ KỊCH BẢN 7: Bơm tiền giả lập (Deposit) cho ví nguồn");
  const deposit = await safeFetch(`${BASE_URL}/wallets/deposit`, {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${token1}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ requestId: Date.now().toString(), walletId: wallet1, amount: 1000000, currency: "VND" })
  });
  if (deposit.success) {
    console.log("   ✅ Pass: Nạp 1,000,000 VND thành công.");
  }

  console.log("\n▶️ KỊCH BẢN 8: Chuyển tiền tới Checkout thành công (Happy Path)");
  // Init Transfer
  const transferInit = await safeFetch(`${BASE_URL}/wallets/transfer/init`, {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${token1}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ requestId: Date.now().toString(), sourceWalletId: wallet1, targetWalletId: wallet2, amount: 200000, currency: "VND" })
  });
  if (transferInit.success) {
    console.log(`   ✅ Pass: Init Transfer thành công. Mã giao dịch: ${transferInit.data.transactionId}`);
    
    // Confirm Transfer
    const confirm = await safeFetch(`${BASE_URL}/wallets/transfer/${transferInit.data.transactionId}/confirm?pin=111111`, {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${token1}`, 'Content-Type': 'application/json' }
    });

    if (confirm.success) {
      console.log("   ✅ Pass: Confirm Transfer thành công. Chuyển tiền hoàn tất (Checkout Done)!");
      
      // Kiểm tra số dư cuối cùng
      const checkBal1 = await safeFetch(`${BASE_URL}/wallets/${wallet1}`, { headers: { 'Authorization': `Bearer ${token1}` }});
      const checkBal2 = await safeFetch(`${BASE_URL}/wallets/${wallet2}`, { headers: { 'Authorization': `Bearer ${token1}` }});
      
      if (checkBal1.data.balanceAmount === 800000) {
         console.log("   ✅ Pass: Số dư người gửi đã trừ chính xác (800,000 VND).");
      }
      if (checkBal2.data.balanceAmount === 200000) {
         console.log("   ✅ Pass: Số dư người nhận đã cộng chính xác (200,000 VND).");
      }

    } else {
      console.log(`   ❌ Fail: Confirm lỗi - ${confirm.message}`);
    }
  } else {
    console.log(`   ❌ Fail: Init lỗi - ${transferInit.message}`);
  }

  console.log("\n🎉 HOÀN TẤT KIỂM TRA CHUYÊN SÂU!");
}

runTest();
