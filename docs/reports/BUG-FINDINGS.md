# Báo Cáo Bug & Vấn Đề Phát Hiện Được

## Tổng Quan
- **Ngày kiểm tra:** 2026-11-05 (cập nhật lần 2: 2026-11-06)
- **E2E Test Status:** 55/55 pass (100%)
- **Graphify Update:** 8.287 nodes, 18.623 edges, 366 communities
- **Backend Compile:** SUCCESS (all services)

---

## ✅ CẬP NHẬT AUDIT 2026-11-06: Backend Full Test Suite

### 🔴 CRITICAL (đã fix): Spring Context boot fail — `WalletBalanceChangedKafkaProducer`

**File:** `backend/services/wallet-service/src/main/java/com/fintech/wallet/infrastructure/kafka/WalletBalanceChangedKafkaProducer.java:34`

**Triệu chứng:** `WalletPostgresIntegrationTest` fail — `Failed to instantiate [WalletBalanceChangedKafkaProducer]: No default constructor found`.

**Nguyên nhân gốc:** Class `@Component` có **2 public constructor không có `@Autowired`**. Spring với 2+ constructor mà không có annotation chỉ định sẽ fallback sang no-arg constructor — vốn không tồn tại → boot context fail. **Đây là bug production thật: wallet-service không thể start**, không chỉ lỗi test.

**Fix:** Xóa constructor 1-arg dead code (không ai gọi — đã grep toàn repo), giữ duy nhất constructor 2-arg để Spring tự resolve.

**Xác minh:** `mvn -pl backend/services/wallet-service test -Dtest=WalletPostgresIntegrationTest` → **EXIT=0** (context boot OK; các log SQL ERROR trong log là expected từ test negative-path).

---

### 🟢 (đã xử lý): `NotificationConsumerTest` — `ClassNotFoundException: WebSocketNotifier`

**Nguyên nhân:** Class compiled stale trong `target/` từ thời `WebSocketNotifier` còn nằm ở default package; incremental compile không build lại.

**Fix:** `mvn clean test` notification-service → **8/8 pass** (report stale cũ thậm chí sai cả số test: 1 thay vì 8).

---

### 🟢 (stale, không phải bug): Các surefire report fail cũ

| Report cũ (5/11) | Trạng thái thực tế 6/11 |
|---|---|
| `LotteryControllerTest` (401→500, 2 fail) | Chạy lại **5/5 pass** |
| `ConfigLimitControllerTest` (401→500, 1 fail) | Chạy lại **3/3 pass** |
| `AmlCaseControllerTest` (403→500, 1 fail) | Test class đã bị xóa; `AmlCaseController.java` hiện đã có `requireManager()` → 403, `requireUser()` → 401 đúng chuẩn (`AmlCaseController.java:76-89`) |

---

## ✅ CRITICAL CŨ — ĐÃ XÁC NHẬN FIX (2026-11-06): Hardcoded Bcrypt Hash

**File:** `backend/services/identity-service/src/main/java/com/fintech/identity/service/AuthService.java`

**Xác minh:** Hash `$2a$10$Bcg3rjT7oYME6TAZkU8yiuHtvX01FWxsK...` **không còn tồn tại** trong source. Logic login hiện chỉ dùng `passwordEncoder.matches()` chuẩn với 2 lần thử (raw + trimmed cho mobile keyboard/autofill). Không còn backdoor path.

---

## 🟡 MEDIUM: Flutter Secure Storage MissingPluginException

**File:** `mobile/test/real_data_e2e_verification_test.dart` (và các test khác)

**Vấn đề:** Log liên tục:
```
[AppSecureStorage] Lỗi an toàn khi đọc khóa access_token: 
MissingPluginException(No implementation found for method read on channel 
plugins.it_nomads.com/flutter_secure_storage)
```

**Nguyên nhân:** Flutter test VM không load native plugin `flutter_secure_storage`.

**Ảnh hưởng:** Test vẫn pass vì mock/interceptor xử lý gracefully, nhưng:
- Token không được lưu secure storage trong test
- Không test được flow logout/clear token thực sự
- Production mobile app có thể gặp issue tương tự trên một số device

**Khuyến nghị:**
- Setup `FlutterError.onError` trong test để catch missing plugins
- Hoặc dùng `MockFlutterSecureStorage` cho unit tests
- Verify plugin registration trong `main()` của test suite

---

## 🟡 MEDIUM: Mixed Content Warnings (HTTP + HTTPS)

**File:** `mobile/lib/core/network/dio_client.dart`
**File:** `mobile/lib/presentation/screens/settings/config_screen.dart`

**Vấn đề:** Code vẫn reference đến `http://` thay vì chỉ dùng `https://` cho production:
```dart
// Line 35-36
'url': 'https://mutation-tubby-overstock.ngrok-free.dev/api/v1',
'ws': 'wss://mutation-tubby-overstock.ngrok-free.dev/ws-native',
```

**Rủi ro:** Nếu switch sang localhost/production, có thể xảy ra mixed content blocking trên iOS/Android modern.

**Khuyến nghị:**
- Thêm validation强制 dùng HTTPS cho production endpoints
- Thêm warning khi detect HTTP in production mode

---

## 🟢 LOW: Test Passwords in Source

**Files:**
- `scripts/maintenance/UpdateDb.java:10` - `String pass = "walletpassword";`
- `mobile/test/remote_datasources_test.dart:178` - hardcoded test credentials

**Nhận xét:** Acceptable cho test code, nhưng nên move vào `.env` hoặc config file riêng để tránh commit accident.

---

## ✅ Đã Fix Trong Phiên Này

### Null-Safety Error
**File:** `mobile/test/real_data_e2e_verification_test.dart:155`

```diff
- targetUserId: receiverUserId ?? '',
+ targetUserId: receiverUserId,
```

**Lý do:** `receiverUserId` đã được declare là non-nullable String, nên `?? ''` là dead code và gây compile warning.

---

## Kiểm Thử E2E Qua Ngrok Public

**URL:** `https://mutation-tubby-overstock.ngrok-free.dev/api/v1`

| Suite | Tests | Passed | Failed |
|-------|-------|--------|--------|
| Real Data Deep Audit | 7 | 7 | 0 |
| Mobile Real Data E2E | 21 | 21 | 0 |
| Backend Inventory Contract | 4 | 4 | 0 |
| Mobile-Web Integration | 23 | 23 | 0 |
| **TOTAL** | **55** | **55** | **0** |

**Kết quả:** Tất cả nghiệp vụ core banking hoạt động đúng qua tunnel công khai:
- ✅ Đăng ký/User/KYC
- ✅ Maker-Checker Nạp Tiền
- ✅ Vay Tiêu Dùng + Tất Toán Trước Hạn
- ✅ Biometric Auth (QĐ 2345)
- ✅ AML Monitoring (≥400M VND)
- ✅ Emergency Kill-Switch
- ✅ Double-Entry Ledger Balance (Debit = Credit, Delta = 0)

---

## Khuyến Nghị Tiếp Theo

1. ~~**Immediate:** Xóa hardcoded bcrypt hash trong AuthService.java~~ ✅ **Đã fix (xác nhận 6/11)**
2. **Short-term:** Thêm CI check cho security scan (detect hardcoded secrets)
3. **Short-term:** Thêm CI check quy tắc "1 constructor @Component không cần @Autowired; 2+ constructor phải có @Autowired" — bug wallet producer hôm nay vượt qua được compile vì nó chỉ fail lúc runtime
4. **Short-term:** Xóa `target/` stale artifacts hoặc luôn `mvn clean test` trong CI — report/class compiled cũ gây chẩn đoán sai (case notification + 3 report stale)
5. **Medium-term:** Setup proper test fixtures thay vì hardcode passwords
6. **Graphify:** Cần chạy `graphify update .` sau khi sửa `WalletBalanceChangedKafkaProducer`
