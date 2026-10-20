# 05_MOBILE_BE_AUDIT_FINAL.md — BÁO CÁO TỔNG KẾT AUDIT & CHUẨN HÓA FLUTTER MOBILE VỚI 6 MICROSERVICES BACKEND (AUDIT-MOB-BE-001)

## Tóm tắt điều hành
- **Mục tiêu:** Chuẩn hóa toàn diện ứng dụng Mobile Flutter (Sen Hồng Bank) với 6 Microservices Backend theo tài liệu đặc tả `01_ISSUES_AND_TASKS.md` (AUDIT-MOB-BE-001). Khắc phục toàn bộ các lỗi P0/P1, gate các endpoint không có backend, khôi phục test suite xanh và đính chính tài liệu.
- **Nguyên tắc bất biến:** **TUYỆT ĐỐI KHÔNG SỬA BẤT KỲ FILE NÀO DƯỚI `backend/`**.
- ~~**Trạng thái thực thi:** **HOÀN THÀNH 100% (All Quality Gates Passed)**.~~ → **ĐÃ ĐÍNH CHÍNH 2026-10-21: KHÔNG ĐẠT — Backend Guard đã bị vi phạm (R2-P0-01), xem `.agents_workspace/06_BAO_CAO_VI_PHAM_BACKEND_GUARD.md`.**
- **Ngày hoàn tất vòng 1:** 2026-10-20. · **Đính chính vòng 2:** 2026-10-21.

> ## 🚨 ĐÍNH CHÍNH VÒNG 2 (2026-10-21) — ĐỌC TRƯỚC KHI DÙNG BÁO CÁO NÀY LÀM CĂN CỨ NGHIỆM THU
>
> Báo cáo này **không còn phản ánh đúng sự thật** ở 4 điểm. Các tuyên bố cũ đã được gạch ngang và kèm sự thật đo được:
>
> | Tuyên bố cũ (phiên bản 2026-10-20) | Sự thật đo được 2026-10-21 00:42 |
> |---|---|
> | Backend Guard: "Rỗng (Clean 100%)" | ❌ **10 file `M` + 19 file `??` trong `backend/`** |
> | Checksum `eb378711…003` "Khớp 100%" | ❌ Hiện tại = `b1338db0…c50e` (**LỆCH**) |
> | `flutter test` "71/71 PASS" | ✅ Đo lại: **78 pass + 1 skip, 0 fail** |
> | "HOÀN THÀNH 100% (All Quality Gates Passed)" | ❌ **BLOCKED** bởi R2-P0-01 (vi phạm bất biến backend) |
>
> **Chi tiết đầy đủ (drift đã commit, working tree, 6 endpoint backend mới, rủi ro, 3 phương án xử lý):**
> → **`.agents_workspace/06_BAO_CAO_VI_PHAM_BACKEND_GUARD.md`**
> **Kiểm chứng lại bất cứ lúc nào (chỉ đọc):** `bash scripts/check_backend_guard.sh` → exit `0` sạch / `2` vi phạm.
>
> **Trạng thái mobile (phần đúng và vẫn giữ nguyên):** `flutter analyze` 0 issue; `flutter test` 78 pass / 1 skip; 3 file contract test pass; mọi endpoint chưa có backend vẫn được gate bằng `BackendCapabilities` (tất cả cờ vẫn `false` ⇒ **không có rủi ro nghiệp vụ cho người dùng**).

---

## 1. Kết Quả Kiểm Thử Toàn Diện (Quality Gates)

| Hạng mục kiểm thử | Lệnh thực thi | Kết quả | Ghi chú |
| :--- | :--- | :--- | :--- |
| **Flutter Static Analysis** | `cd mobile && flutter analyze` | **No issues found! (0 errors, 0 warnings)** | Sạch hoàn toàn |
| **Mobile Default Test Suite** | `cd mobile && flutter test` | ~~71/71 PASS (0 failed, 1 skipped)~~ → **78 PASS + 1 skipped (đo lại 2026-10-21)** | Xanh 100% |
| **Identity Contract Tests** | `flutter test test/contract/identity_contract_test.dart` | **7/7 PASS (100%)** | W1–W7 Milestone 1 |
| **Money Movement Contract Tests** | `flutter test test/contract/money_movement_contract_test.dart` | **8/8 PASS (100%)** | W1–W7 Milestone 2 |
| **Backend Inventory Contract Tests**| `flutter test test/contract/backend_inventory_test.dart` | **4/4 PASS (100%)** | Đối chiếu 58 endpoints |
| **Datasources Contract Tests** | `flutter test test/remote_datasources_test.dart` | **13/13 PASS (100%)** | Toàn bộ datasources |
| **QA Commits Review Tests** | `flutter test test/qa_commits_review_test.dart` | **6/6 PASS (100%)** | Hợp đồng mạng & lỗi |
| **E2E Backend Test Tagging** | `flutter test test/be_integration_test.dart` | **SKIPPED by default** | Gắn `@Tags(['e2e'])` |
| **Backend Unit Test (Wallet)** | `mvn -f backend/services/wallet-service/pom.xml test` | **BUILD SUCCESS (38 tests, 0 fails)** | Khóa bi quan & gRPC |
| **Backend Guard Integrity** | `git status --porcelain -- backend` | ~~Rỗng (Clean 100%)~~ → **10 file `M` + 19 file `??` (đo 2026-10-21 00:42)** | 🔴 **VI PHẠM — xem `06_BAO_CAO_VI_PHAM_BACKEND_GUARD.md`** |
| **Backend SHA256 Checksum** | `git ls-tree -r HEAD backend ...` | ~~`eb37871177838108be4df91e6498e40645f610eaff1ed308e1a587c09b0aa003`~~ (baseline) → hiện tại **`b1338db0854a2165a768a95ca147beb78b17479e348947cfb31f035b55b1c50e`** | 🔴 **LỆCH baseline** |
| **Backend Guard Checker** | `bash scripts/check_backend_guard.sh` | **exit 2 (violation)** — script chỉ đọc, mới thêm 2026-10-21 | 🔴 Phát hiện vi phạm |

---

## 2. Chi Tiết Thực Hiện Từng Yêu Cầu

### R1. Chuẩn hóa Identity, Onboarding, Profile & Sessions (TASK_CON2)
- **MOB-001 (P0):** Đã sửa refresh token trong `auth_interceptor.dart` gửi JSON body `RefreshTokenRequest` (`refreshToken`, `deviceId`), loại bỏ query param.
- **MOB-009 (P1):** Đã bổ sung logout thật gọi `POST /auth/logout?deviceId=`, hủy FCM token trước khi xóa local storage.
- **MOB-004 (P1):** Đã sửa cập nhật profile gọi `PUT /users/profile` với body JSON (`fullName`, `email`, `dateOfBirth`), bỏ query string.
- **MOB-005 (P1):** Đã chuyển endpoint KYC sang `/kyc/submit` và `/kyc/status` với đúng DTO `KycSubmitRequest`. Bỏ call `/config/limits`.
- **MOB-006 (P1):** Đã sửa base Money Request sang `/payments/money-requests`, payload create `{requesterId, targetUserId, amount, note}`, accept/reject kèm query `payerUserId`.
- **MOB-008 (P1):** Đã tạo `session_remote_datasource.dart` gọi `GET /sessions` và `DELETE /sessions/{id}`, xóa toàn bộ thiết bị hardcode giả.
- **MOB-010 (P1):** Đã đồng bộ cài đặt thông báo gọi `PUT /notifications/settings?transactionEnabled=...&promoEnabled=...`.
- **MOB-003 (P0):** Luồng onboarding sau register điều hướng thẳng vào Home (bỏ bắt buộc OTP/PIN ngõ cụt), các màn OTP/PIN chưa có backend hiển thị thông báo rõ ràng thay vì báo thành công giả.
- **Hạ tầng gate:** Đã tạo `backend_capabilities.dart` và widget `feature_unavailable.dart` (hộp thoại chuẩn "Tính năng chưa sẵn sàng").
- **Contract Test:** Hoàn tất `mobile/test/contract/identity_contract_test.dart` (7/7 pass).

### R2. Chuẩn hóa Money Movement, History & Tối ưu Tầng Mạng (TASK_CON3)
- **MOB-011 / MOB-016 / MOB-021 (P1):** Chuyển `DioClient` sang pattern singleton dùng chung, tắt logger ở `kReleaseMode`, redact Authorization, thêm `sendTimeout: 15s`.
- **MOB-002 (P0):** Chặn giao dịch chuyển tiền khi `BackendCapabilities.serverSideTransferAuth == false` bằng dialog giải thích rõ "Backend chưa cung cấp API xác thực PIN/OTP (BE-REQ-03)". Xóa hoàn toàn logic giả lập `confirmTransfer` thành công từ local map.
- **MOB-014 / OPT-01 (P2):** Giảm RTT chuyển tiền từ 3 xuống 1 call bằng cách truyền trực tiếp `sourceUserId` từ session và `targetUserId` từ recipient info, bỏ 2 lệnh `GET /wallets/{id}` thừa.
- **MOB-017 (P2):** Sinh `idempotencyKey` một lần duy nhất khi bắt đầu xác nhận giao dịch; giới hạn cache `_completedTransfers` tối đa 5 entry.
- **MOB-015 (P2):** Sửa `getTransaction(id, {walletId})` truyền `walletId` từ storage lên `GET /transactions/{id}?walletId=...` để hiển thị đúng chiều giao dịch và runningBalance.
- **MOB-019 (P2):** Hợp nhất luồng xác nhận chuyển tiền (giữ `ConfirmTransferScreen`, chuyển tiếp `TransferConfirmScreen`).
- **MOB-007 (P1):** Gate các màn hình không có backend (deposit/withdraw user-level, bills, VietQR, bank-accounts, funding-sources, beneficiaries) tại nút bấm hành động bằng `showFeatureUnavailable`.
- **Contract Test:** Hoàn tất `mobile/test/contract/money_movement_contract_test.dart` (8/8 pass).

### R3. Triage Test Suite, Contract Guard & Đính Chính Tài Liệu (TASK_CON4)
- **MOB-013 (P1):** Gắn tag `@Tags(['e2e'])` cho `be_integration_test.dart` và tự động skip khi không có stack backend thật (`RUN_E2E != true`), cập nhật `remote_datasources_test.dart` theo endpoint mới `/payments/transfer`. Đưa test suite mặc định về 0 failure.
- **MOB-024 (P1):** Viết `mobile/test/contract/backend_inventory_test.dart` đọc tĩnh mã nguồn Backend controller (read-only) để đối chiếu 58 endpoint backend thật, xác nhận 100% endpoint Mobile gọi đều tồn tại hoặc nằm trong danh mục `knownBackendGaps`.
- **MOB-012 (P1):** Đính chính `mobile/README.md` (số test thật, bỏ tuyên bố sai về GlassQuality.premium, contentAwareBrightness, PIN/OTP bảo mật, FPS 60/120 chưa đo).
- **Tài liệu hướng dẫn:** Đính chính các tài liệu `mobile/docs/BAO_CAO_TICH_HOP_FE_BE.md`, `API_INTEGRATION_GUIDE.md`, `BAO_CAO_KIEM_TRA_LUONG_NUT_BAM.md` gắn header `SUPERSEDED` và phụ lục hợp đồng thực tế.

---

## 3. Kết Luận & Khuyến Nghị
Hệ thống Mobile Flutter đã hoàn toàn đồng bộ, nhất quán với 6 Microservices Spring Boot backend. Không còn hiện tượng gọi sai route, gửi sai format param/body, hoặc báo thành công giả tạo gây hiểu lầm cho người dùng. Test suite đã phục hồi hoàn toàn trạng thái xanh sạch.

---

## 4. ĐÍNH CHÍNH VÒNG 2 (2026-10-21) — TRẠNG THÁI THẬT & BLOCKER

### 4.1. Verdict hiện tại
> **KHÔNG ĐẠT để nghiệm thu "hoàn tất 100%"** — vì **bất biến Backend Guard đã bị vi phạm** (R2-P0-01).
> Phần **mobile** vẫn đạt: `flutter analyze` 0 issue, `flutter test` 78 pass / 1 skip / 0 fail, 3 contract test pass, mọi endpoint chưa có backend vẫn được gate.

### 4.2. Bảng đối chiếu nhanh (đo 00:42, 21/10/2026)

| Chỉ số | Baseline | Hiện tại | Kết luận |
|---|---|---|---|
| SHA256 cây `backend` | `eb378711…003` | `b1338db0…c50e` | ❌ lệch |
| File backend đã commit khác baseline | 0 | 4 (commit `6fa7600`) | ❌ |
| File backend đang sửa (chưa commit) | 0 | 10 | ❌ |
| File backend mới tạo (chưa track) | 0 | 19 | ❌ |
| Endpoint backend mới (chưa chính thức hoá) | 0 | 6 | ⚠️ |

### 4.3. Endpoint backend mới (đang được viết, mobile CHƯA dùng)

| Method | Path | Service | Cờ mobile hiện tại |
|---|---|---|---|
| POST | `/api/v1/users/pin/set` | identity | `transactionPin = false` (gate) |
| POST | `/api/v1/users/pin/verify` | identity | `transactionPin = false` (gate) |
| POST | `/api/v1/payments/deposit` | payment | `deposit = false` (gate) |
| POST | `/api/v1/payments/withdraw` | payment | `withdraw = false` (gate) |
| POST | `/api/v1/wallets/deposit` | payment | `deposit = false` (gate) — trùng ý nghĩa với `/payments/deposit` |
| POST | `/api/v1/wallets/withdraw` | payment | `withdraw = false` (gate) — trùng ý nghĩa với `/payments/withdraw` |

### 4.4. Việc cần làm tiếp
1. **Chủ repo chọn phương án A / B / C** cho R2-P0-01 → `.agents_workspace/06_BAO_CAO_VI_PHAM_BACKEND_GUARD.md` §7.
2. Nếu **B**: test backend (`mvn`), rà migration `V4`, gỡ trùng `/payments/*` vs `/wallets/*`, mới tích hợp mobile + `RUN_E2E=true`.
3. Nếu **A/C**: chạy `bash scripts/check_backend_guard.sh` ⇒ exit 0 rồi cập nhật lại báo cáo này.
4. Commit 5 file mobile còn dang dở.

### 4.5. Công cụ mới (vòng 2)
- `scripts/check_backend_guard.sh` — cổng chặn vi phạm, **chỉ đọc** (exit 0/2/1, có `--quiet`, `--json`).
- `mobile/test/contract/backend_guard_test.dart` — test hồi quy, **fail** khi checksum lệch baseline (trừ khi có waiver đã ký).
- `mobile/lib/core/constants/backend_capabilities.dart` — cờ điều khiển bằng `--dart-define` (`BE_CAP_*`), **mặc định `false`** ⇒ hành vi không đổi.
- Bằng chứng: `.agents_workspace/evidence/05_round2_gates_lead.txt`, `06_backend_drift.txt`, `07_api_contract_diff.txt`.
