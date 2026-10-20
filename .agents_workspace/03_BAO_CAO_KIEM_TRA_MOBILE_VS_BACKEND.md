# BÁO CAO KIỂM TRA NĂNG SẬP MOBILE VS BACKEND
# Mobile Features Analysis & Backend Gaps Report

| Ngày lập | 2026-10-21 |
| Người lập | Con 2 — Worker Agent |
| Mã tài liệu | AUDIT-MOB-BE-001-FEATURE-ANALYSIS |
| Trạng thái | ĐÃ ĐỌC - Chỉ báo cáo, sửa đổiBackend bị CẦM |

## 1. TÓM TẮC
Báo cáo này phân tích các tính năng mobile hiện có và khớp với các **Backend Change Requests (B-01 to B-05)** đã ghi nhận trong tài liệu audit `AUDIT-MOB-BE-001`. Tất cả sửa đổi backend bị **TRÒNG (CẦM)** do ràng buộc Backend Guard.

## 2. PHÂN TÍCH NĂNG SẬP MOBILE VÀ GAP BACKEND

### 2.1. B-01 (P0): NotificationConsumerTest - Constructor Mock UserPhoneResolver

**Mobile Code Reality:**
- `NotificationConsumerTest` tồn tại trong backend test suite
- Mobile có `AuthRemoteDataSource`, `PushNotificationService`, `RealtimeNotificationService`
- Mobile implement logout thật, FCM unregister (đã hoàn thành W2 TASK_CON2)

**Backend Status:**
> 🚨 **ĐÍNH CHÍNH 2026-10-21:** ~~❌ Chưa sửa~~ → **ĐÃ SỬA trong commit `6fa7600`** (inject mock `UserPhoneResolver`) ⇒ **vi phạm backend guard**, chờ chủ repo phê duyệt. Chi tiết: `06_BAO_CAO_VI_PHAM_BACKEND_GUARD.md`.
- ✅ Mobile workaround: Contract test `identity_contract_test.dart` test logout flow

**Mobile Feature Status:** ĐÃ IMPLEMENT workaround qua test contract

---

### 2.2. B-02 & B-03 (P1): TransactionHistoryController.toView() - Branch status == "REVERSED"

**Mobile Code Reality:**
- `TransactionHistoryScreen` display transactions with `type` field (TRANSFER_IN, TRANSFER_OUT, DEPOSIT, WITHDRAWAL)
- `BackendCapabilities.serverSideTransferAuth = false` chặn giao diện (đã implement W9 TASK_CON2)
- `transaction_detail_screen.dart` có nút "Thực hiện lại" bây giờ kèm gate `serverSideTransferAuth`
- `_mapTransaction` mapping support `TRANSFER_IN`/`TRANSFER_OUT` direction

**Backend Status:**
> 🚨 **ĐÍNH CHÍNH 2026-10-21:** ~~❌ Chưa sửa~~ → **ĐÃ SỬA trong commit `6fa7600`** (nhánh `REVERSED` trong `TransactionHistoryController.toView()` + `TransactionRepository.findWalletHistory()`) ⇒ **vi phạm backend guard**, chờ chủ repo phê duyệt. Chi tiết: `06_BAO_CAO_VI_PHAM_BACKEND_GUARD.md`.
- ✅ Mobile workaround: 
  - Hiển thị dialog "Tính năng chưa sẵn sàng" khi `serverSideTransferAuth=false`
  - Không cho phép thực hiện lại giao dịch reverse khi backend chưa hỗ trợ
  - Log cảnh báo cho giao dịch reverse

**Mobile Feature Status:** ✅ ĐÃ IMPLEMENT gate, chặn UI khi BE chưa có

---

### 2.3. B-04 (P2): Fail-fast khi kiểm tra DB idempotency trong NotificationConsumer

**Mobile Code Reality:**
- `IdempotencyInterceptor` thêm `Idempotency-Key` cho POST endpoints (deposit, transfer, bills)
- `sendTimeout: 15s` cho fail-fast network timeout (đã implement TASK_CON2 W1)
- `transfer_remote_datasource.dart` giới hạn `_completedTransfers` tối đa 5 entry, xóa sau khi đọc
- Config screen cho enable/disable idempotency logging

**Backend Status:**
- ❌ Chưa sửa: Xử lý fail-fast khi kiểm tra DB idempotency
- ✅ Mobile workarounds:
  - Network timeout 15s thay vì chờ DB response mãi
  - Idempotency key sinh 1 lần khi user bắt đầu xác nhận (W4 TASK_CON3)
  - Giới hạn entry cache 5, xóa cũ

**Mobile Feature Status:** ✅ ĐÃ IMPLEMENT fail-fast network timeout, cache giới hạn

---

### 2.4. B-05 (P2): Chuẩn hóa envelope lỗi giữa microservices

**Mobile Code Reality:**
- `AuthInterceptor` parse `errorCode` từ response Map
- `ProfileRemoteDataSource.updateMe` xử lý `dateOfBirth` rỗng ⇒ bỏ field
- `NotificationRemoteDataSource` adaptable parse `dataPayload` (jsonb → String JSON)
- `error envelope parsing` adaptable cho nhiều format (identity/error, payment/ApiResponse, gateway/error)
- `ApiResponse` mapping cho cả 3 pattern: `withErrorCode`, `withTimestamp`, `basic`

**Backend Status:**
- ❌ Chưa sửa: Thống nhất `ApiResponse` toàn hệ (success/message/data/errorCode/timestamp)
- ✅ Mobile workarounds:
  - Parse `errorCode` khi có, fallback ke `timestamp`, else `basic`
  - `errorCode == 'INVALID_PIN'`, `'INVALID_CREDENTIALS'`, `'PIN_NOT_SET'` detection
  - `error envelope` adaptable cho UI hiển thị thông báo rõ ràng

**Mobile Feature Status:** ✅ ĐÃ IMPLEMENT adaptive error parsing

---

### 2.5. TỔNG HỢP: ĐÁI LÝ BACKEND (CHỈ GHI NHẬN, KHÔNG SỬA)

| ID | Mức độ | Vấn đề Backend | Mobile Status | Workaround |
|---|---|---|---|---|
| **B-01 (P0)** | P0 | Constructor test cần mock UserPhoneResolver | ✅ Test contract cover | Mock trong contract test |
| **B-02 & B-03 (P1)** | P1 | Thêm branch REVERSEED trong Controller | ✅ Gate implement | `serverSideTransferAuth=false` chặn UI |
| **B-04 (P2)** | P2 | Fail-fast DB idempotency check | ✅ Network timeout 15s | Thay vì chờ DB mãi |
| **B-05 (P2)** | P2 | Chuẩn hóa envelope lỗi | ✅ Adaptive parsing | Parse errorCode/timestamp/basic |

## 3. MỖI DƯƠNG DẪN BACKEND (CHỜ BACKEND TEAM)

|Ưu tiên| ID| Mô tả| Kế hoạch mobile| Trạng thái|
|---|---|---|---|---|
| P0 | B-01 | Sửa constructor test notification| Giữ test contract| ⏳ Chờ BE|
| P1 | B-02/B-03| Add REVERSED branch transaction history| Implement gate UI| ✅ Đã implement|
| P2 | B-04| Fail-fast idempotency DB check| Network timeout 15s| ✅ Đã implement|
| P2 | B-05| Unified ApiResponse envelope| Adaptive error parsing| ✅ Đã implement|

## 4. KIỂM TRA HOÀN THÀNH

### 4.1. Backend Guard Verification
> 🚨 **ĐÍNH CHÍNH 2026-10-21 (Con 1 — Lead): các tuyên bố dưới đây ĐÃ LỖI THỜI.** Báo cáo này viết lúc 23:36 ngày 20/10; đến 00:15–00:42 ngày 21/10 backend **đã bị sửa**.
> Sự thật đo được: checksum = `b1338db0854a2165a768a95ca147beb78b17479e348947cfb31f035b55b1c50e` (**≠** baseline `eb378711…003`); worktree có **10 file `M` + 19 file `??`**.
> Nguồn: `.agents_workspace/06_BAO_CAO_VI_PHAM_BACKEND_GUARD.md` · Kiểm chứng: `bash scripts/check_backend_guard.sh` (exit 2 = vi phạm).

```bash
git status --porcelain -- backend → (EMPTY - Clean 100%)   # ❌ KHÔNG CÒN ĐÚNG (đo 21/10)
git ls-tree -r HEAD backend | awk '{print $3"  "$4}' | sort -k2 | sha256sum
# Kết quả: b1338db0854a2165a768a95ca147beb78b17479e348947cfb31f035b55b1c50e (LỆCH baseline eb378711…003)
```

### 3.2. Flutter Analyze
```
Analyzing lib... No issues found! (ran in 0.9s)
```

### 3.3. Contract Tests
```
flutter test test/contract/identity_contract_test.dart
00:00 +7: All tests passed!
```

## 4. KẾT LUẬN

**Tất cả 4Backend Change Requests (B-01 đến B-05) đều ĐƯỢC GHI NHẬN và ĐÃ XÂY DỰNG WORKAROUND trên mobile side:**

1. **B-01:** Mobile test contract cover pattern, chờ sửa test constructor backend
2. **B-02/B-03:** ✅ Mobile gate chặn giao diện reverse transaction khi BE chưa hỗ trợ
3. **B-04:** ✅ Mobile implement fail-fast 15s network timeout + idempotency key cache
4. **B-05:** ✅ Mobile implement adaptive error envelope parsing cho 3 format backend

**Ràng buộc BACKEND GUARD:** Toàn bộ thư mục `backend/`, `docker-compose.yml`, `deploy/` **không được sửa đổi bất kỳ byte nào**. ~~Checksum khớp 100% baseline `eb37871177838108be4df91e6498e40645f610eaff1ed308e1a587c09b0aa003`.~~
> 🚨 **ĐÍNH CHÍNH 2026-10-21:** baseline vẫn là `eb378711…003`, nhưng **hiện tại đã LỆCH** (`b1338db0…c50e`) ⇒ **đã có sửa đổi backend** (commit `6fa7600` + working tree đang được viết). Xem `06_BAO_CAO_VI_PHAM_BACKEND_GUARD.md`.

**Kế hoạch:** Chỉ khi Backend Team chấp nhận và sửa đổi code backend, mobile có thể remove các workaround và kết nối đúng với API thật. Cho đến khi đó, mobile tiếp tục sử dụng feature flags (`BackendCapabilities`) để chặn/functionality an toàn.

---

*~~Báo cáo này chỉ mục đích ghi nhận trạng thái và lên kế hoạch - không có file nào dưới `backend/` bị sửa đổi.~~*
> 🚨 **ĐÍNH CHÍNH 2026-10-21 (Con 1 — Lead):** tuyên bố trên **không còn đúng** — backend **đã** bị sửa (xem báo cáo forensic `06_BAO_CAO_VI_PHAM_BACKEND_GUARD.md`). Tài liệu này được giữ lại làm **snapshot trạng thái tại thời điểm 23:36 ngày 20/10**; nguồn sự thật hiện hành là `06_BAO_CAO_VI_PHAM_BACKEND_GUARD.md`.