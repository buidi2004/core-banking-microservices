# Hướng Dẫn Vận Hành Hệ Thống 15 Con OpenCode (Dùng Model Free & Chống Rate Limit)

> [!NOTE]
> Hệ thống đã được nâng cấp từ 5 con lên **15 con OpenCode độc lập** (`con1` đến `con15`). Toàn bộ 15 con đều hoạt động trên thư mục cấu hình, cache, SQLite DB riêng biệt và tận dụng kho **9 Model Free** tích hợp sẵn của OpenCode kèm cơ chế tự động luân chuyển chống Rate Limit.

---

## 1. Danh Sách 15 Con OpenCode & Phân Bổ Model Free

| Lệnh gọi | Vai trò chuyên biệt | Model Free mặc định | Thư mục Profile |
| :--- | :--- | :--- | :--- |
| **`con1`** | Con 1 [Lead Architect & Planner] | `opencode/minimax-m3.1-flash-free` | `~/.opencode_profiles/con1` |
| **`con2`** | Con 2 [Worker 1: Identity & Auth] | `opencode/nemotron-3.5-lightning-free` | `~/.opencode_profiles/con2` |
| **`con3`** | Con 3 [Worker 2: Money & Network] | `opencode/longcat-2.5-preview-free` | `~/.opencode_profiles/con3` |
| **`con4`** | Con 4 [Worker 3: QA & Tests] | `opencode/nemotron-3-ultra-free` | `~/.opencode_profiles/con4` |
| **`con5`** | Con 5 [Reviewer & Docs] | `opencode/deepseek-v4.1-flash-free` | `~/.opencode_profiles/con5` |
| **`con6`** | Con 6 [Worker 4: UI & Styling] | `opencode/glm-5.3-flash-free` | `~/.opencode_profiles/con6` |
| **`con7`** | Con 7 [Worker 5: Business Logic] | `opencode/mimo-v2.6-flash-free` | `~/.opencode_profiles/con7` |
| **`con8`** | Con 8 [Worker 6: Database & Cache] | `opencode/beam-free` | `~/.opencode_profiles/con8` |
| **`con9`** | Con 9 [Worker 7: Security & Guard] | `opencode/nemotron-3.5-super-vl-free` | `~/.opencode_profiles/con9` |
| **`con10`** | Con 10 [Explorer & Research] | `opencode/longcat-2.5-preview-free` | `~/.opencode_profiles/con10` |
| **`con11`** | Con 11 [Optimizer & Refactor] | `opencode/nemotron-3.5-lightning-free` | `~/.opencode_profiles/con11` |
| **`con12`** | Con 12 [Security Auditor] | `opencode/minimax-m3.1-flash-free` | `~/.opencode_profiles/con12` |
| **`con13`** | Con 13 [Integration Tester] | `opencode/nemotron-3-ultra-free` | `~/.opencode_profiles/con13` |
| **`con14`** | Con 14 [Load & Benchmark] | `opencode/glm-5.3-flash-free` | `~/.opencode_profiles/con14` |
| **`con15`** | Con 15 [Release & Summary] | `opencode/deepseek-v4.1-flash-free` | `~/.opencode_profiles/con15` |

*(Bạn cũng có thể gọi bằng alias: `opencode1` đến `opencode15`).*

---

## 2. Cơ Chế Chống Rate Limit Bằng "Vòng Xoay 9 Model Free"

Mỗi khi chạy tự động (`conX run --auto "..."`), script `opencode-instance` sẽ kích hoạt **Model Pool** gồm cả 9 model free:
1. `opencode/minimax-m3.1-flash-free`
2. `opencode/nemotron-3.5-lightning-free`
3. `opencode/longcat-2.5-preview-free`
4. `opencode/nemotron-3-ultra-free`
5. `opencode/deepseek-v4.1-flash-free`
6. `opencode/glm-5.3-flash-free`
7. `opencode/mimo-v2.6-flash-free`
8. `opencode/beam-free`
9. `opencode/nemotron-3.5-super-vl-free`

> [!TIP]
> **Tự động Fallback:** Nếu Model chính của bot bị chạm trần Rate Limit (HTTP 429), bot sẽ **tự động chuyển sang model free tiếp theo** trong danh sách mà không bị crash hay gián đoạn phiên làm việc.

---

## 3. Cách Đăng Nhập Tài Khoản Riêng Cho Từng Con (Nếu Muốn)

Nếu bạn có nhiều tài khoản GitHub / OpenCode hoặc muốn cấp tài khoản riêng:
```bash
con1 auth login
con2 auth login
...
con15 auth login
```
Mỗi tài khoản sẽ lưu trong profile độc lập tương ứng, không bị ghi đè.

---

## 4. Cách Quản Trị & Giám Sát

- **Bảng Dashboard giám sát trực quan:**
  ```bash
  opencode-monitor
  ```
- **Tắt khẩn cấp toàn bộ các con:**
  ```bash
  pkill -f opencode
  ```
