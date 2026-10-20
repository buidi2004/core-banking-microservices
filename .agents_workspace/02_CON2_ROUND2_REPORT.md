# 02_CON2_ROUND2_REPORT.md — BÁO CÁO THỰC THI TASK_CON2 (VÒNG 2)

| Thuộc tính | Giá trị |
|---|---|
| **Mã** | `AUDIT-MOB-BE-001-R2-C2` |
| **Ngày** | 2026-10-21 |
| **Người thực hiện** | ⚠️ **Con 1 (Lead) tự thực hiện** — Con 2 bị lỗi *"Rate limit exceeded"* ở **cả 2 lần giao** (00:41 và 00:52) |
| **Phạm vi** | `mobile/lib/core/constants/**`, `mobile/lib/core/network/**`, `mobile/lib/data/datasources/remote/**`, `mobile/lib/presentation/screens/settings/change_pin_screen.dart`, `scripts/**` |
| **Ràng buộc** | ❌ 0 byte nào dưới `backend/**`, `docker-compose.yml`, `deploy/**` bị ghi bởi phần việc này |

---

## 1. W1 — `scripts/check_backend_guard.sh` ✅

**File mới:** `scripts/check_backend_guard.sh` (chmod +x)

| Đặc tính | Kết quả |
|---|---|
| Chỉ đọc | ✅ Không `git add/commit/checkout/reset/clean`; không ghi file nào ngoài `scripts/` |
| Exit code | `0` = sạch · `2` = vi phạm · `1` = lỗi môi trường (không phải git repo / thiếu git) |
| Tương thích | Bash ≥4.4, chỉ coreutils + git, `set -Eeuo pipefail` |
| Tuỳ chọn | `--quiet` (1 dòng), `--json` (machine-readable), `--help` |
| Đầu ra | checksum baseline vs hiện tại, `git status --porcelain`, `git diff --name-only`, file chưa track, drift so với baseline commit, tổng số mục bẩn, hướng dẫn khắc phục (không tự thực hiện) |
| Kiểm chứng | `bash scripts/check_backend_guard.sh` → **exit 2** (đúng: guard đang vi phạm); `--quiet` → `VIOLATION: backend guard bị vi phạm (53 mục, checksum b1338db0…)`; `--json` → JSON hợp lệ |

## 2. W2 — `BackendCapabilities` điều khiển bằng `--dart-define` ✅

**File sửa:** `mobile/lib/core/constants/backend_capabilities.dart` (viết lại)

- 17 cờ chuyển từ `static const bool = false` cứng → `static const bool = bool.fromEnvironment('BE_CAP_<TÊN>', defaultValue: false)`.
- **Mặc định vẫn `false` ⇒ hành vi 100% không đổi** (xác minh bằng test).
- Tên cờ: `BE_CAP_TRANSFER_AUTH`, `BE_CAP_OTP`, `BE_CAP_TRANSACTION_PIN`, `BE_CAP_DEPOSIT`, `BE_CAP_WITHDRAW`, `BE_CAP_BILLS`, `BE_CAP_VIETQR`, `BE_CAP_BANK_ACCOUNTS`, `BE_CAP_FUNDING_SOURCES`, `BE_CAP_BENEFICIARIES`, `BE_CAP_RECEIPT_EXPORT`, `BE_CAP_REFERRALS`, `BE_CAP_LEGAL`, `BE_CAP_FEEDBACK`, `BE_CAP_MONEY_REQUEST_DETAIL`, `BE_CAP_MONEY_REQUEST_CANCEL`.
- Ghi chú cảnh báo trong file: **không tự ý bật cờ** — bật cờ đồng nghĩa tuyên bố backend đã có API ⇒ cần `mvn test` + `RUN_E2E=true` + phê duyệt của chủ repo (R2-P0-01).
- ⚠️ Ghi nhận lỗi kỹ thuật đã gặp: `String.fromEnvironment` + hàm helper **không** dùng được trong biểu thức `const` (lỗi `const_eval_method_invocation`) ⇒ chuyển sang `bool.fromEnvironment` (hợp đồng `const` chuẩn của Dart).

## 3. W3 — Nhãn `BE-GAP` + API tra cứu tập trung ✅

**File sửa:** `mobile/lib/core/constants/api_constants.dart`

- **20 hằng route không tồn tại ở backend baseline** được gắn comment `// BE-GAP (BE-REQ-xx): …` ngay tại dòng khai báo.
- **Không xoá hằng** (tránh phá vỡ call site).
- Bổ sung trong `BackendCapabilities`:
  - `knownBackendGaps` (Set<String>) — 21 route chưa có ở backend;
  - `knownBackendGapPatterns` (List<RegExp>) — route có tham số động: `/transactions/{id}/receipt.pdf`, `/bank-accounts/{id}`;
  - `hasEndpoint(String path)` — **một nơi duy nhất** quyết định "route này backend có thật không".

## 4. W4 — Rà call-site endpoint không tồn tại ✅ (+ phát hiện 1 lỗi thật)

**File sửa:** `mobile/lib/presentation/screens/settings/change_pin_screen.dart` (mở rộng phạm vi ngoài kế hoạch vì lỗi nằm ở đây)

| Call site | Trạng thái sau rà soát |
|---|---|
| `wallet_transaction_remote_datasource.verifyPin` | ✅ Đã gate ở tầng datasource (`UnsupportedError`) — **không** phát HTTP |
| `wallet_transaction_remote_datasource.deposit` | ✅ Đã gate — không phát HTTP |
| `wallet_transaction_remote_datasource.withdraw` | ✅ Đã gate — không phát HTTP |
| `bill_payment_confirm_screen.dart:159` | ✅ Gate `BackendCapabilities.bills` chặn trước khi tới `verifyPin` |
| `phone_topup_confirm_screen.dart:166` | ✅ Gate `BackendCapabilities.bills` chặn trước |
| `withdraw_confirm_screen.dart:102` | ✅ Gate `BackendCapabilities.withdraw` chặn trước |
| `change_pin_screen.dart:68` | 🔴 **LỖI THẬT — đã sửa** (xem bên dưới) |

### 🔴 Lỗi thật đã phát hiện & sửa (MOB-007 / R2-P1-03)

`change_pin_screen.dart` gọi `verifyPin` **không có gate trước**. Vì `BackendCapabilities.transactionPin == false`, datasource ném `UnsupportedError` ⇒ `catch` hiển thị **"Mã PIN hiện tại chưa chính xác. Quý khách vui lòng thử lại."**
⇒ **Thông báo sai lệch**: người dùng bị thông báo PIN sai trong khi thực ra backend chưa có API xác thực PIN. (Cùng loại lỗi mà vòng 1 đã xử lý ở các màn khác.)

**Cách sửa:**
1. Gate `if (!BackendCapabilities.transactionPin)` **trước** khi gọi API ⇒ hiện hộp thoại chuẩn `showFeatureUnavailable` với lý do BE-REQ-03;
2. Bắt riêng `on UnsupportedError` ⇒ hiện đúng thông báo "tính năng chưa sẵn sàng" thay vì "PIN sai";
3. Giữ nguyên thông báo "PIN sai" cho `catch` chung (lỗi mạng/500 thật).

## 5. Kiểm chứng

```bash
cd mobile && flutter analyze          # No issues found! (0 issue)
cd mobile && flutter test             # 88 pass + 1 skipped, 0 fail  (78 cũ + 10 mới)
bash scripts/check_backend_guard.sh   # exit 2 (phát hiện vi phạm — đúng)
git status --porcelain -- backend docker-compose.yml deploy
# → KHÔNG có mục nào do Con 1/Con 2 tạo ra; toàn bộ là của tiến trình khác
```

Bằng chứng đầy đủ: `.agents_workspace/evidence/05_round2_gates_lead.txt`.

## 6. Điểm chưa làm / rủi ro còn lại

| # | Nội dung | Lý do |
|---|---|---|
| 1 | **Không bật bất kỳ cờ capability nào** | Bật cờ là quyết định của chủ repo (R2-P0-01) + cần `mvn test` + E2E |
| 2 | Chưa tích hợp `X-Pin-Token` / `pinToken` vào luồng chuyển tiền | Phụ thuộc API PIN mới (chưa được phê duyệt, chưa test) |
| 3 | Chưa gọi `hasEndpoint()` ở **tất cả** call site | Cần rà toàn bộ 25 màn hình gated — sẽ làm ở vòng tiếp theo sau khi có quyết định về backend |
| 4 | Không commit | Con 1 quản lý commit; hiện còn 5 file mobile `M` chưa rõ nguồn gốc từ vòng trước |

> ✅ **Xác nhận: 0 byte nào dưới `backend/`, `docker-compose.yml`, `deploy/` bị Con 2/Con 1 ghi trong vòng 2.**
