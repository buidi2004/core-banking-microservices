# AI Agent Rules for EWallet Project

---
## 🔌 MCP: codebase-memory-mcp
- **Mục đích:** Đọc hiểu đồ thị mã nguồn dự án.
- **Rule:** Ưu tiên dùng `search_graph` và `trace_path` thay vì grep hay tìm kiếm thủ công.

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

