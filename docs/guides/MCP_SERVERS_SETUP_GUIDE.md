# HƯỚNG DẪN CẤU HÌNH & VẬN HÀNH TOÀN DIỆN BỘ MCP SERVERS CHO JAVA MICROSERVICES

> **Mục tiêu:** Trang bị đầy đủ các Model Context Protocol (MCP) servers chuẩn mực cho trợ lý AI (Antigravity, Cursor, Claude Desktop, VS Code Cline/Roo Code) để hiểu sâu sắc cây mã nguồn đa module Maven, quản lý Pull Requests, truy vấn trực tiếp CSDL phân tán (Database-per-Service), giám sát hạ tầng Docker và tra cứu tài liệu OpenAPI/Swagger.

---

## 1. Bản đồ tổng thể 5 nhóm MCP Servers (11 Servers Sẵn Sàng)

| Nhóm | Tên Server | Giao thức / Package | Vai trò & Khả năng của AI |
| :--- | :--- | :--- | :--- |
| **1. Dart & Flutter Chuyên Dụng** | `dart-flutter-analyzer` | Local Native MCP Server | Chạy `flutter analyze`, `flutter test`, quét Memory Leak (`dispose()`), thanh tra Widget chuẩn Anti-Slop (Liquid Glass, Bottom Bar 110dp, Tabular Figures) |
| **2. Mã nguồn & Cấu trúc** | `filesystem` | `@modelcontextprotocol/server-filesystem` | Đọc, ghi, tìm kiếm file, duyệt cấu trúc multi-module `pom.xml` |
| | `github` | `@modelcontextprotocol/server-github` | Quản lý PRs, Issues, commits, branch, xem log CI/CD |
| | `graphify` | `graphify-mcp` | Đồ thị tri thức AST (10.405 nodes, 495 communities) |
| | `codebase-memory` | `codebase-memory-mcp` | Bộ nhớ ngữ nghĩa, truy vết luồng gọi hàm giữa các service |
| **3. Cơ sở Dữ liệu** | `postgres-ledger` | `@modelcontextprotocol/server-postgres` | Truy vấn Sổ cái kép (`ewallet_ledger_db`:5436) |
| | `postgres-payment` | `@modelcontextprotocol/server-postgres` | Tra cứu giao dịch nạp quầy, Saga (`ewallet_payment_db`:5435) |
| | `postgres-wallet` | `@modelcontextprotocol/server-postgres` | Tra cứu số dư ví, pessimistic lock (`ewallet_wallet_db`:5434) |
| | `postgres-identity` | `@modelcontextprotocol/server-postgres` | Tra cứu users, KYC, pin, staff (`ewallet_identity_db`:5433) |
| **4. Hạ tầng & DevOps** | `docker` | `mcp-server-docker` | Giám sát 18 containers, xem log, inspect, restart container |
| **5. API & Tích hợp** | `openapi` | `openapi-mcp-server` | Tra cứu đặc tả OpenAPI/Swagger từ các service live |

---

## 2. Các vị trí cấu hình đồng bộ trong dự án

Bộ cấu hình JSON đã được thiết lập tự động tại 5 vị trí:
1. **Antigravity Workspace:** `.agents/mcp_config.json`
2. **Antigravity Global:** `~/.gemini/config/mcp_config.json`
3. **Cursor IDE:** `.cursor/mcp.json`
4. **VS Code (Cline / Roo Code / Continue):** `.vscode/mcp.json`
5. **Claude Desktop:** `~/.config/Claude/claude_desktop_config.json`

---

## 3. Chi tiết cấu hình JSON (Chuẩn Stdio Transport)

```json
{
  "mcpServers": {
    "dart-flutter-analyzer": {
      "command": "node",
      "args": [
        "/home/buidi/Tài liệu/core-banking-microservices/.agents/servers/dart-flutter-mcp/server.js"
      ]
    },
    "codebase-memory": {
      "command": "npx",
      "args": [
        "-y",
        "codebase-memory-mcp"
      ]
    },
    "graphify": {
      "command": "/home/buidi/.local/bin/graphify-mcp",
      "args": [
        "/home/buidi/Tài liệu/core-banking-microservices/graphify-out/graph.json"
      ]
    },
    "filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "/home/buidi/Tài liệu/core-banking-microservices"
      ]
    },
    "github": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-github"
      ],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": ""
      }
    },
    "docker": {
      "command": "/home/buidi/.local/bin/mcp-server-docker",
      "args": []
    },
    "postgres-ledger": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-postgres",
        "postgresql://ledger_app_user:LedgerApp%23Secure2025%21@localhost:5436/ewallet_ledger_db"
      ]
    },
    "postgres-payment": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-postgres",
        "postgresql://payment_db_user:PaymentDb%23Secure2025%21@localhost:5435/ewallet_payment_db"
      ]
    },
    "postgres-wallet": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-postgres",
        "postgresql://wallet_db_user:WalletDb%23Secure2025%21@localhost:5434/ewallet_wallet_db"
      ]
    },
    "postgres-identity": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-postgres",
        "postgresql://identity_db_user:IdentityDb%23Secure2025%21@localhost:5433/ewallet_identity_db"
      ]
    },
    "openapi": {
      "command": "npx",
      "args": [
        "-y",
        "openapi-mcp-server",
        "http://localhost:8900/openapi.json"
      ]
    }
  }
}
```

---

## 4. Quy tắc an toàn bắt buộc khi AI sử dụng MCP

1. **Quy tắc Cơ sở dữ liệu (PostgreSQL):**
   * Mọi câu lệnh truy vấn dữ liệu từ AI **BẮT BUỘC** phải có mệnh đề `LIMIT 50`.
   * **NGHIÊM CẤM** chạy các câu lệnh phá hủy cấu trúc như `DROP`, `TRUNCATE` hoặc `DELETE` hàng loạt.
   * Ký tự đặc biệt trong mật khẩu DB (ví dụ `#` $\rightarrow$ `%23`, `!` $\rightarrow$ `%21`) đã được URL-encode chuẩn xác để không bị ngắt kết nối.
2. **Quy tắc GitHub:**
   * Khi tạo Pull Request, bắt buộc liệt kê danh sách file đã thay đổi và tóm tắt rủi ro.
   * Để kích hoạt đầy đủ tính năng GitHub MCP, hãy điền GitHub Personal Access Token vào biến `GITHUB_PERSONAL_ACCESS_TOKEN`.
3. **Quy tắc Hạ tầng Docker:**
   * Sử dụng để tra cứu trạng thái và xem log khi kiểm thử lỗi runtime, tránh tùy tiện restart cụm cơ sở dữ liệu khi hệ thống đang xử lý giao dịch.

