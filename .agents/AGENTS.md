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
