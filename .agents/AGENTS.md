# AI Agent Rules for EWallet Project

---
## 📖 HƯỚNG DẪN KHỞI TẠO MÔI TRƯỜNG DỰ ÁN (BE, FE, MOBILE)
> [!TIP]
> Chi tiết toàn bộ quy trình thiết lập môi trường từ zero, tải dependencies, chạy 14 Docker containers, 6 Microservices, Web Portal và Flutter Mobile được ghi chép đầy đủ tại:
> 👉 [ENVIRONMENT_SETUP_GUIDE.md](file:///home/buidi/core-banking-microservices/.agents/ENVIRONMENT_SETUP_GUIDE.md)

---
## 🚨 NGUYÊN TẮC BẮT BUỘC SỐ 1: GRAPHIFY KNOWLEDGE GRAPH ENGINE (ƯU TIÊN TUYỆT ĐỐI)
> [!IMPORTANT]
> **DỰ ÁN TÍCH HỢP TOÀN DIỆN GRAPHIFY (https://github.com/Graphify-Labs/graphify.git) LÀM CƠ SỞ TRI THỨC VÀ ĐỒ THỊ AST ƯU TIÊN SỐ 1.**
> - **CẤM:** Tuyệt đối không dùng `grep`, `find`, `cat` bừa bãi hoặc đọc toàn bộ file lớn gây quá tải context window.
> - **BẮT BUỘC:** Mọi thao tác tìm hiểu nghiệp vụ, kiến trúc, tìm class, interface, method, route, model, luồng gọi hàm giữa 6 Microservices, Web Portal và Mobile PHẢI tra cứu qua đồ thị **Graphify** trước.
> - **Đồ thị cục bộ:** 7.801 nodes · 17.525 edges · 315 communities trích xuất offline 100% bằng Tree-sitter (0 token, bảo mật tuyệt đối).

### 🛠️ Bộ lệnh Graphify ưu tiên sử dụng (Bắt buộc tuân thủ):
1. **Truy vấn câu hỏi tự nhiên / nghiệp vụ:**
   ```bash
   graphify query "<câu hỏi>" # Trả về chính xác subgraph, class, method, vị trí file và line number
   ```
2. **Tìm đường đi ngắn nhất giữa 2 thành phần:**
   ```bash
   graphify path "<Symbol_A>" "<Symbol_B>" # Ví dụ: graphify path "PaymentSagaOrchestrator" "JournalEntry"
   ```
3. **Giải thích chi tiết 1 class/symbol và các kết nối inbound/outbound:**
   ```bash
   graphify explain "<Node_ID_hoặc_Tên_Class>" # Xem caller, callee, import, references
   ```
4. **Đánh giá ảnh hưởng ngược (Impact Analysis):**
   ```bash
   graphify affected "<Event_hoặc_Model>" --depth 2 # Sửa đổi X sẽ kéo theo những class nào
   ```
5. **Kiến trúc God Nodes:**
   ```bash
   graphify god-nodes --top 15 # Các hub quan trọng nhất của hệ thống
   ```
6. **Cập nhật đồ thị sau khi sửa code (AST incremental, 0 token):**
   ```bash
   graphify update . # Hoặc tự động qua Git hooks (post-commit/post-checkout)
   ```
7. **Duyệt Wiki & Trực quan hóa tương tác:**
   - [Wiki Index](file:///home/buidi/Tài liệu/core-banking-microservices/graphify-out/wiki/index.md): 325 bài tổng hợp theo từng community.
   - [Đồ thị tương tác](file:///home/buidi/Tài liệu/core-banking-microservices/graphify-out/graph.html): Mở trực tiếp trên trình duyệt.

### 🔌 Tích hợp kép: MCP `graphify` & `codebase-memory-mcp`
- Cấu hình tại [`.agents/mcp_config.json`](file:///home/buidi/Tài liệu/core-banking-microservices/.agents/mcp_config.json):
  - Server `graphify`: `graphify-mcp` phục vụ đồ thị `graphify-out/graph.json`.
  - Server `codebase-memory`: Bổ trợ các hàm `search_graph`, `trace_path`, `get_code_snippet`.

### ⚠️ Trường hợp ngoại lệ duy nhất được fallback sang grep/cat:
- Tìm chuỗi ký tự cố định trong file cấu hình (`.yml`, `.properties`, `.env`, `.sql`).
- Tìm chuỗi thông báo lỗi hardcoded literal.
- Sau khi `graphify query` xác nhận không có symbol trong đồ thị AST.

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

---
## 🎨 Agent Skill: Taste Skill (Anti-Slop Design cho Web & Flutter Mobile)
- **Vị trí Skill:** `.agents/skills/taste-skill` (và tham chiếu `.agents/skills/taste-skill/references/flutter-mobile.md`).
- **Mục đích:** Định hướng nghệ thuật, thẩm mỹ cấp cao (Fintech Tier-1, Apple HIG) chống giao diện "AI slop" rẻ tiền, mang lại giao diện tinh tế, sang trọng cho Web & Flutter Mobile.
- **Tiêu chuẩn thiết kế:**
  1. **Quy tắc bất biến về Bottom Bar:** Tuyệt đối KHÔNG ĐƯỢC chỉnh sửa, phá vỡ, làm sai lệch hoặc thu nhỏ thanh Bottom Bar (`IOSLiquidGlassTabBar`). Luôn duy trì khoảng đệm đáy `110–120dp` (hoặc `SizedBox(height: 110)`) ở cuối danh sách cuộn (`CustomScrollView`, `ListView`) để nội dung không bị che lấp khi `extendBody: true`.
  2. **Bề mặt & Đường nét:** Thay thế đổ bóng đậm/đục bằng viền siêu mảnh 0.5dp (`Border.all(color: Colors.black.withOpacity(0.06), width: 0.5)`) và hiệu ứng kính lỏng Liquid Glass (`BackdropFilter` mờ nhẹ, border gradient sáng).
  3. **Màu sắc có mục đích (Color on Data, not Chrome):** Chỉ 3–5% diện tích màn hình mang màu rực; nền và khung icon mang sắc trung tính/kính mờ, dành màu sắc nổi bật cho dữ liệu tài chính (xanh ngọc cho tiền vào, đỏ/hồng cho tiền ra, vàng hổ phách cho trạng thái).
  4. **Typography tài chính:** Bắt buộc kích hoạt Tabular Figures (`FontFeature.tabularFigures()`) cho toàn bộ số dư và giao dịch để các chữ số không bị giật dòng.
  5. **Cảm ứng & Phản hồi:** Mọi vùng chạm tối thiểu 44×44dp, tích hợp rung nhẹ xúc giác `HapticFeedback.selectionClick()`.


