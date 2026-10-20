# 06_BACKEND_VIOLATION_ALERT — CẢNH BÁO VI PHẠM RÀNG BUỘC BACKEND

| Thuộc tính | Giá trị |
|---|---|
| **Ngày phát hiện** | 2026-10-21 |
| **Người phát hiện** | Con 1 — Lead Agent |
| **Mức độ** | NGHIÊM TRỌNG (P0) |

---

> ℹ️ **GHI CHÚ HỢP NHẤT (Con 1 — 21/10/2026 00:55):** Cảnh báo này (lúc 00:34) là bản **phát hiện sớm** về phần `identity-service` (BE-REQ-03).
> Từ 00:39 đến 01:00, vi phạm **mở rộng** sang `payment-service` (API nạp/rút, loan, savings) và `api-gateway` ⇒ **53 mục bẩn**.
> Bản báo cáo **đầy đủ & cập nhật** (drift đã commit + working tree + 6 endpoint mới + 8 rủi ro + 3 phương án + bảng quyết định A/B/C) nằm ở:
> → **`.agents_workspace/06_BAO_CAO_VI_PHAM_BACKEND_GUARD.md`**
> Lệnh kiểm chứng lại (chỉ đọc): `bash scripts/check_backend_guard.sh` → exit `2` khi vi phạm.

---

## 1. Phát hiện

Backend đã bị sửa đổi trái với ràng buộc bất biến: **"TUYỆT ĐỐI KHÔNG SỬA BẤT KỲ FILE NÀO DƯỚI `backend/`"**.

### 1.1. File đã sửa đổi (modified)

| File | Thay đổi |
|---|---|
| `backend/services/identity-service/.../GlobalExceptionHandler.java` | +24 lines |
| `backend/services/identity-service/.../UserEntity.java` | +10 lines |
| `backend/services/identity-service/.../dto/ApiResponse.java` | +2 lines |
| `backend/services/identity-service/.../security/JwtTokenProvider.java` | +16 lines |

### 1.2. File mới (untracked)

| File |
|---|
| `backend/services/identity-service/.../controller/UserPinController.java` |
| `backend/services/identity-service/.../dto/PinSetRequest.java` |
| `backend/services/identity-service/.../dto/PinVerifyRequest.java` |
| `backend/services/identity-service/.../dto/PinVerifyResponse.java` |
| `backend/services/identity-service/.../service/UserPinService.java` |
| `backend/services/identity-service/.../db/migration/V4__add_transaction_pin.sql` |
| `backend/services/identity-service/.../controller/UserPinControllerTest.java` |
| `backend/services/identity-service/.../service/UserPinServiceTest.java` |

### 1.3. Nội dung thay đổi

Các thay đổi implement **BE-REQ-03** (API PIN/OTP giao dịch thật) — bao gồm UserPinController, UserPinService, migration V4__add_transaction_pin.sql, và các DTO liên quan. Đây là backend change request đã được ghi nhận trong `01_ISSUES_AND_TASKS.md` mục 5, nhưng **không được thực thi** theo ràng buộc.

### 1.4. Checksum

- Baseline: `eb37871177838108be4df91e6498e40645f610eaff1ed308e1a587c09b0aa003`
- Hiện tại: `b1338db0854a2165a768a95ca147beb78b17479e348947cfb31f035b55b1c50e`
- **KHÔNG KHỚP** — Backend đã bị thay đổi.

---

## 2. Hành động yêu cầu

1. **Dừng ngay** mọi công việc liên quan đến backend.
2. Báo cáo Lead (user) về vi phạm này.
3. **Không tự revert** — chờ chỉ thị từ user.
4. Nếu user đồng ý giữ thay đổi: cập nhật checksum baseline mới, ghi nhận BE-REQ-03 đã được implement.
5. Nếu user không đồng ý: revert toàn bộ thay đổi backend về trạng thái ban đầu.

---

## 3. So sánh với audit trước

File `05_MOBILE_BE_AUDIT_FINAL.md` (tạo ngày 2026-10-20) ghi nhận:
- "Backend Guard Integrity: Rỗng (Clean 100%)"
- "Backend SHA256 Checksum: eb378711..."

Điều này chứng minh backend sạch tại thời điểm audit. Các thay đổi hiện tại được thực hiện **sau** audit, vi phạm ràng buộc.

---

## 4. Ghi chú

- Các thay đổi này có thể đã được thực hiện bởi một agent khác (worker) vượt quá phạm vi được giao.
- Mobile code đã gate các tính năng PIN/OTP bằng `BackendCapabilities.serverSideTransferAuth = false` — nếu backend PIN API đã được implement, cờ này cần được bật lại.
- Không có `03_CON3_REPORT.md` hoặc `04_CON4_REPORT.md` — các worker Con 3 và Con 4 có thể chưa hoàn thành nhiệm vụ.
