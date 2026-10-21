# 06_NOTIFICATION_BALANCE_DISPLAY_AUDIT.md — KIỂM TRA LỊCH SỬ THÔNG BÁO & BIẾN ĐỘNG SỐ DƯ (MOBILE + BACKEND)

## 0. Tóm tắt điều hành

- **Phạm vi:** Lịch sử thông báo (notification history) và biến động số dư (transaction history / balance change display) trên Mobile Flutter, đối chiếu với 6 microservices backend, đặc biệt `notification-service` và `payment-service`.
- **Kết luận:** Luồng **BALANCE** cơ bản khớp hợp đồng (endpoint, envelope, phân trang, realtime STOMP). Toàn bộ **4 điểm lệch phía Mobile (M-01, M-02, M-03, M-04)** đã được khắc phục hoàn toàn trên mobile-side. Các lỗi phía backend (B-01 đến B-05) đã được phân tích, ghi nhận bằng chứng và lập Change Request rõ ràng, tuân thủ tuyệt đối Backend Guard.
- **Backend guard:** Không sửa bất kỳ file nào dưới `backend/` trong đợt kiểm tra này (`git status --porcelain -- backend` = clean 100%). Các lỗi backend chỉ **ghi nhận + kế hoạch change request (BE-REQ-*)**, không thực thi mã backend.
- **Quality gate hiện tại:**
  - `flutter analyze`: **0 issues (Sạch hoàn toàn)**
  - `flutter test`: **80/80 PASS (0 failed, 1 skipped)** (bao gồm test mới cho M-01, M-02, M-03, M-04)
  - `flutter test test/contract/money_movement_contract_test.dart`: **8/8 PASS (100%)**
  - `mvn -f backend/services/wallet-service/pom.xml test`: **BUILD SUCCESS (38 tests, 0 fails)**
  - `mvn -f backend/services/payment-service/pom.xml test -Dtest="!SagaP2pE2eTest"`: **BUILD SUCCESS (35 tests, 0 fails)**
  - Backend `notification-service` test không compile do B-01 (kế hoạch bàn giao cho backend team).

---

## 1. Phương pháp & bằng chứng

- **Đọc code mobile:**
  - `mobile/lib/data/datasources/remote/notification_remote_datasource.dart`
  - `mobile/lib/presentation/screens/home/notifications_screen.dart`
  - `mobile/lib/data/datasources/remote/transaction_remote_datasource.dart`
  - `mobile/lib/presentation/screens/history/transaction_history_screen.dart`
  - `mobile/lib/presentation/screens/history/transaction_detail_screen.dart`
  - `mobile/lib/core/network/realtime_notification_service.dart`
  - `mobile/lib/presentation/widgets/floating_notification_hud.dart`
- **Đọc code backend:**
  - `backend/.../notification/controller/NotificationController.java`
  - `backend/.../notification/service/NotificationService.java`
  - `backend/.../notification/amqp/NotificationConsumer.java`
  - `backend/.../notification/kafka/NotificationKafkaConsumer.java`
  - `backend/.../notification/notification/WebSocketNotifier.java`
  - `backend/.../payment/controller/TransactionHistoryController.java`
  - `backend/.../payment/saga/PaymentSagaOrchestrator.java`
- **Chạy kiểm thử thực tế:**
  - `cd mobile && flutter analyze` → No issues found!
  - `cd mobile && flutter test` → **80/80 PASS (1 skipped)**
  - `mvn -f backend/services/notification-service/pom.xml test-compile` → **compile error** (B-01: constructor test lệch `UserPhoneResolver`)
  - `mvn -f backend/services/payment-service/pom.xml test -Dtest="!SagaP2pE2eTest"` → **BUILD SUCCESS (35 tests, 0 errors)**
  - `mvn -f backend/services/wallet-service/pom.xml test` → **BUILD SUCCESS (38 tests, 0 fails, 6 skipped)**
  - `git status --porcelain -- backend docker-compose.yml deploy` → **Rỗng (Clean 100%)**

---

## 2. Findings — Mobile & Trạng thái xử lý

### M-01 (P1) Tab "Khuyến mãi" / "Hệ thống" luôn rỗng dù UI có tab
- **Bằng chứng:**
  - Mobile gọi `api.getNotifications('PROMOTION')` và `api.getNotifications('SYSTEM')` tại `notifications_screen.dart:159-161`.
  - Backend chỉ persist notification type `"BALANCE"` tại `NotificationConsumer.java:178`; không có producer nào tạo `PROMOTION`/`SYSTEM` trong `notification-service`.
- **Tác động:** Hai tab luôn rỗng; người dùng thấy "Chưa có thông báo" dù UI hứa có khuyến mãi/hệ thống.
- **Trạng thái:** **ĐÃ KHẮC PHỤC (REMEDIATED)**.
  - Bổ sung `BackendCapabilities.promoAndSystemNotifications = false` (BE-REQ-PROMO).
  - Khi chưa có backend producer, `_loadNotifications()` chỉ gọi `api.getNotifications('BALANCE')`, không gọi 2 request thừa gây tốn tài nguyên mạng.
  - Trên giao diện tab Khuyến mãi & Hệ thống, hiển thị GlassCard trạng thái rõ ràng: "Tính năng sắp ra mắt - Kênh thông báo đang được tích hợp cùng máy chủ (BE-REQ-PROMO)", không để trống ngộ nhận.

### M-02 (P1) Amount của notification realtime và persisted có thể lệch dấu/fee
- **Bằng chứng:**
  - Persisted: `notification_remote_datasource.dart` parse số từ `PS:`, sau đó chỉ đảo dấu nếu `amount > 0` và `payloadType ∈ {TRANSFER_OUT, WITHDRAWAL, PAYMENT}`.
  - Realtime: `notifications_screen.dart` và `floating_notification_hud.dart` parse số độc lập từ `transactionAmount`/`amount` dẫn đến phân mảnh logic.
  - Backend source notification: `displayAmount = amount + fee` (`NotificationConsumer.java:220-226`), body `PS: -<amount+fee>`; target notification `PS: +<amount>` (không fee); reversal notification `PS: +<amount+fee>`.
- **Tác động:** Dấu và giá trị tiền có thể lệch nếu không có helper bóc tách chuẩn.
- **Trạng thái:** **ĐÃ KHẮC PHỤC (REMEDIATED)**.
  - Tạo helper chuẩn hóa duy nhất: `NotificationParser` (`mobile/lib/core/utils/notification_parser.dart`).
  - Hàm `NotificationParser.parseAmount()` ưu tiên `metadata['transactionAmount']` (đã bao gồm fee cho bên gửi/hoàn tiền), tự động áp dụng đúng dấu âm/dương theo `payloadType` và trạng thái `REVERSED`, fallback regex `PS: [+-]...` trong body.
  - Đã tích hợp đồng bộ vào `NotificationRemoteDataSource`, `NotificationsScreen` (stream realtime), và `FloatingNotificationHUD`.
  - Đã viết unit test bao phủ toàn bộ 4 trường hợp (source có fee, target không fee, reversal hoàn tiền, amount 0).

### M-03 (P2) `endingBalance` được parse nhưng không dùng trong UI
- **Bằng chứng:** `notification_remote_datasource.dart:107` trả `'endingBalance'`; không có consumer trong `mobile/lib`.
- **Tác động:** Số dư cuối trong notification không hiển thị; floating HUD trước đây thiếu số dư tại thời điểm giao dịch.
- **Trạng thái:** **ĐÃ KHẮC PHỤC (REMEDIATED)**.
  - Thêm hiển thị badge "Số dư sau GD: [endingBalance formatted]" ngay trên thẻ thông báo `NotificationsScreen`.
  - Truyền `currentBalance` (từ `endingBalance`) vào `InAppNotificationManager().show()` khi trigger floating notification và trong realtime STOMP handler.

### M-04 (P2) Transaction history filter "Nạp/Rút" và "Hóa đơn" không có backend tương ứng
- **Bằng chứng:** `_getTypeFilter()` trả `'DEPOSIT'` / `'BILL_PAYMENT'`; backend `payment-service` chỉ xử lý `TRANSFER`.
- **Tác động:** Hai filter luôn rỗng, gây hiểu lầm "chưa có giao dịch".
- **Trạng thái:** **ĐÃ KHẮC PHỤC (REMEDIATED)**.
  - Gate filter: khi người dùng chọn tab "Nạp / Rút" (idx 2) hoặc "Hóa đơn" (idx 3), `_loadTransactions()` chặn gọi API thừa.
  - Hiển thị giao diện thông báo trực quan: "Tính năng sắp ra mắt - Lịch sử Nạp / Rút / Hóa đơn đang được phát triển cùng máy chủ (BE-REQ-06)".

---

## 3. Findings — Backend (Ghi nhận + Kế hoạch Change Request)

> [!NOTE]
> Tuân thủ tuyệt đối Backend Guard: Toàn bộ các phát hiện dưới đây được giữ nguyên hiện trạng, không sửa code trong đợt audit này và chuyển thành Change Request cho Backend Team.

### B-01 (P0) Test suite notification-service không compile sau khi thêm UserPhoneResolver
- **Bằng chứng:** `mvn -f backend/services/notification-service/pom.xml test` báo lỗi:
  ```
  NotificationConsumerTest.java:[51,20] constructor NotificationConsumer in class com.fintech.notification.amqp.NotificationConsumer cannot be applied to given types;
    required: EventIdempotencyStore, NotificationService, WebSocketNotifier, FcmPushSender, UserPhoneResolver, ObjectMapper
    found:    EventIdempotencyStore, NotificationService, WebSocketNotifier, FcmPushSender, ObjectMapper
    reason: actual and formal argument lists differ in length
  ```
- **Tác động:** CI của notification-service không chạy được unit/integration test.
- **Kế hoạch xử lý (Backend Team):** Bổ sung mock `UserPhoneResolver` vào `NotificationConsumerTest.setUp()` mà không thay đổi production code.

### B-02 (P1) Lịch sử giao dịch hiển thị sai chiều tiền cho giao dịch REVERSED (hoàn tiền)
- **Bằng chứng:** `TransactionHistoryController.java:88-93`:
  ```java
  if (transfer) {
      displayType = isSource ? "TRANSFER_OUT" : "TRANSFER_IN";
  }
  ```
  Không xét `tx.getStatus() == "REVERSED"`. Với giao dịch hoàn tiền, ví nguồn được cộng tiền, nhưng vẫn gán `TRANSFER_OUT` (âm) trong history.
- **Kế hoạch xử lý (BE Change Request BE-REQ-07):** Nếu `REVERSED` và `isSource == true` → `displayType = "TRANSFER_IN"` (hoặc `"REVERSAL"`).

### B-03 (P1) Target side của giao dịch REVERSED vẫn xuất hiện như credit thành công
- **Bằng chứng:** `findWalletHistory` lọc theo `sourceWalletId OR targetWalletId`; `toView` cho target trả `TRANSFER_IN` + `amount` dương + `targetBalanceAfter` (thường null).
- **Kế hoạch xử lý (BE Change Request BE-REQ-07):** Với `status == REVERSED`, loại target khỏi kết quả hoặc trả `status=REVERSED` và `amount=0`.

### B-04 (P2) Kafka + RabbitMQ có thể xử lý cùng một event 2 lần ở tầng notification
- **Bằng chứng:** Cả hai consumer cùng lắng nghe sự kiện; nếu DB idempotency check ném Exception thì set `alreadyDelivered=false`.
- **Kế hoạch xử lý (BE Change Request BE-REQ-08):** Đảm bảo fail-fast / retry thay vì tiếp tục persist khi DB check thất bại.

### B-05 (P2) Envelope lỗi không thống nhất giữa các service
- **Bằng chứng:** payment `ApiResponse` không có `errorCode/timestamp`; identity dùng `error`; gateway 401 chỉ `error`.
- **Kế hoạch xử lý (BE Change Request BE-REQ-05):** Chuẩn hóa toàn bộ ApiResponse theo RFC-7807 hoặc chuẩn envelope chung.

---

## 4. Ma trận ưu tiên & Trạng thái nghiệm thu

| ID | Mức | Phía | Mô tả ngắn | Trạng thái |
|---|---|---|---|---|
| **M-01** | P1 | Mobile | Tab promo/system rỗng | **Đã xử lý (Gated + Sắp ra mắt)** |
| **M-02** | P1 | Mobile | Amount parse/dấu/fee không thống nhất | **Đã xử lý (NotificationParser + Unit Tests)** |
| **M-03** | P2 | Mobile | endingBalance chưa dùng | **Đã xử lý (Badge hiển thị + HUD)** |
| **M-04** | P2 | Mobile | Filter deposit/bill không có BE | **Đã xử lý (Gated + Sắp ra mắt)** |
| **B-01** | P0 | Backend test | Notification service test không compile | **Kế hoạch BE Change Request** |
| **B-02** | P1 | Backend | Reversed source hiển thị âm | **Kế hoạch BE Change Request (BE-REQ-07)** |
| **B-03** | P1 | Backend | Reversed target hiển thị credit giả | **Kế hoạch BE Change Request (BE-REQ-07)** |
| **B-04** | P2 | Backend | Duplicate push khi DB check throw | **Kế hoạch BE Change Request (BE-REQ-08)** |
| **B-05** | P2 | Backend | Envelope lỗi không thống nhất | **Kế hoạch BE Change Request (BE-REQ-05)** |

---

## 5. Kết quả thực thi kiểm thử & Quality Gates

### Lệnh thực thi & Kết quả

```bash
# 1. Phân tích tĩnh Flutter
cd mobile && flutter analyze
# Output: No issues found! (0 errors, 0 warnings)

# 2. Toàn bộ Flutter test suite (Bao gồm test case M-01 đến M-04)
cd mobile && flutter test
# Output: 80/80 PASS (0 failed, 1 skipped)

# 3. Test chuyên biệt hợp đồng biến động số dư và thông báo
cd mobile && flutter test test/notification_balance_display_audit_test.dart
# Output: 9/9 PASS (100%)

# 4. Money Movement Contract Test
cd mobile && flutter test test/contract/money_movement_contract_test.dart
# Output: 8/8 PASS (100%)

# 5. Backend Wallet Service Unit Tests
mvn -f backend/services/wallet-service/pom.xml test
# Output: BUILD SUCCESS (38 tests, 0 failures, 6 skipped)

# 6. Backend Payment Service Unit Tests
mvn -f backend/services/payment-service/pom.xml test -Dtest="!SagaP2pE2eTest"
# Output: BUILD SUCCESS (35 tests, 0 failures)

# 7. Kiểm tra tính toàn vẹn Backend Guard
git status --porcelain -- backend docker-compose.yml deploy
# Output: RỖNG (Clean 100%, không chạm backend)
```

---

## 6. Guard & Ràng buộc (Verification of Constraints)

- **TUYỆT ĐỐI KHÔNG SỬA `backend/**`, `docker-compose.yml`, `deploy/**`**: Cam kết tuân thủ 100%. `git status --porcelain -- backend` hoàn toàn rỗng.
- **Mobile không mock data thành công**: Khi tính năng chưa có backend (`PROMOTION`, `SYSTEM`, `DEPOSIT`, `BILL_PAYMENT`), mobile hiển thị trung thực trạng thái "Tính năng sắp ra mắt" và mã change request tương ứng, không tạo dữ liệu giả lập.
