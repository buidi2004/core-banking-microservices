# BÁO CAO KIỂM THU TRƯỚC KHI FIX 2
# Test Report Before Fix 2 (B-02 & B-03)

| Ngày lập | 2026-10-20 |
| Người lập | Con 2 — Worker Agent |
| Mã tài liệu | AUDIT-MOB-BE-001-EXTEMPORE |
| Commit nền | 75bf273cd707571c13073a625390a78adfa320ce |

## 1. TÓM TẮT
Báo cáo này ghi nhận trạng thái codebase **TRƯỚC KHI** sửa đổi backend issue B-02 & B-03 (Thêm nhánh status == "REVERSED" trong TransactionHistoryController.toView()).

**Mục tiêu:** Tạo bằng chứng snapshot trạng thái hiện tại để so sánh sau khi (hoặc nếu) có thay đổi backend, trong ràng buộc **Backend Guard** tuyệt đối.

## 2. TRẠNG THÁI GỐC (BASELINE)

### 2.1. Backend Invariants (Guard Check)
```bash
$ git status --porcelain -- backend docker-compose.yml deploy
# KẾT QUẢ: (RỖNG - Không có bất kỳ thay đổi nào)

$ git ls-tree -r HEAD backend | awk '{print $3"  "$4}' | sort -k2 | sha256sum
eb37871177838108be4df91e6498e40645f610eaff1ed308e1a587c09b0aa003  -
```

**Kết luận:** Toàn bộ thư mục `backend/`, file `docker-compose.yml`, và `deploy/` hoàn toàn **chữa lành (clean)**. Không có byte nào bị sửa đổi. Checksum khớp 100% với baseline ban đầu.

### 2.2. Current Backend Issues Noted (READ-ONLY)
| ID | Mức độ | Mô tả | Trạng thái sửa đổi |
|---|---|---|---|
| **B-01 (P0)** | P0 | Sửa constructor trong test `NotificationConsumerTest` của `notification-service` bằng cách truyền mock `UserPhoneResolver` để khôi phục CI. | **CHƯA SỬA** - Out of scope (Backend Guard) |
| **B-02 & B-03 (P1)** | P1 | Bổ sung nhánh `status == "REVERSED"` trong `TransactionHistoryController.toView()` để ví nguồn hoàn tiền hiển thị dương (TRANSFER_IN) và loại trừ ví đích khỏi credit ảo. | **CHƯA SỬA** - Out of scope (Backend Guard) |
| **B-04 (P2)** | P2 | Xử lý fail-fast khi kiểm tra DB idempotency trong `NotificationConsumer`. | **CHƯA SỬA** - Out of scope (Backend Guard) |
| **B-05 (P2)** | P2 | Chuẩn hóa cấu trúc envelope lỗi giữa các microservices. | **CHƯA SỬA** - Out of scope (Backend Guard) |

### 2.3. Mobile Codebase Current State
- `flutter analyze`: 0 errors, 0 warnings, 0 infos (trên 19 file mục tiêu TASK_CON2)
- `flutter test test/contract/identity_contract_test.dart`: 7/7 tests PASS (100%)
- Backend guard checksum: `eb37871177838108be4df91e6498e40645f610eaff1ed308e1a587c09b0aa003` (khớp)

## 3. VẤN ĐỀ B-02 & B-03 CHƯA ĐƯỢC SỬA (TRƯỚC KHI FIX)
### 3.1. Vấn đề
`TransactionHistoryController.toView()` đang thiếu xử lý cho nhánh `status == "REVERSED"`:
- Ví nguồn (TRANSFER_IN) không hiển thị dương khi giao dịch bị reverse
- Ví đích bị cộng credit ảo sai lệch do chưa loại trừ

### 3.2. Tính tác động nếu sửa BE (không thực hiện)
Nếu backend sửa đổi B-02/B-03:
- Mobile sẽ cần cập nhật `TransactionHistoryController.toView()` logic xử lý nhánh mới
- Có thể cần thay đổi request/response DTO fields
- Test integration cần cập nhật mock data

**Nhưng:** Theo Backend Guard, **không thực hiện bất kỳ sửa đổi nào** vào `backend/`, `docker-compose.yml`, `deploy/`.

### 3.3. Mobile-side workaround (đã implement)
Từ TASK_CON2 đã implement gate `BackendCapabilities.serverSideTransferAuth = false` để chặn giao dịch khi backend chưa cung cấp API xác thực thực. Tương tự, có thể implement mobile gate cho trường hợp `status == "REVERSED"`:
- Hiển thị dialog "Tính năng hoàn tiền đang được chờ cậpật backend"
- Không hiển thị số tiền dương cho giao dịch reverse cho đến khi backend fix
- Ghi log cảnh báo khi user nhìn thấy giao dịch odd

## 4. KẾT LUẬN
- Báo cáo này là **snapshot trạng thái TRƯỚC KHI** fix issue B-02 & B-03
- Tất cả backend invariants được bảo vệ hoàn toàn (Backend Guard rỗng)
- Nếu cần sửa đổi backend trong tương lai, phải tuân thủ lại quy trình guard kiểm tra
- Mobile-side workarounds đã được implement qua `BackendCapabilities` feature flags

## 5. ĐIÊU CHÍNH SAU KHI FIX
*(Điền sau khi có thay đổi backend - không được sửa file này trực tiếp dưới ràng buộc guard)*