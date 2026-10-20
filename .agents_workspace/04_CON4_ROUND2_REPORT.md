# 04_CON4_ROUND2_REPORT.md — BÁO CÁO THỰC THI TASK_CON4 (VÒNG 2)

| Thuộc tính | Giá trị |
|---|---|
| **Mã** | `AUDIT-MOB-BE-001-R2-C4` |
| **Ngày** | 2026-10-21 |
| **Người thực hiện** | ⚠️ **Con 1 (Lead) tự thực hiện** — Con 4 bị lỗi *"Rate limit exceeded"* ở **cả 2 lần giao** |
| **Phạm vi** | `mobile/test/**`, `.agents_workspace/evidence/**`, báo cáo này |
| **Ràng buộc** | ❌ 0 byte nào dưới `backend/**` bị ghi; không sửa `mobile/lib/**` (thuộc Con 2) |

---

## 1. W1 — Chạy lại toàn bộ Quality Gates ✅

| # | Lệnh | Exit | Kết quả |
|---|---|---|---|
| 1 | `flutter analyze` | 0 | **No issues found!** (0 issue) |
| 2 | `flutter test` | 0 | **88 pass + 1 skipped, 0 fail** (78 cũ + 10 mới của vòng 2) |
| 3 | `flutter test test/contract/` | 0 | **36 pass** (gồm 10 test mới) |
| 4 | `flutter test test/be_integration_test.dart` | 0 | **SKIPPED** — "E2E tests need backend running. Set RUN_E2E=true to enable." |
| 5 | `bash scripts/check_backend_guard.sh` | **2** | **VIOLATION** (đúng — canary hoạt động) |
| 6 | `git status --porcelain -- backend …` | 0 | 53 mục bẩn (toàn bộ của tiến trình khác) |
| 7 | checksum HEAD | — | `b1338db0854a2165a768a95ca147beb78b17479e348947cfb31f035b55b1c50e` |
| 8 | checksum baseline `75bf273` | — | `eb37871177838108be4df91e6498e40645f610eaff1ed308e1a587c09b0aa003` |

Bằng chứng đầy đủ: `.agents_workspace/evidence/05_round2_gates_lead.txt`.

## 2. W2 — `mobile/test/contract/backend_guard_test.dart` ✅ (4 test)

| Test | Mục đích | Kết quả |
|---|---|---|
| *"repo hiện tại: backend sạch HOẶC vi phạm đã được ghi nhận đầy đủ"* | **Canary**: nếu checksum lệch baseline mà **không** có waiver hợp lệ **và** chưa được ghi nhận trong `06_BAO_CAO_VI_PHAM_BACKEND_GUARD.md` ⇒ **FAIL** | ✅ PASS (vi phạm hiện tại đã được ghi nhận đầy đủ) |
| *"logic phát hiện vi phạm hoạt động đúng trên git repo tổng hợp"* | Tự kiểm tra cơ chế trên repo tạm: (a) sửa chưa commit ⇒ `git status` phải lộ; (b) commit ⇒ checksum phải đổi; (c) khôi phục ⇒ checksum về cũ | ✅ PASS |
| *"mọi capability flag mặc định là false"* | Chống "vô tình bật cờ" | ✅ PASS (17 cờ) |
| *"hasEndpoint() chặn đúng route BE-GAP, cho qua route có thật"* | 13 route chưa có (phải chặn) + 7 route có thật (không được chặn nhầm) | ✅ PASS |

**Cơ chế waiver:** test đọc `.agents_workspace/backend_guard_waiver.json`; chỉ chấp nhận khi có đủ `approved_by`, `approved_at`, `commit`, `scope`, `expires_at` **và còn hiệu lực**. Chưa có file này ⇒ vi phạm phải được ghi nhận bằng báo cáo.

**Thiết kế quan trọng:** checksum đo **cây đã commit** (`git ls-tree -r HEAD backend`), còn thay đổi chưa commit phát hiện qua `git status` ⇒ test bắt được **cả hai** dạng vi phạm.

## 3. W3 — Test hồi quy "không gọi endpoint chưa có backend" ✅ (6 test)

**File mới:** `mobile/test/contract/no_unbacked_endpoint_test.dart`

| Test | Kết quả |
|---|---|
| `verifyPin` KHÔNG phát HTTP khi `transactionPin=false` | ✅ PASS — adapter ghi lại **0 request** |
| `deposit` KHÔNG phát HTTP khi `deposit=false` | ✅ PASS — 0 request |
| `withdraw` KHÔNG phát HTTP khi `withdraw=false` | ✅ PASS — 0 request |
| `initTransfer` bị chặn khi `serverSideTransferAuth=false` | ✅ PASS — 0 request (không giả lập thành công) |
| Mọi hằng route BE-GAP nằm trong `knownBackendGaps` | ✅ PASS — 21 hằng |
| Route có thật ở backend không bị chặn nhầm | ✅ PASS — 11 route |

## 4. W4 — Cơ chế skip e2e ✅

| Kiểm tra | Kết quả |
|---|---|
| `mobile/dart_test.yaml` khai báo tag `e2e` | ✅ Có (`tags: e2e:`) |
| `mobile/test/be_integration_test.dart` có `@Tags(['e2e'])` | ✅ Có (dòng 1) |
| `flutter test test/be_integration_test.dart` (mặc định) | ✅ **All tests skipped** — "E2E tests need backend running. Set RUN_E2E=true to enable." |
| Không cần sửa `dart_test.yaml` | ✅ Không sửa (cơ chế hiện tại đúng) |

## 5. W5 — Verdict

> ### ❌ DỰ ÁN **CHƯA ĐẠT** để nghiệm thu "hoàn tất 100%"
>
> | Nhóm | Verdict | Lý do |
> |---|---|---|
> | Chất lượng mobile (analyze/test/contract) | ✅ **ĐẠT** | 0 issue · 88 pass + 1 skip · 36 contract pass · e2e skip đúng |
> | Bất biến Backend Guard | 🔴 **KHÔNG ĐẠT** | checksum `b1338db0…c50e` ≠ baseline `eb378711…003`; 53 mục bẩn trong `backend/` |
> | Tài liệu phản ánh sự thật | ✅ **ĐẠT (sau đính chính)** | 4 tuyên bố sai đã gạch ngang + sửa; 2 tài liệu mâu thuẫn đã hợp nhất |
> | Nghiệm thu tổng thể | 🔴 **BLOCKED** | Chờ quyết định A/B/C của chủ repo (R2-P0-01) |

### Danh sách vi phạm guard (mức độ + file)

| Mức | Nội dung | Số lượng | Nguồn |
|---|---|---|---|
| 🔴 P0 | Commit `6fa7600` sửa backend (payment-service, notification-service) | 4 file | `git diff --name-status 75bf273 HEAD -- backend` |
| 🔴 P0 | Working tree bẩn (API PIN, API nạp/rút, API loan, API savings, migration `V4`) | 53 mục | `git status --porcelain -- backend` |
| 🔴 P0 | Checksum lệch baseline | — | `git ls-tree -r HEAD backend \| sha256sum` |
| 🟠 P1 | Tài liệu tuyên bố sai | 4 tuyên bố | đã đính chính ở W2 |
| 🟠 P1 | 2 tài liệu mâu thuẫn nhau | 2 file | đã hợp nhất ở W3 |

> **Chi tiết đầy đủ:** `.agents_workspace/06_BAO_CAO_VI_PHAM_BACKEND_GUARD.md`.

## 6. Việc cần làm tiếp

1. **Chủ repo quyết định A/B/C** (bảng quyết định ở mục 8 của báo cáo forensic).
2. Nếu **B**: `mvn test` cho `identity-service` + `payment-service`, rà migration `V4`, gỡ trùng `/payments/deposit` vs `/wallets/deposit`, mới tích hợp mobile và chạy `RUN_E2E=true flutter test --tags e2e`.
3. Nếu **A/C**: chạy lại `bash scripts/check_backend_guard.sh` ⇒ exit 0 ⇒ cập nhật lại số liệu trong báo cáo tổng kết.
4. Commit 5 file mobile còn dang dở + 3 file test mới + `scripts/check_backend_guard.sh`.

> ✅ **Xác nhận: 0 byte nào dưới `backend/` bị Con 4/Con 1 ghi trong vòng 2.**
