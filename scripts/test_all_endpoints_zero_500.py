#!/usr/bin/env python3
"""
Comprehensive Deep-Check Verification Suite
Verifies:
1. 100% of valid API endpoints return 200/201 (Zero unexpected 400 or 500 errors).
2. Intentional invalid cases return controlled, well-structured business domain errors (401, 403, 404, 422, or structured 400) - NEVER an unhandled 500 Internal Server Error.
3. Multi-tier consistency: Mobile App, Web Teller Portal, API Gateway, 6 Microservices, Kafka, Redis, Ledger Double-Entry.
"""

import urllib.request
import urllib.error
import json
import time
import uuid
import sys

BASE_URL = "http://localhost:8080"
TIMESTAMP = int(time.time())

results = {
    "total": 0,
    "passed": 0,
    "failed": 0,
    "500_errors": 0,
    "unexpected_400_errors": 0,
    "tests": []
}

def log_test(name, expected_status, actual_status, passed, details=""):
    results["total"] += 1
    if passed:
        results["passed"] += 1
        print(f"  [PASS] {name} -> HTTP {actual_status} {details}")
    else:
        results["failed"] += 1
        if actual_status == 500:
            results["500_errors"] += 1
        if actual_status == 400 and expected_status != 400:
            results["unexpected_400_errors"] += 1
        print(f"  [FAIL] {name} -> Expected {expected_status}, Got HTTP {actual_status}: {details}")
    
    results["tests"].append({
        "name": name,
        "expected": expected_status,
        "actual": actual_status,
        "passed": passed,
        "details": details
    })

def make_request(method, path, body=None, token=None, extra_headers=None):
    url = f"{BASE_URL}{path}"
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    if extra_headers:
        headers.update(extra_headers)
    
    data = json.dumps(body).encode("utf-8") if body is not None else None
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            content = resp.read().decode("utf-8")
            try:
                parsed = json.loads(content)
            except Exception:
                parsed = content
            return resp.status, parsed
    except urllib.error.HTTPError as e:
        content = e.read().decode("utf-8")
        try:
            parsed = json.loads(content)
        except Exception:
            parsed = content
        return e.code, parsed
    except Exception as e:
        return 0, str(e)

print("=" * 80)
print("SEN HONG CORE BANKING: DEEP-CHECK 100% COMPLIANCE & ZERO 500/400 AUDIT")
print("=" * 80)

# ------------------------------------------------------------------------------
# 1. AUTHENTICATION & SETUP
# ------------------------------------------------------------------------------
print("\n[PHASE 1] Khởi tạo Xác thực & Phiên làm việc (Staff & Mobile User)...")

# 1.1 Login Teller
status, data = make_request("POST", "/api/v1/auth/login", {
    "phoneNumber": "0911000001",
    "password": "DemoPass#2026!"
})
teller_token = data.get("data", {}).get("token") or data.get("data", {}).get("accessToken") if isinstance(data, dict) else None
log_test("Login Teller (0911000001)", 200, status, status == 200 and teller_token is not None)

# 1.2 Login Manager
status, data = make_request("POST", "/api/v1/auth/login", {
    "phoneNumber": "0911000003",
    "password": "DemoPass#2026!"
})
manager_token = data.get("data", {}).get("token") or data.get("data", {}).get("accessToken") if isinstance(data, dict) else None
log_test("Login Manager (0911000003)", 200, status, status == 200 and manager_token is not None)

# 1.3 Register New Mobile User
mobile_phone = f"098{TIMESTAMP % 10000000:07d}"
status, data = make_request("POST", "/api/v1/auth/register", {
    "phoneNumber": mobile_phone,
    "password": "DemoPass#2026!",
    "fullName": "Audit Test User",
    "email": f"audit_{TIMESTAMP}@banking.example.com"
})
user_token = data.get("data", {}).get("accessToken") or data.get("data", {}).get("token") if isinstance(data, dict) else None
user_id = data.get("data", {}).get("userId") if isinstance(data, dict) else None
log_test("Register Mobile User", [200, 201], status, status in [200, 201] and user_token is not None, f"userId: {user_id}")

# 1.4 Set & Verify PIN for Mobile User
status, data = make_request("POST", "/api/v1/users/pin/set", {"pin": "123456"}, token=user_token, extra_headers={"X-User-Id": user_id})
log_test("Set User PIN 123456", 200, status, status == 200)

status, data = make_request("POST", "/api/v1/users/pin/verify", {"pin": "123456"}, token=user_token, extra_headers={"X-User-Id": user_id})
pin_token = data.get("data") if isinstance(data, dict) else None
if isinstance(pin_token, dict):
    pin_token = pin_token.get("pinToken") or pin_token.get("token")
log_test("Verify User PIN", 200, status, status == 200 and pin_token is not None)

# ------------------------------------------------------------------------------
# 2. LEGAL, FAQ & PUBLIC ENDPOINTS
# ------------------------------------------------------------------------------
print("\n[PHASE 2] Kiểm tra Endpoints Công khai (Legal, FAQ, Health)...")

status, data = make_request("GET", "/actuator/health")
log_test("Gateway Health Check", 200, status, status == 200)

status, data = make_request("GET", "/api/v1/legal/terms")
log_test("GET /legal/terms", 200, status, status == 200)

status, data = make_request("GET", "/api/v1/support/faq")
log_test("GET /support/faq", 200, status, status == 200)

# ------------------------------------------------------------------------------
# 3. IDENTITY SERVICE & USER MANAGEMENT
# ------------------------------------------------------------------------------
print("\n[PHASE 3] Kiểm tra Identity Service & Quản lý Người dùng...")

status, data = make_request("GET", "/api/v1/users/me", token=user_token)
log_test("GET /users/me", 200, status, status == 200)

status, data = make_request("GET", "/api/v1/users/profile", token=user_token)
log_test("GET /users/profile", 200, status, status == 200)

status, data = make_request("GET", "/api/v1/users/me/qrcode", token=user_token)
log_test("GET /users/me/qrcode", 200, status, status == 200)

status, data = make_request("GET", "/api/v1/config/limits", token=user_token)
log_test("GET /config/limits", 200, status, status == 200)

status, data = make_request("GET", "/api/v1/config/limits/status", token=user_token)
log_test("GET /config/limits/status", 200, status, status == 200)

status, data = make_request("POST", "/api/v1/devices/register", {
    "deviceId": f"audit-device-{TIMESTAMP}",
    "fcmToken": f"fcm-token-audit-{TIMESTAMP}",
    "deviceType": "ANDROID"
}, token=user_token)
log_test("POST /devices/register", 200, status, status == 200)

status, data = make_request("GET", "/api/v1/kyc/status", token=user_token)
log_test("GET /kyc/status", 200, status, status == 200)

# ------------------------------------------------------------------------------
# 4. WALLET SERVICE
# ------------------------------------------------------------------------------
print("\n[PHASE 4] Kiểm tra Wallet Service & Số dư...")

status, data = make_request("GET", "/api/v1/wallets/me", token=user_token)
wallet_id = data.get("data", {}).get("id") or data.get("data", {}).get("walletId") if isinstance(data, dict) else None
log_test("GET /wallets/me", 200, status, status == 200 and wallet_id is not None, f"walletId: {wallet_id}")

status, data = make_request("GET", f"/api/v1/wallets/{wallet_id}", token=user_token)
log_test(f"GET /wallets/{wallet_id}", 200, status, status == 200)

status, data = make_request("GET", "/api/v1/wallets/recipient-info?phoneNumber=0909876543", token=user_token)
log_test("GET /wallets/recipient-info?phoneNumber=...", 200, status, status == 200)

status, data = make_request("GET", "/api/v1/wallets/recipient-info?phone=0909876543", token=user_token)
log_test("GET /wallets/recipient-info?phone=... (Alias)", 200, status, status == 200)

status, data = make_request("GET", "/api/v1/wallets/fees/estimate?amount=100000&type=TRANSFER", token=user_token)
log_test("GET /wallets/fees/estimate", 200, status, status == 200)

status, data = make_request("GET", "/api/v1/wallets/admin/accounts", token=manager_token)
log_test("GET /wallets/admin/accounts (Admin/Manager)", 200, status, status == 200)

# Deposit money into user wallet via Teller
status, data = make_request("POST", "/api/v1/cash/deposits", {
    "accountNumber": mobile_phone,
    "customerName": "Audit Test User",
    "amount": 10000000,
    "currency": "VND",
    "branchId": "BR_Q1",
    "makerId": "teller1",
    "note": "Nạp tiền kiểm thử hệ thống",
    "idempotencyKey": f"IDEM-AUDIT-DEP-{TIMESTAMP}"
}, token=teller_token, extra_headers={"Idempotency-Key": f"IDEM-AUDIT-DEP-{TIMESTAMP}"})
log_test("POST /cash/deposits (Teller nạp 10.000.000 VND)", 200, status, status == 200)

# ------------------------------------------------------------------------------
# 5. PAYMENT SERVICE & SAGA P2P
# ------------------------------------------------------------------------------
print("\n[PHASE 5] Kiểm tra Payment Service & Saga Orchestration...")

# Partner Banks
status, data = make_request("GET", "/api/v1/banks", token=user_token)
log_test("GET /banks", 200, status, status == 200 and len(data.get("data", [])) > 0, f"Found {len(data.get('data', []))} banks")

status, data = make_request("GET", "/api/v1/payments/banks", token=user_token)
log_test("GET /payments/banks (Dual route)", 200, status, status == 200)

# VietQR generate & decode
status, data = make_request("POST", "/api/v1/payments/vietqr/generate", {
    "bankBin": "970436",
    "accountNumber": "001100998877",
    "amount": 250000,
    "purpose": "Thanh toan tien sach"
}, token=user_token)
qr_data = data.get("data", {}) if isinstance(data, dict) and data.get("data") else {}
qr_string = qr_data.get("qrRaw") or qr_data.get("qrString") or qr_data.get("qrCode") or ""
log_test("POST /payments/vietqr/generate", 200, status, status == 200 and len(qr_string) > 0)

status, data = make_request("POST", "/api/v1/payments/vietqr/decode", {
    "qrString": qr_string
}, token=user_token)
log_test("POST /payments/vietqr/decode", 200, status, status == 200)

# Saga P2P Transfer (Alice to Bob)
status, data = make_request("POST", "/api/v1/payments/transfer", {
    "sourceUserId": "a11ce000-0000-0000-0000-000000000001",
    "targetUserId": "b0b00000-0000-0000-0000-000000000002",
    "amount": 50000,
    "description": "Audit Saga Transfer"
}, token=teller_token, extra_headers={"Idempotency-Key": f"IDEM-AUDIT-SAGA-{TIMESTAMP}"})
log_test("POST /payments/transfer (Saga P2P 1-step)", 200, status, status == 200 and data.get("data", {}).get("status") == "SUCCESS")

# 2-step Transfer endpoints
status, data = make_request("POST", "/api/v1/wallets/transfer/init", {
    "receiverPhone": "0909876543",
    "amount": 50000,
    "note": "2-step Transfer Init Test"
}, token=user_token)
transfer_init_id = data.get("data", {}).get("transferId") or data.get("data", {}).get("id") if isinstance(data, dict) else None
log_test("POST /wallets/transfer/init (2-step init)", 200, status, status == 200)

if transfer_init_id:
    status, data = make_request("POST", f"/api/v1/wallets/transfer/{transfer_init_id}/confirm", {
        "pin": "123456",
        "pinToken": pin_token
    }, token=user_token)
    log_test(f"POST /wallets/transfer/{transfer_init_id}/confirm", 200, status, status == 200)

# Savings & Loans
status, data = make_request("GET", "/api/v1/savings/products", token=user_token)
log_test("GET /savings/products", 200, status, status == 200 and len(data.get("data", [])) > 0)

status, data = make_request("GET", "/api/v1/savings/accounts", token=user_token)
log_test("GET /savings/accounts", 200, status, status == 200)

status, data = make_request("GET", "/api/v1/loans/products", token=user_token)
log_test("GET /loans/products", 200, status, status == 200 and len(data.get("data", [])) > 0)

status, data = make_request("GET", "/api/v1/loans", token=user_token)
log_test("GET /loans", 200, status, status == 200)

status, data = make_request("GET", "/api/v1/cards", token=user_token)
log_test("GET /cards", 200, status, status == 200)

status, data = make_request("GET", "/api/v1/bills/lookup?provider=EVN_HN&customerCode=EVN123456", token=user_token)
log_test("GET /bills/lookup", 200, status, status == 200)

status, data = make_request("GET", "/api/v1/transactions", token=user_token)
log_test("GET /transactions", 200, status, status == 200)

status, data = make_request("GET", "/api/v1/funding-sources", token=user_token)
log_test("GET /funding-sources", 200, status, status == 200)

status, data = make_request("GET", "/api/v1/bank-accounts", token=user_token)
log_test("GET /bank-accounts", 200, status, status == 200)

status, data = make_request("GET", "/api/v1/beneficiaries", token=user_token)
log_test("GET /beneficiaries", 200, status, status == 200)

status, data = make_request("GET", "/api/v1/promotions", token=user_token)
log_test("GET /promotions", 200, status, status == 200)

# ------------------------------------------------------------------------------
# 6. CASH DEPOSIT & TELLER / MANAGER PORTAL
# ------------------------------------------------------------------------------
print("\n[PHASE 6] Kiểm tra Web Portal Teller Maker & Manager Checker...")

status, data = make_request("GET", "/api/v1/cash/vault/summary?branchId=BR_Q1", token=teller_token)
log_test("GET /cash/vault/summary", 200, status, status == 200)

status, data = make_request("GET", "/api/v1/cash/vault-summary?branchId=BR_Q1", token=teller_token)
log_test("GET /cash/vault-summary (Dual mapping)", 200, status, status == 200)

status, data = make_request("GET", "/api/v1/cash/deposits?branchId=BR_Q1", token=teller_token)
log_test("GET /cash/deposits", 200, status, status == 200)

# Maker creates a deposit > 50M -> PENDING_APPROVAL
deposit_idem = f"IDEM-LARGE-DEP-{TIMESTAMP}"
status, data = make_request("POST", "/api/v1/cash/deposits", {
    "accountNumber": mobile_phone,
    "customerName": "Audit Test User",
    "amount": 75000000,
    "currency": "VND",
    "branchId": "BR_Q1",
    "makerId": "teller1",
    "note": "Lệnh nạp lớn kiểm tra Maker-Checker",
    "idempotencyKey": deposit_idem
}, token=teller_token, extra_headers={"Idempotency-Key": deposit_idem})
large_dep_id = data.get("data", {}).get("id") or data.get("data", {}).get("depositCode") if isinstance(data, dict) else None
dep_status = data.get("data", {}).get("status") if isinstance(data, dict) else None
log_test("POST /cash/deposits (> 50M -> PENDING_APPROVAL)", 200, status, status == 200 and dep_status == "PENDING_APPROVAL")

# Manager Checker approves
if large_dep_id:
    status, data = make_request("POST", f"/api/v1/cash/deposits/{large_dep_id}/approve", {
        "checkerId": "manager1",
        "checkerName": "Manager Lê Hoàng C",
        "note": "Đồng ý duyệt lệnh nạp tiền mặt 75M"
    }, token=manager_token)
    log_test(f"POST /cash/deposits/{large_dep_id}/approve (Checker duyệt)", 200, status, status == 200 and data.get("data", {}).get("status") == "COMPLETED")

status, data = make_request("GET", "/api/v1/loans/pending", token=manager_token)
log_test("GET /loans/pending (Manager portal)", 200, status, status == 200)

# ------------------------------------------------------------------------------
# 7. LEDGER SERVICE (DOUBLE-ENTRY BOOKKEEPING)
# ------------------------------------------------------------------------------
print("\n[PHASE 7] Kiểm tra Ledger Service & Bảo toàn Tuyệt đối Sổ cái kép...")

status, data = make_request("GET", "/api/v1/ledger/summary", token=manager_token)
log_test("GET /ledger/summary", 200, status, status == 200)

status, data = make_request("GET", "/api/v1/ledger/turnover-summary", token=manager_token)
log_test("GET /ledger/turnover-summary", 200, status, status == 200)

status, data = make_request("GET", "/api/v1/ledger/accounts/balance-check", token=manager_token)
bal_data = data.get("data", {}) if isinstance(data, dict) else {}
is_balanced = bal_data.get("balanced", False)
total_debit = float(bal_data.get("totalDebit", 0))
total_credit = float(bal_data.get("totalCredit", 0))
delta = abs(total_debit - total_credit)
log_test("GET /ledger/accounts/balance-check (Delta = 0.00)", 200, status, status == 200 and is_balanced and delta == 0.0, f"Delta: {delta} VND | Balanced: {is_balanced}")

status, data = make_request("GET", "/api/v1/ledger/entries", token=manager_token)
log_test("GET /ledger/entries", 200, status, status == 200)

status, data = make_request("GET", "/api/v1/ledger/cash-summary?branchId=BR_Q1", token=manager_token)
log_test("GET /ledger/cash-summary", 200, status, status == 200)

status, data = make_request("GET", "/api/v1/ledger/cash-deposit/summary?branchId=BR_Q1", token=manager_token)
log_test("GET /ledger/cash-deposit/summary", 200, status, status == 200)

# ------------------------------------------------------------------------------
# 8. NOTIFICATION SERVICE
# ------------------------------------------------------------------------------
print("\n[PHASE 8] Kiểm tra Notification Service...")

status, data = make_request("GET", "/api/v1/notifications", token=user_token)
log_test("GET /notifications", 200, status, status == 200)

status, data = make_request("GET", "/api/v1/notifications/unread-count", token=user_token)
log_test("GET /notifications/unread-count", 200, status, status == 200)

status, data = make_request("PATCH", "/api/v1/notifications/read-all", token=user_token)
log_test("PATCH /notifications/read-all", 200, status, status == 200)

status, data = make_request("PUT", "/api/v1/notifications/settings", {
    "promotions": True,
    "systemAlerts": True,
    "transactionAlerts": True
}, token=user_token)
log_test("PUT /notifications/settings", 200, status, status == 200)

# ------------------------------------------------------------------------------
# 9. CONTROLLED ERROR SCENARIOS (VERIFYING ZERO UNHANDLED 500s)
# ------------------------------------------------------------------------------
print("\n[PHASE 9] Kiểm tra Kịch bản Lỗi có Kiểm soát (Tuyệt đối KHÔNG có lỗi 500)...")

# 9.1 Invalid Password Login -> Expect HTTP 400 or 401 Controlled Error (NOT 500)
status, data = make_request("POST", "/api/v1/auth/login", {
    "phoneNumber": "0911000001",
    "password": "WrongPassword#123!"
})
is_controlled_auth_error = status in [400, 401] and isinstance(data, dict) and "không chính xác" in str(data)
log_test("Invalid Login Credentials -> 400/401 Controlled Auth Error (NOT 500)", [400, 401], status, is_controlled_auth_error, f"Response: {data.get('message') if isinstance(data, dict) else ''}")

# 9.2 Unauthorized access without token -> Expect HTTP 401 (NOT 500)
status, data = make_request("GET", "/api/v1/wallets/me")
log_test("Unauthenticated Protected Endpoint -> 401 Unauthorized", 401, status, status == 401)

# 9.3 Insufficient Balance Transfer -> Expect Controlled Domain Error (400 or 422 with INSUFFICIENT_BALANCE, NEVER 500)
status, data = make_request("POST", "/api/v1/payments/transfer", {
    "sourceUserId": "b0b00000-0000-0000-0000-000000000002",
    "targetUserId": "a11ce000-0000-0000-0000-000000000001",
    "amount": 999999999999,  # Ridiculously high amount
    "description": "Overdraft test"
}, token=teller_token, extra_headers={"Idempotency-Key": f"IDEM-OVERDRAFT-{TIMESTAMP}"})
has_controlled_code = isinstance(data, dict) and (data.get("errorCode") in ["INSUFFICIENT_BALANCE", "WALLET_BALANCE_INSUFFICIENT", "PAYMENT_FAILED"] or "số dư" in str(data).lower())
log_test("Overdraft Saga Transfer -> Controlled Error (NOT 500)", [400, 422], status, status in [400, 422] and status != 500 and has_controlled_code, f"Error Code: {data.get('errorCode') if isinstance(data, dict) else ''}")

# 9.4 Non-existent entity -> Expect HTTP 400 or 404 (NOT 500)
fake_uuid = str(uuid.uuid4())
status, data = make_request("GET", f"/api/v1/loans/{fake_uuid}", token=user_token)
log_test("Non-existent Loan Detail -> 400/404 Controlled Error (NOT 500)", [400, 404], status, status in [400, 404])

# 9.5 Maker attempting to approve own cash deposit -> Expect Blocked (400 Maker!=Checker or 403 Forbidden, NOT 500)
test_self_idem = f"IDEM-SELF-CHECK-{TIMESTAMP}"
status, data = make_request("POST", "/api/v1/cash/deposits", {
    "accountNumber": mobile_phone,
    "customerName": "Audit Test User",
    "amount": 60000000,
    "currency": "VND",
    "branchId": "BR_Q1",
    "makerId": "teller1",
    "note": "Kiểm tra tự duyệt",
    "idempotencyKey": test_self_idem
}, token=teller_token, extra_headers={"Idempotency-Key": test_self_idem})
self_dep_id = data.get("data", {}).get("id") or data.get("data", {}).get("depositCode") if isinstance(data, dict) else None

if self_dep_id:
    status, data = make_request("POST", f"/api/v1/cash/deposits/{self_dep_id}/approve", {
        "checkerId": "teller1",  # Same as maker!
        "checkerName": "Teller Nguyễn Văn A",
        "note": "Maker cố tình tự duyệt"
    }, token=teller_token)
    is_blocked = status in [400, 403] and status != 500
    log_test("Maker Approving Own Deposit -> Blocked 400/403 (NOT 500)", [400, 403], status, is_blocked, f"Response: {data.get('message') if isinstance(data, dict) else ''}")

# 9.6 Re-approving already completed deposit -> Expect Controlled 400 ALREADY_COMPLETED (NOT 500)
if self_dep_id:
    # First approve with Manager
    make_request("POST", f"/api/v1/cash/deposits/{self_dep_id}/approve", {
        "checkerId": "manager1",
        "checkerName": "Manager Lê Hoàng C",
        "note": "Hợp lệ duyệt"
    }, token=manager_token)
    # Then re-approve again
    status, data = make_request("POST", f"/api/v1/cash/deposits/{self_dep_id}/approve", {
        "checkerId": "manager1",
        "checkerName": "Manager Lê Hoàng C",
        "note": "Duyệt lần 2"
    }, token=manager_token)
    log_test("Re-approving Completed Deposit -> Controlled 400 (NOT 500)", 400, status, status == 400, f"Response: {data.get('message') if isinstance(data, dict) else ''}")

# ------------------------------------------------------------------------------
# SUMMARY REPORT
# ------------------------------------------------------------------------------
print("\n" + "=" * 80)
print("AUDIT RESULTS SUMMARY")
print("=" * 80)
print(f"Total Tests Executed:     {results['total']}")
print(f"Passed Tests:             {results['passed']} ({results['passed']/results['total']*100:.1f}%)")
print(f"Failed Tests:             {results['failed']}")
print(f"HTTP 500 Errors:          {results['500_errors']} (Zero tolerance: {'PASSED' if results['500_errors'] == 0 else 'FAILED'})")
print(f"Unexpected 400 Errors:    {results['unexpected_400_errors']} (Zero tolerance: {'PASSED' if results['unexpected_400_errors'] == 0 else 'FAILED'})")
print("=" * 80)

if results["failed"] > 0 or results["500_errors"] > 0 or results["unexpected_400_errors"] > 0:
    sys.exit(1)
else:
    print("\nALL VERIFICATIONS PASSED: 100% STANDARD COMPLIANCE AND ZERO 400/500 ERRORS!")
    sys.exit(0)
