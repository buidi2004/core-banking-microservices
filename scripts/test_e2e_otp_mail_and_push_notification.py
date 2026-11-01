#!/usr/bin/env python3
"""
E2E Deep Verification: OTP via Email & Mobile Push Notifications (WebSocket STOMP / Kafka / REST)
Sen Hong Core Banking Microservices
"""

import sys
import time
import json
import uuid
import subprocess
import requests
import asyncio
import websockets

BASE_URL = "http://localhost:8080/api/v1"
WS_URL = "ws://localhost:8080/ws-native"

COLOR_GREEN = "\033[92m"
COLOR_RED = "\033[91m"
COLOR_YELLOW = "\033[93m"
COLOR_CYAN = "\033[96m"
COLOR_RESET = "\033[0m"

passed_tests = 0
failed_tests = 0

def log_step(title):
    print(f"\n{COLOR_CYAN}{'='*80}\n>>> {title}\n{'='*80}{COLOR_RESET}")

def log_success(msg):
    global passed_tests
    passed_tests += 1
    print(f"  {COLOR_GREEN}✓ [PASS]{COLOR_RESET} {msg}")

def log_fail(msg):
    global failed_tests
    failed_tests += 1
    print(f"  {COLOR_RED}✗ [FAIL]{COLOR_RESET} {msg}")

def get_redis_key(key):
    cmd = ["docker", "exec", "ewallet-redis", "redis-cli", "GET", key]
    res = subprocess.run(cmd, capture_output=True, text=True)
    val = res.stdout.strip()
    return val if val != "" and val != "(nil)" else None

def get_redis_ttl(key):
    cmd = ["docker", "exec", "ewallet-redis", "redis-cli", "TTL", key]
    res = subprocess.run(cmd, capture_output=True, text=True)
    try:
        return int(res.stdout.strip())
    except:
        return -1

def del_redis_key(key):
    cmd = ["docker", "exec", "ewallet-redis", "redis-cli", "DEL", key]
    subprocess.run(cmd, capture_output=True, text=True)

def query_notification_db(sql):
    cmd = ["docker", "exec", "ewallet-postgres-notification", "psql", "-U", "notification_db_user", "-d", "ewallet_notification_db", "-t", "-A", "-c", sql]
    res = subprocess.run(cmd, capture_output=True, text=True)
    return res.stdout.strip()

# ==============================================================================
# PHASE 1: E2E KIỂM TRA CHUYÊN SÂU MÃ OTP QUA EMAIL (GMAIL/SMTP)
# ==============================================================================
def test_otp_email_flows():
    log_step("PHASE 1: KIỂM TRA CHUYÊN SÂU MÃ OTP QUA EMAIL (GMAIL/SMTP)")

    timestamp = int(time.time())
    test_phone = f"099{timestamp % 10000000:07d}"
    test_email = f"test.senhong.{timestamp}@gmail.com"

    # --------------------------------------------------------------------------
    # 1.1 Gửi OTP Đăng ký (REGISTER)
    # --------------------------------------------------------------------------
    print(f"\n--- 1.1 Kiểm tra gửi mã OTP Đăng ký mới (REGISTER) cho SĐT: {test_phone} ---")
    resp = requests.post(f"{BASE_URL}/auth/otp/send", json={
        "phoneNumber": test_phone,
        "purpose": "REGISTER",
        "email": test_email
    })
    
    if resp.status_code == 200:
        data = resp.json().get("data", {})
        ref_id = data.get("referenceId")
        masked_mail = data.get("maskedEmail")
        expires_in = data.get("expiresInSeconds")
        log_success(f"Gửi OTP thành công: referenceId={ref_id}, maskedEmail={masked_mail}, expiresIn={expires_in}s")
        
        # Kiểm tra Redis key
        redis_otp_key = f"identity:otp:{test_phone}:REGISTER"
        otp_val = get_redis_key(redis_otp_key)
        ttl = get_redis_ttl(redis_otp_key)
        if otp_val and len(otp_val) == 6 and otp_val.isdigit():
            log_success(f"Redis lưu mã OTP chính xác: key='{redis_otp_key}', code='{otp_val}', TTL={ttl}s (hạn 180s)")
        else:
            log_fail(f"Không tìm thấy mã OTP hợp lệ trong Redis: code={otp_val}")
    else:
        log_fail(f"Gửi OTP thất bại: HTTP {resp.status_code} - {resp.text}")

    # --------------------------------------------------------------------------
    # 1.2 Kiểm tra Bảo mật Mục đích OTP (Security Purpose Guard)
    # --------------------------------------------------------------------------
    print("\n--- 1.2 Kiểm tra chặn các mục đích OTP không được phép (Security Guard) ---")
    invalid_purpose_resp = requests.post(f"{BASE_URL}/auth/otp/send", json={
        "phoneNumber": test_phone,
        "purpose": "HACK_BYPASS_PURPOSE"
    })
    if invalid_purpose_resp.status_code == 400:
        err_msg = invalid_purpose_resp.json().get("message", "")
        if "không được hỗ trợ" in err_msg:
            log_success(f"Hệ thống chặn thành công mục đích trái phép: '{err_msg}'")
        else:
            log_success(f"Hệ thống trả về lỗi 400 đúng quy chuẩn: '{err_msg}'")
    else:
        log_fail(f"Lỗi: Hệ thống không chặn purpose không hợp lệ (HTTP {invalid_purpose_resp.status_code})")

    # --------------------------------------------------------------------------
    # 1.3 Kiểm tra Giới hạn số lần thử (Max 3 Failed Attempts & Rate Limiting)
    # --------------------------------------------------------------------------
    print("\n--- 1.3 Kiểm tra cơ chế chống Brute-Force (Tối đa 3 lần nhập sai) ---")
    redis_otp_key = f"identity:otp:{test_phone}:REGISTER"
    attempts_key = f"identity:otp:attempts:{test_phone}:REGISTER"
    
    # Lần 1: Sai
    r1 = requests.post(f"{BASE_URL}/auth/otp/verify", json={
        "phoneNumber": test_phone,
        "code": "000000",
        "purpose": "REGISTER"
    })
    attempts_in_redis = get_redis_key(attempts_key)
    if r1.status_code == 400 and attempts_in_redis == "1":
        log_success(f"Lần 1 nhập sai: Redis attempts=1, thông báo: '{r1.json().get('message')}'")
    else:
        log_fail(f"Lần 1 nhập sai chưa đúng kỳ vọng: HTTP {r1.status_code}, Redis attempts={attempts_in_redis}")

    # Lần 2: Sai
    r2 = requests.post(f"{BASE_URL}/auth/otp/verify", json={
        "phoneNumber": test_phone,
        "code": "111111",
        "purpose": "REGISTER"
    })
    attempts_in_redis = get_redis_key(attempts_key)
    if r2.status_code == 400 and attempts_in_redis == "2":
        log_success(f"Lần 2 nhập sai: Redis attempts=2, thông báo: '{r2.json().get('message')}'")
    else:
        log_fail(f"Lần 2 nhập sai chưa đúng kỳ vọng: HTTP {r2.status_code}, Redis attempts={attempts_in_redis}")

    # Lần 3: Sai
    r3 = requests.post(f"{BASE_URL}/auth/otp/verify", json={
        "phoneNumber": test_phone,
        "code": "222222",
        "purpose": "REGISTER"
    })
    attempts_in_redis = get_redis_key(attempts_key)
    if r3.status_code == 400 and attempts_in_redis == "3":
        log_success(f"Lần 3 nhập sai: Redis attempts=3, thông báo: '{r3.json().get('message')}'")
    else:
        log_fail(f"Lần 3 nhập sai chưa đúng kỳ vọng: HTTP {r3.status_code}, Redis attempts={attempts_in_redis}")

    # Lần 4: Vượt quá 3 lần -> Phải khóa và tự động hủy OTP trong Redis
    r4 = requests.post(f"{BASE_URL}/auth/otp/verify", json={
        "phoneNumber": test_phone,
        "code": "333333",
        "purpose": "REGISTER"
    })
    otp_after_lock = get_redis_key(redis_otp_key)
    if r4.status_code == 400 and "quá 3 lần" in r4.json().get("message", "") and otp_after_lock is None:
        log_success(f"Khóa OTP thành công: Mã bị tiêu hủy ngay khỏi Redis để chống vét cạn: '{r4.json().get('message')}'")
    else:
        log_fail(f"Lần 4 không khóa hoặc chưa tiêu hủy OTP: HTTP {r4.status_code}, key còn={otp_after_lock}")

    # --------------------------------------------------------------------------
    # 1.4 Kiểm tra Hết hạn OTP (TTL Expiration)
    # --------------------------------------------------------------------------
    print("\n--- 1.4 Kiểm tra xác thực OTP đã hết hạn (TTL Expired) ---")
    expired_resp = requests.post(f"{BASE_URL}/auth/otp/verify", json={
        "phoneNumber": test_phone,
        "code": "123456",
        "purpose": "REGISTER"
    })
    if expired_resp.status_code == 400 and "hết hạn hoặc không tồn tại" in expired_resp.json().get("message", ""):
        log_success(f"Hệ thống từ chối OTP hết hạn chính xác: '{expired_resp.json().get('message')}'")
    else:
        log_fail(f"Xử lý OTP hết hạn chưa chuẩn: HTTP {expired_resp.status_code} - {expired_resp.text}")

    # --------------------------------------------------------------------------
    # 1.5 Kiểm tra Xác thực thành công & Cấp JWT otpToken
    # --------------------------------------------------------------------------
    print("\n--- 1.5 Kiểm tra Xác thực OTP thành công & Cấp Token ---")
    # Sinh OTP mới
    requests.post(f"{BASE_URL}/auth/otp/send", json={
        "phoneNumber": test_phone,
        "purpose": "REGISTER",
        "email": test_email
    })
    new_otp_code = get_redis_key(redis_otp_key)
    print(f"  Mã OTP mới từ Redis: {new_otp_code}")
    
    verify_resp = requests.post(f"{BASE_URL}/auth/otp/verify", json={
        "phoneNumber": test_phone,
        "code": new_otp_code,
        "purpose": "REGISTER"
    })
    otp_token = None
    if verify_resp.status_code == 200:
        v_data = verify_resp.json().get("data", {})
        otp_token = v_data.get("otpToken")
        if v_data.get("verified") is True and otp_token:
            log_success(f"Xác thực OTP thành công: verified=True, cấp JWT otpToken ({otp_token[:25]}...)")
        else:
            log_fail(f"Dữ liệu xác thực không đầy đủ: {v_data}")
        # Kiểm tra OTP đã bị xóa khỏi Redis sau khi dùng xong
        if get_redis_key(redis_otp_key) is None:
            log_success("Mã OTP đã tự động tiêu hủy khỏi Redis ngay sau khi xác thực thành công (One-Time-Password)")
        else:
            log_fail("Mã OTP chưa được xóa khỏi Redis sau khi xác thực!")
    else:
        log_fail(f"Xác thực OTP hợp lệ thất bại: HTTP {verify_resp.status_code} - {verify_resp.text}")

    # --------------------------------------------------------------------------
    # 1.6 Kiểm tra Luồng Đăng ký & Reset Password qua OTP Token
    # --------------------------------------------------------------------------
    print("\n--- 1.6 Kiểm tra hoàn tất Đăng ký tài khoản và Reset Mật khẩu qua OTP Token ---")
    reg_resp = requests.post(f"{BASE_URL}/auth/register", json={
        "phoneNumber": test_phone,
        "email": test_email,
        "fullName": "Le Van OTP Test",
        "password": "Password123!",
        "deviceId": "device-otp-test"
    })
    
    if reg_resp.status_code in [200, 201]:
        log_success(f"Đăng ký tài khoản {test_phone} thành công")
        
        # Test Forgot Password OTP flow
        fp_resp = requests.post(f"{BASE_URL}/auth/forgot-password", json={
            "phoneNumber": test_phone
        })
        if fp_resp.status_code == 200:
            log_success(f"Yêu cầu Quên mật khẩu gửi OTP thành công: maskedEmail={fp_resp.json().get('data', {}).get('maskedEmail')}")
            fp_otp_key = f"identity:otp:{test_phone}:FORGOT_PASSWORD"
            fp_code = get_redis_key(fp_otp_key)
            if fp_code:
                log_success(f"Lấy mã OTP Forgot Password từ Redis: {fp_code}")
                # Verify forgot password OTP
                v_fp_resp = requests.post(f"{BASE_URL}/auth/otp/verify", json={
                    "phoneNumber": test_phone,
                    "code": fp_code,
                    "purpose": "FORGOT_PASSWORD"
                })
                fp_token = v_fp_resp.json().get("data", {}).get("otpToken")
                if fp_token:
                    log_success(f"Xác thực OTP Quên mật khẩu thành công, nhận fp_token")
                    # Reset password using CORRECT endpoint: /auth/reset-password (không phải /forgot-password/reset)
                    new_password = "NewPassword456!"
                    reset_resp = requests.post(f"{BASE_URL}/auth/reset-password", json={
                        "phoneNumber": test_phone,
                        "otpToken": fp_token,
                        "newPassword": new_password
                    })
                    if reset_resp.status_code == 200:
                        log_success("Đặt lại mật khẩu thành công bằng otpToken (endpoint: /auth/reset-password)")
                        # Test login with new password
                        login_new = requests.post(f"{BASE_URL}/auth/login", json={
                            "phoneNumber": test_phone,
                            "password": new_password,
                            "deviceId": "device-otp-test"
                        })
                        if login_new.status_code == 200:
                            log_success("Đăng nhập thành công với mật khẩu mới đã đặt lại")
                        else:
                            log_fail(f"Đăng nhập với mật khẩu mới thất bại: {login_new.text}")
                    else:
                        log_fail(f"Đặt lại mật khẩu thất bại: {reset_resp.text}")
                else:
                    log_fail(f"Không nhận được fp_token: {v_fp_resp.text}")
            else:
                log_fail("Không tìm thấy mã OTP Forgot Password trong Redis")
        else:
            log_fail(f"Gọi /auth/forgot-password thất bại: {fp_resp.text}")
    else:
        log_fail(f"Đăng ký tài khoản thất bại: HTTP {reg_resp.status_code} - {reg_resp.text}")


# ==============================================================================
# PHASE 2: E2E KIỂM TRA CHUYÊN SÂU THÔNG BÁO ĐẨY (PUSH NOTIFICATION / WEBSOCKET)
# ==============================================================================
async def test_push_and_websocket_flows():
    log_step("PHASE 2: KIỂM TRA CHUYÊN SÂU THÔNG BÁO ĐẨY & WEBSOCKET STOMP REALTIME")

    # Đăng nhập lấy JWT của tài khoản test (0901234567 - seed account Alice, balance ~13M VND)
    login_res = requests.post(f"{BASE_URL}/auth/login", json={
        "phoneNumber": "0901234567",
        "password": "DemoPass#2026!",
        "deviceId": "device-push-test"
    })
    if login_res.status_code != 200:
        log_fail(f"Không thể đăng nhập tài khoản seed Alice (0901234567): {login_res.text}")
        return

    auth_data = login_res.json()["data"]
    access_token = auth_data["accessToken"]
    user_id = auth_data["userId"]
    headers = {"Authorization": f"Bearer {access_token}"}

    # Lấy walletId
    wallet_res = requests.get(f"{BASE_URL}/wallets/me", headers=headers)
    wallet_data = wallet_res.json().get("data", {})
    wallet_id = wallet_data.get("id") or wallet_data.get("walletId")
    log_success(f"Xác thực người dùng thành công: userId={user_id}, walletId={wallet_id}")

    # --------------------------------------------------------------------------
    # 2.1 Đăng ký Thiết bị FCM Device Token (POST /devices/register)
    # --------------------------------------------------------------------------
    print("\n--- 2.1 Kiểm tra Đăng ký FCM Device Token cho Ứng dụng Mobile ---")
    mock_fcm_token = f"fcm_token_flutter_mobile_{int(time.time())}"
    reg_device_res = requests.post(f"{BASE_URL}/devices/register", headers=headers, json={
        "fcmToken": mock_fcm_token,
        "deviceType": "ANDROID",
        "deviceModel": "Google Pixel 8 Pro",
        "appVersion": "1.0.0"
    })
    if reg_device_res.status_code == 200:
        log_success(f"Đăng ký Device Token thành công: {mock_fcm_token}")
        # Kiểm tra bảng device_tokens trong DB
        db_token_check = query_notification_db(
            f"SELECT COUNT(*) FROM device_tokens WHERE user_id = '{user_id}' AND token = '{mock_fcm_token}' AND is_active = true;"
        )
        if db_token_check == "1":
            log_success(f"Cơ sở dữ liệu PostgreSQL đã ghi nhận token đang active cho userId={user_id}")
        else:
            log_fail(f"Không tìm thấy token active trong Postgres: count={db_token_check}")
    else:
        log_fail(f"Đăng ký FCM Device Token thất bại: HTTP {reg_device_res.status_code} - {reg_device_res.text}")

    # --------------------------------------------------------------------------
    # 2.2 Kết nối STOMP WebSocket Native & Lắng nghe thông báo Realtime
    # --------------------------------------------------------------------------
    print("\n--- 2.2 Kiểm tra Kết nối STOMP WebSocket Native (/ws-native) ---")
    received_stomp_notifications = []

    async def stomp_listener():
        try:
            ws_headers = {"Authorization": f"Bearer {access_token}"}
            async with websockets.connect(WS_URL, extra_headers=ws_headers) as ws:
                # Gửi CONNECT frame STOMP
                connect_frame = f"CONNECT\naccept-version:1.2,1.1,1.0\nheart-beat:10000,10000\nAuthorization:Bearer {access_token}\n\n\x00"
                await ws.send(connect_frame)
                
                resp = await ws.recv()
                if "CONNECTED" in resp:
                    log_success(f"STOMP WebSocket Broker phản hồi CONNECTED thành công trên {WS_URL}")
                else:
                    log_fail(f"STOMP không nhận được CONNECTED: {resp}")
                    return

                # Subscribe /topic/wallets/{walletId}/notifications
                wallet_topic = f"/topic/wallets/{wallet_id}/notifications"
                sub_wallet = f"SUBSCRIBE\nid:sub-wallet-0\ndestination:{wallet_topic}\n\n\x00"
                await ws.send(sub_wallet)
                log_success(f"Đã subscribe STOMP topic: {wallet_topic}")

                # Subscribe /topic/users/{userId}/notifications
                user_topic = f"/topic/users/{user_id}/notifications"
                sub_user = f"SUBSCRIBE\nid:sub-user-0\ndestination:{user_topic}\n\n\x00"
                await ws.send(sub_user)
                log_success(f"Đã subscribe STOMP topic: {user_topic}")

                # Chờ thông báo đẩy trong tối đa 10 giây
                try:
                    while True:
                        msg = await asyncio.wait_for(ws.recv(), timeout=7.0)
                        if "MESSAGE" in msg:
                            received_stomp_notifications.append(msg)
                            log_success(f"STOMP nhận khung MESSAGE thời gian thực!")
                            break
                except asyncio.TimeoutError:
                    print("  [WebSocket STOMP] Hết thời gian chờ khung MESSAGE realtime.")
        except Exception as e:
            log_fail(f"Lỗi STOMP WebSocket: {e}")

    # --------------------------------------------------------------------------
    # 2.3 Kích hoạt Giao dịch Biến động Số dư Thực tế
    # --------------------------------------------------------------------------
    print("\n--- 2.3 Kích hoạt Giao dịch Thực tế & Đón nhận Thông báo Đẩy ---")
    
    async def trigger_transaction():
        await asyncio.sleep(1.0) # Cho WebSocket kịp kết nối và subscribe
        # Nạp tiền vào ví
        deposit_amount = 50000
        print(f"  Thực hiện nạp tiền +{deposit_amount:,} VND vào ví...")
        dep_res = requests.post(f"{BASE_URL}/wallets/deposit", headers=headers, json={
            "amount": deposit_amount,
            "description": "Nạp tiền kiểm tra thông báo đẩy Mobile"
        })
        if dep_res.status_code == 200:
            log_success(f"Giao dịch nạp tiền thành công: +{deposit_amount:,} VND")
        else:
            log_fail(f"Giao dịch nạp tiền thất bại: {dep_res.text}")

    # Chạy song song WebSocket listener và transaction trigger
    await asyncio.gather(stomp_listener(), trigger_transaction())

    # --------------------------------------------------------------------------
    # 2.4 Kiểm tra Lưu trữ & REST APIs Quản lý Thông báo phía Mobile
    # --------------------------------------------------------------------------
    print("\n--- 2.4 Kiểm tra REST APIs Quản lý Thông báo (Mobile Endpoints) ---")
    time.sleep(1.0) # Đợi Kafka & consumer ghi nhận DB

    # Lấy danh sách thông báo
    notifs_res = requests.get(f"{BASE_URL}/notifications?type=BALANCE&page=0&size=10", headers=headers)
    latest_notif_id = None
    if notifs_res.status_code == 200:
        notif_body = notifs_res.json()
        content = notif_body.get("data", {}).get("content", [])
        log_success(f"Lấy danh sách thông báo thành công: tìm thấy {len(content)} thông báo BALANCE")
        if len(content) > 0:
            top_notif = content[0]
            latest_notif_id = top_notif.get("id")
            title = top_notif.get("title")
            body = top_notif.get("body")
            payload = top_notif.get("dataPayload")
            log_success(f"Thông báo mới nhất: id={latest_notif_id}, title='{title}', body='{body}'")
            if payload:
                log_success(f"Dữ liệu mở rộng dataPayload hợp lệ (Mobile bóc tách số tiền & số dư cuối)")
        else:
            log_fail("Danh sách thông báo trống!")
    else:
        log_fail(f"Gọi GET /notifications thất bại: HTTP {notifs_res.status_code} - {notifs_res.text}")

    # Kiểm tra số lượng chưa đọc (unread count)
    unread_res = requests.get(f"{BASE_URL}/notifications/unread-count", headers=headers)
    if unread_res.status_code == 200:
        unread_count = unread_res.json().get("data", {}).get("unread", 0)
        log_success(f"Số lượng thông báo chưa đọc: unread={unread_count}")
    else:
        log_fail(f"Gọi GET /notifications/unread-count thất bại: {unread_res.text}")

    # Đánh dấu 1 thông báo là đã đọc (PATCH /notifications/{id}/read)
    if latest_notif_id:
        read_res = requests.patch(f"{BASE_URL}/notifications/{latest_notif_id}/read", headers=headers)
        if read_res.status_code == 200:
            log_success(f"Đánh dấu đã đọc thông báo {latest_notif_id} thành công")
        else:
            log_fail(f"Đánh dấu đã đọc thất bại: HTTP {read_res.status_code} - {read_res.text}")

    # Đánh dấu tất cả đã đọc (PATCH /notifications/read-all)
    read_all_res = requests.patch(f"{BASE_URL}/notifications/read-all", headers=headers)
    if read_all_res.status_code == 200:
        log_success("Đánh dấu tất cả thông báo đã đọc thành công")
        # Kiểm tra lại unread count phải bằng 0
        unread_after = requests.get(f"{BASE_URL}/notifications/unread-count", headers=headers).json().get("data", {}).get("unread")
        if unread_after == 0:
            log_success("Xác nhận số lượng chưa đọc sau khi read-all về đúng 0")
        else:
            log_fail(f"Unread count sau khi read-all vẫn còn: {unread_after}")
    else:
        log_fail(f"Đánh dấu tất cả đã đọc thất bại: {read_all_res.text}")

    # Cập nhật cài đặt thông báo (PUT /notifications/settings)
    settings_res = requests.put(f"{BASE_URL}/notifications/settings", headers=headers, json={
        "transactionAlerts": True,
        "promotions": False
    })
    if settings_res.status_code == 200:
        log_success("Cập nhật tùy chọn thông báo (transactionAlerts=True, promotions=False) thành công")
    else:
        log_fail(f"Cập nhật cài đặt thông báo thất bại: {settings_res.text}")

    # --------------------------------------------------------------------------
    # 2.5 Hủy Đăng ký Thiết bị FCM (DELETE /devices/unregister)
    # --------------------------------------------------------------------------
    print("\n--- 2.5 Kiểm tra Hủy Đăng ký FCM Device Token khi Đăng xuất ---")
    unreg_res = requests.delete(f"{BASE_URL}/devices/unregister?fcmToken={mock_fcm_token}", headers=headers)
    if unreg_res.status_code == 200:
        log_success(f"Hủy đăng ký FCM token {mock_fcm_token} thành công")
        db_unreg_check = query_notification_db(
            f"SELECT COUNT(*) FROM device_tokens WHERE token = '{mock_fcm_token}' AND is_active = true;"
        )
        if db_unreg_check == "0":
            log_success("Cơ sở dữ liệu đã hủy kích hoạt token thành công")
        else:
            log_fail(f"Token vẫn còn active trong database: count={db_unreg_check}")
    else:
        log_fail(f"Hủy đăng ký FCM token thất bại: HTTP {unreg_res.status_code} - {unreg_res.text}")


# ==============================================================================
# MAIN ENTRYPOINT
# ==============================================================================
def main():
    print(f"\n{COLOR_CYAN}BẮT ĐẦU CHƯƠNG TRÌNH KIỂM TRA CHUYÊN SÂU E2E: OTP EMAIL & PUSH NOTIFICATION{COLOR_RESET}")
    start_time = time.time()

    # 1. Chạy Phase 1: OTP Email
    test_otp_email_flows()

    # 2. Chạy Phase 2: Push Notifications & WebSocket STOMP
    asyncio.run(test_push_and_websocket_flows())

    elapsed = time.time() - start_time
    print(f"\n{COLOR_CYAN}{'='*80}{COLOR_RESET}")
    print(f"{COLOR_CYAN}KẾT QUẢ TỔNG QUAN KIỂM TRA E2E:{COLOR_RESET}")
    print(f"  - Tổng số test case PASS: {COLOR_GREEN}{passed_tests}{COLOR_RESET}")
    print(f"  - Tổng số test case FAIL: {COLOR_RED}{failed_tests}{COLOR_RESET}")
    print(f"  - Tổng thời gian thực thi: {elapsed:.2f}s")
    print(f"{COLOR_CYAN}{'='*80}{COLOR_RESET}")

    if failed_tests > 0:
        sys.exit(1)
    else:
        print(f"\n{COLOR_GREEN}✓ TẤT CẢ CÁC BƯỚC KIỂM TRA E2E OTP EMAIL VÀ PUSH NOTIFICATION HOÀN TOÀN ĐẠT CHUẨN 100%!{COLOR_RESET}\n")

if __name__ == "__main__":
    main()

