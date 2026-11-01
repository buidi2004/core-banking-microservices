# 🕸️ Graphify — Knowledge Graph cho Codebase

Tài liệu này mô tả cách [Graphify](https://github.com/Graphify-Labs/graphify) được tích hợp vào dự án
**Sen Hồng Core Banking & E-Wallet** để AI agent (OpenCode/Claude Code/Cursor…) truy vấn codebase
theo đồ thị tri thức thay vì grep/đọc file tràn lan.

## 1. Graphify là gì và vì sao dùng ở đây?

- Parse mã nguồn **cục bộ bằng tree-sitter AST** (Java, Dart, TypeScript, SQL, YAML, Shell…):
  deterministic, **không gọi LLM, không gửi code ra ngoài**.
- Mỗi cạnh có nhãn độ tin cậy: `EXTRACTED` (đọc trực tiếp từ source) hoặc `INFERRED` (do graphify suy luận).
- Không dùng vector store/embedding — đây là đồ thị thật, truy vấn bằng `query`, `path`, `explain`.
- Kết quả: agent trả lời câu hỏi kiến trúc (Saga → Ledger, gRPC Wallet → Payment…) với ít token hơn
  nhiều lần so với grep + đọc file.

## 2. Những gì đã được cài trong repo

| Thành phần | Đường dẫn | Vai trò |
| :--- | :--- | :--- |
| CLI `graphify` (PyPI `graphifyy` + extra `sql`) | cài bằng `uv tool` | Build & truy vấn graph |
| Skill cho OpenCode | `.opencode/skills/graphify/` | Kích hoạt bằng lệnh `/graphify` |
| Plugin nhắc dùng graph | `.opencode/plugins/graphify.js` | Nhắc `graphify query` trước lệnh shell đầu phiên |
| Hướng dẫn cho agent | `AGENTS.md` (mục `## graphify`) | Quy tắc query-first cho mọi agent |
| Loại trừ khỏi graph | `.graphifyignore` | Bỏ skill archify vendored, `releases/`, build output |
| Output | `graphify-out/` (đã gitignore) | `graph.json`, `graph.html`, `GRAPH_REPORT.md` |

> Graph hiện tại: **~8.089 nodes · 17.490 edges · 337 communities**, 94% cạnh `EXTRACTED`.
> Build từ commit `4e65b0f` (code + heading tài liệu markdown).

## 3. Cài đặt lại trên máy khác

```bash
# 1. Cài CLI (Python 3.10+, uv)
uv tool install "graphifyy[sql]"
# hoặc: pipx install "graphifyy[sql]"

# 2. Đăng ký skill + plugin cho OpenCode (project-scoped)
graphify install --project --platform opencode

# 3. Build graph (code-only: 0 token, không cần API key)
graphify extract . --code-only
graphify cluster-only .
graphify export html --node-limit 12000   # graph.html đầy đủ node-level
```

Cách nhanh nhất trên máy mới — một lệnh duy nhất (tự cài CLI, build/update, xuất HTML):

```bash
bash scripts/graphify-bootstrap.sh        # thêm --full để build lại từ đầu
```

Mở `graphify-out/graph.html` bằng trình duyệt để xem/tìm/lọc đồ thị tương tác.

## 4. Truy vấn hằng ngày

```bash
# Câu hỏi tự nhiên → subgraph liên quan (thay cho grep)
graphify query "luồng chuyển tiền P2P đi qua saga và ledger như thế nào"

# Đường đi ngắn nhất giữa 2 khái niệm
graphify path "PaymentSagaOrchestrator" "LedgerService"

# Giải thích 1 node + các kết nối
graphify explain "JournalEntry" --all

# Ảnh hưởng ngược: sửa X thì cái gì bị ảnh hưởng
graphify affected "TransactionEvent" --depth 2

# Các hub kiến trúc
graphify god-nodes --top 15
```

Mẹo:

- `--budget 4000` để lấy nhiều node hơn (mặc định 2000 token).
- Tên trùng (ví dụ `ApiResponse` xuất hiện ở nhiều service): dùng `path/symbol` dạng
  `backend/.../File.java::ClassName`, hoặc id đầy đủ mà CLI gợi ý.
- Exit code: `0` có kết quả, `3` tên mơ hồ, `4` không tìm thấy node.

## 5. Cập nhật graph sau khi sửa code

```bash
graphify update .        # AST incremental, không tốn token
```

`update` cũng đưa heading của file markdown vào graph (không gọi LLM); muốn graph thuần code thì
build lại bằng `graphify extract . --code-only --force`.

Tuỳ chọn — tự động cập nhật sau mỗi commit/checkout (cài git hook):

```bash
graphify hook install    # post-commit / post-checkout / post-merge / post-rewrite
graphify hook status
graphify hook uninstall  # gỡ bỏ
```

Nếu không dùng hook, hãy chạy `graphify update .` sau khi pull/merge để graph không bị cũ.

## 6. Bật thêm semantic pass (docs/PDF) và đặt tên community

Mặc định repo đang build **code-only** nên không cần API key. Muốn index thêm `docs/`, README, PDF
hoặc đặt tên cộng đồng (`Community 12` → `payment-saga`) thì cấu hình một backend:

```bash
export GOOGLE_API_KEY=...        # hoặc ANTHROPIC_API_KEY / OPENAI_API_KEY / DEEPSEEK_API_KEY...
# hoặc chạy local: export OLLAMA_BASE_URL=http://localhost:11434

graphify extract .               # AST + semantic cho docs
graphify label .                 # đặt tên community bằng LLM
```

Nếu chỉ muốn code: giữ `--code-only` khi extract và dùng `cluster-only .` như hiện tại.

## 7. Mọi AI agent đều đọc được (onboarding)

**Nguồn sự thật duy nhất là [`AGENTS.md`](../AGENTS.md)** — mọi file cấu hình khác chỉ trỏ về đó,
nên khi bản đồ repo/quy tắc thay đổi chỉ cần sửa một chỗ.

| Công cụ | File được tự động đọc | Nội dung |
| :--- | :--- | :--- |
| OpenCode | `AGENTS.md` + `.opencode/skills/graphify/` + plugin | đầy đủ |
| Claude Code | `CLAUDE.md` (+ hook `.claude/settings.json`) | trỏ `AGENTS.md` |
| Codex / Aider / Zed / Amp / Jules | `AGENTS.md` (chuẩn chung) | đầy đủ |
| Cursor | `AGENTS.md`, `.cursor/rules/00-read-first.mdc`, `graphify.mdc` | trỏ + luật `alwaysApply` |
| Gemini CLI | `GEMINI.md` (+ hook `.gemini/settings.json`) | trỏ `AGENTS.md` |
| GitHub Copilot Chat | `.github/copilot-instructions.md` + skill Copilot | trỏ `AGENTS.md` |
| Windsurf | `.windsurfrules` | trỏ `AGENTS.md` |
| Cline | `.clinerules` | trỏ `AGENTS.md` |
| Roo Code | `.roo/rules/00-read-first.md` | trỏ `AGENTS.md` |

### Máy mới / clone mới — 1 lệnh

```bash
bash scripts/graphify-bootstrap.sh
```

Script này: cài `graphifyy[sql]` nếu thiếu (uv → pipx → pip), build graph lần đầu
(hoặc `update` incremental nếu đã có), rồi xuất `graph.html` đầy đủ. Không cần API key.

### Thêm một AI khác sau này

```bash
graphify install --project --platform <tên>   # claude|cursor|gemini|codex|…
```

Sau đó thêm 1 dòng trỏ về `AGENTS.md` vào file cấu hình của công cụ đó (nếu công cụ không đọc
`AGENTS.md` gốc).

## 8. Hạn chế đã biết

- Đồ thị dựng từ **AST tĩnh**: lời gọi qua HTTP (`RestTemplate`/`WebClient`/Feign), gRPC stub sinh tự động,
  Kafka/RabbitMQ event không tạo cạnh `calls` trực tiếp giữa 2 service. Vì vậy `graphify path` giữa
  class ở 2 service có thể không tìm thấy đường đi định hướng — thử `--undirected`, hoặc truy vấn theo
  DTO/event (`TransactionEvent`, `WalletBalanceChangedPayload`) và dùng `graphify affected`.
- Code sinh tự động trong `target/`, `build/`, `.dart_tool/`, `node_modules/` bị loại khỏi graph.
- Một số tên class trùng giữa các service (ví dụ `ApiResponse`, `Wallet`): CLI sẽ báo *Ambiguous* và
  liệt kê id đầy đủ — dùng id đó cho `path`/`explain`.
- `graphify update .` có thể đưa thêm heading markdown vào graph; muốn graph thuần code, build lại
  bằng `graphify extract . --code-only --force`.

## 9. Lưu ý khi làm việc nhóm

- `graphify-out/` **không commit** (graph.json ~10 MB, graph.html ~9 MB). Mỗi máy tự build lại.
- Muốn cả team dùng chung một graph đã build: bỏ dòng `graphify-out/` trong `.gitignore` và commit,
  hoặc đẩy lên object storage/CI artifact.
- `.graphifyignore` đang loại trừ `.agents/skills/**` (skill archify vendored) và `releases/**`
  để graph tập trung vào code ngân hàng. Thêm pattern vào file này nếu có thư mục sinh tự động khác.
- `graph.json` được ghi lại toàn bộ mỗi lần build — nếu có commit, diff lớn là bình thường.
