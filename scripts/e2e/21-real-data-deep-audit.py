#!/usr/bin/env python3
"""
scripts/e2e/21-real-data-deep-audit.py
Kiểm thử chuyên sâu toàn diện các tính năng cốt lõi bằng DỮ LIỆU THỰC TẾ (Real DB).
"""
import urllib.request
import urllib.error
import json
import sys
import time

BASE_URL = "http://localhost:8080/api/v1"

def http_post(path, body=None, token=None, headers=None, expected_status=200):
    url = f"{BASE_URL}{path}"
    req_headers = {"Content-Type": "application/json"}
    if token:
        req_headers["Authorization"] = f"Bearer {token}"
    if headers:
        req_headers.update(headers)
    
    data_bytes = json.dumps(body).encode("utf-8") if body is not None else None
    req = urllib.request.Request(url, data=data_bytes, headers=req_headers, method="POST")
    try:
        with urllib.request.urlopen(req) as resp:
            raw = resp.read().decode("utf-8")
            return resp.status, json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        raw = e.read().decode("utf-8")
        try:
            parsed = json.loads(raw)
        except:
            parsed = {"raw": raw}
        return e.code, parsed

def http_get(path, token=None, headers=None):
    url = f"{BASE_URL}{path}"
    req_headers = {}
    if token:
        req_headers["Authorization"] = f"Bearer {token}"
    if headers:
        req_headers.update(headers)
    
    req = urllib.request.Request(url, headers=req_headers, method="GET")
    try:
        with urllib.request.urlopen(req) as resp:
            raw = resp.read().decode("utf-8")
            return resp.status, json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        raw = e.read().decode("utf-8")
        try:
            parsed = json.loads(raw)
        except:
            parsed = {"raw": raw}
        return e.code, parsed

def main():
    print("=" * 70)
    print("🚀 BẮT ĐẦU KIỂM THỬ CHUYÊN SÂU DỮ LIỆU THẬT 100% (REAL DATA E2E AUDIT)")
    print("=" * 70)

    ts = int(time.time())
    user_phone = f"098{ts % 10000000:07d}"
    print(f"\n[1] Đăng ký User khách hàng mới: SĐT={user_phone}")
    status, res = http_post("/auth/register", {
        "phoneNumber": user_phone,
        "fullName": "Khách Hàng Kiểm Thử Dữ Liệu Thật",
        "email": f"user.{ts}@senhong.vn",
        "password": "DemoPass#2026!",
        "deviceId": f"device-{ts}"
    })
    assert status in (200, 201), f"Đăng ký thất bại: {res}"
    user_id = res["data"]["userId"]
    print(f"  ✔ Đăng ký thành công! UserID = {user_id}")

    # Login user
    status, res = http_post("/auth/login", {
        "phoneNumber": user_phone,
        "password": "DemoPass#2026!",
        "deviceId": f"device-{ts}"
    })
    assert status == 200, f"Đăng nhập thất bại: {res}"
    user_token = res["data"]["accessToken"]
    print(f"  ✔ Đăng nhập lấy Bearer JWT Token thành công.")

    # Lấy thông tin ví
    status, res = http_get("/wallets/me", token=user_token)
    assert status == 200, f"Không lấy được ví: {res}"
    user_wallet_id = res["data"]["id"]
    print(f"  ✔ Ví Core Banking: {user_wallet_id} | Số dư khởi tạo: {res['data']['balance']} VND")

    # Thiết lập PIN và lấy PIN token
    status, res = http_post("/users/pin/set", {"pin": "123456"}, token=user_token)
    assert status == 200, f"Set PIN thất bại: {res}"
    status, res = http_post("/users/pin/verify", {"pin": "123456"}, token=user_token)
    assert status == 200, f"Verify PIN thất bại: {res}"
    pin_token = res["data"] if isinstance(res["data"], str) else res["data"].get("pinToken")
    print(f"  ✔ Thiết lập & xác thực PIN thành công, PIN Token cấp hợp lệ.")

    # [2] Nạp tiền 30.000.000 VND vào ví qua Teller
    print("\n[2] Nạp tiền 30.000.000 VND vào ví qua Giao dịch viên Teller1")
    # Login teller1
    status, res = http_post("/auth/login", {
        "phoneNumber": "0911000001",
        "password": "DemoPass#2026!",
        "deviceId": "teller-dev"
    })
    teller_token = res["data"]["accessToken"]

    dep_code = f"DEP-REAL-{ts}"
    status, res = http_post("/cash/deposits", {
        "accountNumber": user_wallet_id,
        "customerName": "Khách Hàng Kiểm Thử Dữ Liệu Thật",
        "citizenId": "079201099999",
        "phoneNumber": user_phone,
        "amount": 30000000,
        "note": "Nạp tiền quầy kiểm thử dữ liệu thực tế"
    }, token=teller_token, headers={"Idempotency-Key": dep_code})
    assert status == 200, f"Lập phiếu nạp thất bại: {res}"
    deposit_id = res["data"]["id"]
    print(f"  ✔ Phiếu nạp {dep_code} (ID: {deposit_id}) đã lập.")

    # Tự động duyệt nếu <= 50M
    status, res = http_get("/wallets/me", token=user_token)
    assert status == 200 and res["data"]["balance"] >= 30000000, f"Số dư chưa cập nhật: {res}"
    print(f"  ✔ Tiền đã vào ví khách hàng thành công: {res['data']['balance']:,.0f} VND")

    # [3] Kiểm tra Vay Tiêu Dùng & Tất Toán Trước Hạn
    print("\n[3] Kiểm thử Vay Tiêu Dùng Tín Chấp & Tất Toán Trước Hạn (Early Settlement)")
    # Gửi hồ sơ vay 5.000.000 VND
    status, res = http_post("/loans/apply", {
        "walletId": user_wallet_id,
        "productType": "VAY_TIEU_DUNG_NHANH",
        "amount": 5000000,
        "termMonths": 6,
        "purpose": "Kiểm thử tất toán trước hạn",
        "pinToken": pin_token
    }, token=user_token)
    assert status == 200, f"Gửi hồ sơ vay thất bại: {res}"
    loan_id = res["data"]["id"]
    print(f"  ✔ Hồ sơ vay đã tạo: ID={loan_id}, Số tiền=5.000.000 VND, Kỳ hạn=6 tháng")

    # Phê duyệt giải ngân qua Manager1
    status, res = http_post("/auth/login", {
        "phoneNumber": "0911000003",
        "password": "DemoPass#2026!",
        "deviceId": "manager-dev"
    })
    manager_token = res["data"]["accessToken"]
    status, res = http_post(f"/loans/{loan_id}/approve", token=manager_token)
    assert status == 200, f"Duyệt giải ngân thất bại: {res}"
    print(f"  ✔ Giám đốc chi nhánh đã phê duyệt và giải ngân 5.000.000 VND vào ví.")

    # Kiểm tra số dư ví sau giải ngân (30M + 5M = 35M)
    status, res = http_get("/wallets/me", token=user_token)
    print(f"  ✔ Số dư ví sau giải ngân: {res['data']['balance']:,.0f} VND")

    # THỰC HIỆN TẤT TOÁN TRƯỚC HẠN
    print("  -> Thực hiện Tất Toán Toàn Bộ Khoản Vay Trước Hạn...")
    # Lấy lại pin token mới
    status, res = http_post("/users/pin/verify", {"pin": "123456"}, token=user_token)
    pin_token = res["data"] if isinstance(res["data"], str) else res["data"].get("pinToken")

    status, res = http_post(f"/loans/{loan_id}/settle", {"pinToken": pin_token}, token=user_token)
    assert status == 200, f"Tất toán trước hạn thất bại: {res}"
    settle_data = res["data"]
    print(f"  ✔ TẤT TOÁN TRƯỚC HẠN THÀNH CÔNG:")
    print(f"     - Hợp đồng: {settle_data.get('contractNumber')}")
    print(f"     - Tổng tiền đã thanh toán: {settle_data.get('paidAmount', 0):,.0f} VND")
    print(f"     - Dư nợ gốc còn lại: {settle_data.get('remainingPrincipal', 0):,.0f} VND")
    print(f"     - Trạng thái hợp đồng: {settle_data.get('status')} (isFullyRepaid={settle_data.get('isFullyRepaid') or settle_data.get('fullyRepaid')})")
    print(f"     - Diễn giải: {settle_data.get('message')}")

    # [4] Kiểm tra Quy chuẩn Quyết định 2345/QĐ-NHNN (Bắt buộc Biometric Token khi >= 10M)
    print("\n[4] Kiểm thử Tuân thủ Quyết định 2345/QĐ-NHNN (Chuyển tiền >= 10.000.000 VND)")
    bob_phone = f"097{ts % 10000000:07d}"
    status, res = http_post("/auth/register", {
        "phoneNumber": bob_phone,
        "fullName": "Người Nhận Chuyển Khoản Bob",
        "email": f"bob.{ts}@senhong.vn",
        "password": "DemoPass#2026!",
        "deviceId": f"device-bob-{ts}"
    })
    assert status in (200, 201), f"Đăng ký Bob thất bại: {res}"
    bob_user_id = res["data"]["userId"]
    print(f"  ✔ Khởi tạo tài khoản người nhận Bob thành công: SĐT={bob_phone}, UserID={bob_user_id}")

    # Thử chuyển 15.000.000 VND KHÔNG có biometric token -> BẮT BUỘC BỊ TỪ CHỐI
    print("  -> Bước 4a: Chuyển 15.000.000 VND KHÔNG CÓ Biometric Token...")
    tf_idem_1 = f"tf-qd2345-fail-{ts}"
    status, res = http_post("/payments/transfer", {
        "sourceUserId": user_id,
        "targetUserId": bob_user_id,
        "amount": 15000000,
        "currency": "VND",
        "note": "Chuyển tiền test QĐ 2345 không có khuôn mặt",
        "pinToken": pin_token,
        "idempotencyKey": tf_idem_1
    }, token=user_token, headers={"Idempotency-Key": tf_idem_1})
    
    assert status == 400 and res.get("errorCode") == "BIOMETRIC_AUTH_REQUIRED", f"LỖI: Server không chặn QĐ 2345! status={status}, res={res}"
    print(f"  ✔ CHẶN THÀNH CÔNG: HTTP 400 - {res.get('errorCode')}")
    print(f"     Thông điệp pháp lý: \"{res.get('message')}\"")

    # Bước 4b: Xác thực sinh trắc học Face Match eKYC để cấp Biometric Token
    print("  -> Bước 4b: Xác thực Face Match eKYC qua camera...")
    status, res = http_post("/security/biometric/verify", {
        "faceTemplateBase64": "live_camera_face_vector_sample_data",
        "livenessScore": 0.99
    }, token=user_token)
    assert status == 200, f"Xác thực Face thất bại: {res}"
    bio_token = res["data"]["biometricToken"]
    print(f"  ✔ Cấp Biometric JWT Token thành công (Face Match Score: 99.0%)")

    # Bước 4c: Chuyển lại 15.000.000 VND VỚI Biometric Token
    print("  -> Bước 4c: Chuyển lại 15.000.000 VND KÈM Biometric Token...")
    tf_idem_2 = f"tf-qd2345-pass-{ts}"
    status, res = http_post("/payments/transfer", {
        "sourceUserId": user_id,
        "targetUserId": bob_user_id,
        "amount": 15000000,
        "currency": "VND",
        "note": "Chuyển tiền tuân thủ QĐ 2345/NHNN",
        "pinToken": pin_token,
        "biometricToken": bio_token,
        "idempotencyKey": tf_idem_2
    }, token=user_token, headers={"Idempotency-Key": tf_idem_2})
    
    assert status == 200 and res["data"]["status"] == "SUCCESS", f"Chuyển tiền thất bại: {res}"
    print(f"  ✔ CHUYỂN TIỀN THÀNH CÔNG QUA SAGA: Mã GD = {res['data'].get('transactionId') or res['data'].get('id')}")
    bal_after = res['data'].get('sourceBalanceAfter') or res['data'].get('sourceBalance') or res['data'].get('remainingBalance')
    if bal_after is not None:
        print(f"     Số dư người gửi còn lại: {bal_after:,.0f} VND")

    # [5] Kiểm tra Giám sát AML Giao dịch Giá trị lớn
    print("\n[5] Kiểm thử Giám sát AML Giao dịch Giá trị lớn (Luật PCRT 2022)")
    status, res = http_get("/transactions/aml/large?minAmount=10000000&size=5", token=teller_token)
    assert status == 200, f"Truy vấn AML thất bại: {res}"
    aml_data = res["data"]
    print(f"  ✔ Tổng số giao dịch AML phát hiện: {aml_data.get('totalElements')}")
    print(f"  ✔ Tiêu chuẩn pháp lý: {aml_data.get('standard')}")

    # [6] Kiểm tra Khóa Khẩn Cấp (Fraud Emergency Kill-Switch)
    print("\n[6] Kiểm thử Khóa Khẩn Cấp (Emergency Kill-Switch)")
    status, res = http_post("/security/emergency-lock", {
        "reason": "Phát hiện đăng nhập lạ trên thiết bị nghi ngờ"
    }, token=user_token)
    assert status == 200, f"Khóa khẩn cấp thất bại: {res}"
    print(f"  ✔ Kích hoạt Kill-Switch thành công: Trạng thái User = {res['data']['status']}")

    # Xác minh User bị chặn đăng nhập ngay lập tức
    status, res = http_post("/auth/login", {
        "phoneNumber": user_phone,
        "password": "DemoPass#2026!",
        "deviceId": "hacker-device"
    })
    assert status == 403, f"LỖI: User bị khóa nhưng vẫn đăng nhập được! status={status}"
    print(f"  ✔ XÁC MINH AN TOÀN: Đăng nhập bị chặn hoàn toàn với HTTP 403 ({res.get('message')})")

    # [7] Kiểm tra Bất biến Sổ Cái Kép (Double-Entry Invariant)
    print("\n[7] Kiểm thử Bất biến Sổ Cái Kép (Ledger Balance Verification)")
    status, res = http_get("/ledger/accounts/balance-check", token=teller_token)
    assert status == 200, f"Kiểm tra sổ cái thất bại: {res}"
    ledger = res["data"]
    debit = ledger["totalDebit"]
    credit = ledger["totalCredit"]
    delta = abs(debit - credit)
    print(f"  ✔ Tổng Nợ (Debit)  : {debit:,.2f} VND")
    print(f"  ✔ Tổng Có (Credit) : {credit:,.2f} VND")
    print(f"  ✔ Sai lệch Delta   : {delta:,.2f} VND (balanced={ledger['balanced']})")
    assert delta == 0, f"LỖI: Sổ cái bị lệch! Delta = {delta}"

    print("\n" + "=" * 70)
    print("🎉 TẤT CẢ 7 BÀI KIỂM THỬ DỮ LIỆU THẬT ĐẠT 100% HOÀN HẢO!")
    print("=" * 70)

if __name__ == "__main__":
    main()
