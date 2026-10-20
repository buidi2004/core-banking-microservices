# AI Agent Rules for EWallet Project

---
## 🚨 NGUYÊN TẮC BẮT BUỘC SỐ 1: CODEBASE MEMORY MCP (GRAPH-FIRST ENGINE)
> [!IMPORTANT]
> **AI AGENT PHẢI LUÔN SỬ DỤNG `codebase-memory-mcp` ĐẦU TIÊN KHI ĐỌC, TÌM KIẾM HOẶC PHÂN TÍCH MÃ NGUỒN.**
> - **CẤM:** Tuyệt đối không dùng `grep`, `find`, `cat` bừa bãi hoặc đọc toàn bộ file lớn gây quá tải context window.
> - **BẮT BUỘC:** Mọi thao tác tìm class, interface, method, route, model, luồng gọi hàm, hoặc khảo sát kiến trúc PHẢI gọi công cụ MCP Graph trước.

### 📌 Phân vùng dự án (Bắt buộc truyền tham số `project`):
1. **`core-banking-backend`**: Dành cho mã nguồn Backend Java 17 / Spring Boot 3 (`backend/`):
   - 6 Microservices: `api-gateway`, `identity-service`, `wallet-service`, `payment-service`, `ledger-service`, `notification-service`.
   - `common-library` (Protobuf, gRPC, Events, DTOs).
2. **`core-banking-mobile`**: Dành cho ứng dụng Mobile Flutter (`mobile/`):
   - Clean Architecture, 50+ Screens, BLoC/Cubit, Repositories, Liquid Glass UI.

### 🛠️ Thứ tự ưu tiên sử dụng MCP Tools (Bắt buộc tuân thủ):
1. `search_graph(project, query/name_pattern)`: Tìm kiếm symbol (class, method, route, model, controller).
2. `trace_path(project, function_name, direction)`: Lần theo luồng gọi hàm (`inbound` = ai gọi, `outbound` = hàm này gọi ai, `both` = cả hai).
3. `get_code_snippet(project, qualified_name)`: Lấy chính xác đúng đoạn code cần đọc/sửa thay vì đọc cả file.
4. `get_file_outline(project, file_path)`: Xem cấu trúc/dàn ý của file trước khi can thiệp.
5. `get_architecture(project, aspects)`: Khảo sát kiến trúc module/service.

### ⚠️ Trường hợp ngoại lệ duy nhất được fallback sang grep/cat:
- Tìm chuỗi ký tự cố định trong file cấu hình (`.yml`, `.properties`, `.env`, `.sql`).
- Tìm chuỗi thông báo lỗi hardcoded literal.
- Sau khi `search_graph` xác nhận không có symbol trong đồ thị AST.

---
## 🔌 MCP: postgres-database-mcp
- **Mục đích:** Truy vấn cơ sở dữ liệu.
- **Rule:** Khi chạy query, luôn giới hạn `LIMIT 50`. Không chạy lệnh DROP hay DELETE.

---
## 🔌 MCP: github-mcp
- **Mục đích:** Quản lý pull request và issues.
- **Rule:** Khi tạo Pull Request, bắt buộc phải liệt kê các file đã thay đổi.

---
## 🎨 Agent Skill: Archify (Sơ đồ hệ thống tương tác)
- **Vị trí Skill:** `.agents/skills/archify` (và global `~/.gemini/config/skills/archify`).
- **Mục đích:** Tự động tạo sơ đồ kiến trúc, quy trình, luồng dữ liệu, lifecycle và sequence diagrams tương tác dạng HTML (inline SVG, dark/light themes, motion, export PNG/SVG/WebM).
- **Các loại sơ đồ hỗ trợ:**
  - `architecture`: Kiến trúc hệ thống, microservices, cloud/infrastructure boundaries.
  - `workflow`: Quy trình nghiệp vụ, phê duyệt, CI/CD, runbooks.
  - `sequence`: Tuần tự gọi API, luồng giao dịch E-Wallet, lifecycle request.
  - `dataflow`: Luồng xử lý dữ liệu, streaming, pipeline ETL.
  - `lifecycle`: Vòng đời trạng thái đối tượng (giao dịch, ví, tài khoản).
- **Quy tắc làm việc:**
  1. Đọc schema tương ứng tại `.agents/skills/archify/schemas/` và file mẫu tại `.agents/skills/archify/examples/`.
  2. Tạo file JSON đặc tả (JSON-IR) với `meta.quality_profile = "showcase"`.
  3. Xác thực bằng lệnh: `archify validate <type> <spec.json> --quality showcase --json` (yêu cầu 0 errors, 0 warnings).
  4. Xuất file HTML tương tác: `archify deliver <type> <spec.json> <output.html> --quality showcase --json`.
  5. Khi user cần xem thương hiệu/công nghệ, có thể tra cứu nhanh: `archify brands "<tên>" --json`.

