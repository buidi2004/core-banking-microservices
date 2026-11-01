# AGENTS.md — Điểm vào chung cho mọi AI agent

> **ĐỌC FILE NÀY TRƯỚC** khi trả lời bất kỳ câu hỏi nào về codebase này (Claude Code, Cursor,
> Codex, Copilot, Gemini CLI, OpenCode, Aider, Windsurf, Cline… đều được trỏ về đây).
> Mục tiêu: nắm kiến trúc trong ~2 phút, rồi truy vấn đồ thị tri thức thay vì grep tràn lan.

## 0. Thứ tự đọc

1. **File này** — bản đồ repo, luồng nghiệp vụ, cổng dịch vụ, quy ước.
2. `graphify-out/GRAPH_REPORT.md` — kiến trúc tổng quan, god nodes, community (nếu đã build graph).
3. `docs/GRAPHIFY.md` — cách query/path/explain, build & cập nhật graph.
4. `docs/architecture/` — báo cáo thiết kế chi tiết (Saga, dual-broker, migration 5 services).
5. `docs/guides/` — hướng dẫn frontend, OpenCode, codebase memory.

## 1. Đồ thị tri thức — ưu tiên hơn grep

Repo có knowledge graph cục bộ (tree-sitter AST, không gửi code ra ngoài, 0 token):

```bash
graphify query "luồng chuyển tiền P2P đi qua saga và ledger"   # câu hỏi → subgraph
graphify path "<node-id-A>" "<node-id-B>"                        # quan hệ giữa 2 khái niệm
graphify explain "PaymentSagaOrchestrator"                       # 1 node + kết nối
graphify affected "TransactionEvent" --depth 2                   # ảnh hưởng ngược
```

- Có `graphify-out/graph.json` → chạy `graphify query` **trước** lần grep/read source đầu tiên.
- **Chưa có graph** (máy mới/clone mới) → chạy `bash scripts/graphify-bootstrap.sh`
  (offline, ~2 phút, không cần API key), rồi query.
- Sau khi sửa code → `graphify update .` (incremental, 0 token).
- Tên trùng giữa các service → dùng id đầy đủ hoặc dạng `path/File.java::Class` mà CLI gợi ý.
- Quy tắc chi tiết nằm ở mục `## graphify` cuối file này.

## 2. Bản đồ repo

| Đường dẫn | Nội dung |
| :--- | :--- |
| `backend/services/api-gateway` | Spring Cloud Gateway :8080 — JWT filter, blacklist Redis, rate limit, route |
| `backend/services/identity-service` | :8081 — user, KYC, BCrypt PIN, OTP, JWT, device |
| `backend/services/wallet-service` | :8082 + gRPC :9090 — số dư, pessimistic lock, hạn mức, Kafka balance event |
| `backend/services/payment-service` | :8083 — Saga P2P, Outbox Relay, Maker-Checker nạp quầy, bills/cards/savings |
| `backend/services/ledger-service` | :8084 — double-entry, JournalEntry/Posting bất biến, chống duplicate |
| `backend/services/notification-service` | :8085 — STOMP WebSocket, FCM, SMS Banking |
| `backend/common-library` | proto `wallet.proto`, gRPC stubs, shared DTO/event envelope |
| `backend/pom.xml`, `pom.xml` | Maven multi-module (Java 17 / Spring Boot 3.2.5) |
| `mobile/` | Flutter app “Sen Hồng Bank”, Clean Architecture (`lib/{core,data,domain,presentation}`) |
| `frontend/cash-deposit-portal` | React 18 + Vite + Tailwind — Teller Portal (:5173) |
| `scripts/` | `init-5-databases.sql`, E2E scenarios (`scripts/e2e/*.sh`), maintenance |
| `docker-compose.yml`, `deploy/` | Hạ tầng local: Postgres ×5, Kafka, RabbitMQ, Redis, services |
| `docs/` | Kiến trúc, guide, báo cáo migration, `GRAPHIFY.md` |

## 3. Cổng & hạ tầng

| Thành phần | Cổng | Ghi chú |
| :--- | :--- | :--- |
| API Gateway | 8080 | điểm vào duy nhất cho client |
| identity / wallet / payment / ledger / notification | 8081 / 8082 / 8083 / 8084 / 8085 | HTTP |
| wallet gRPC | 9090 | Payment → Wallet nội bộ |
| Postgres ×5 | 5433–5437 | database-per-service, Flyway mỗi service |
| Kafka (KRaft) | 9092 | topic `banking.wallet.balance-changed.v1`, `banking.payment.transaction-lifecycle.v1` |
| RabbitMQ | 5672 / UI 15672 | exchange `wallet.transaction.events`, routing key `transaction.completed/reversed/failed` |
| Redis | 6379 | distributed lock, token blacklist, OTP |
| Teller Portal | 5173 | React Vite |

## 4. Luồng nghiệp vụ trọng yếu

1. **P2P transfer (Saga Orchestration)** — `PaymentSagaOrchestrator`:
   `RESERVE_BALANCE` → `DEBIT_WALLET` → `CREDIT_WALLET`; lỗi bước 3 → compensating action
   (release/hoàn tiền). Idempotency-Key bắt buộc, timeout 30s.
2. **Transactional Outbox** — payment ghi `outbox_events` cùng transaction DB; `OutboxRelay` poll
   500ms, đẩy song song RabbitMQ (task) + Kafka (event stream), at-least-once.
3. **Double-entry ledger** — mỗi giao dịch tạo `JournalEntry` POSTED + ≥2 `LedgerPosting`
   (DEBIT = CREDIT, lệch ≠ 0 → `LedgerUnbalancedException`).
4. **Cash deposit Maker-Checker** — Teller Portal → payment-service → ledger; kiểm tra hạn mức
   két quỹ chi nhánh, 2 cấp duyệt.
5. **Notification** — ledger/payment phát event → notification-service → STOMP `/topic/notifications`,
   FCM, SMS format.
6. **Auth** — JWT access/refresh, PIN BCrypt strength 12, OTP Redis, blacklist khi logout,
   khóa tài khoản sau 5 lần sai / khóa PIN sau 3 lần sai.

## 5. Quy ước code

- **Backend**: Java 17, package `com.fintech.<service>.{domain,application,infrastructure,controller,…}`
  (hexagonal-ish); DTO ↔ domain mapper riêng; Flyway `src/main/resources/db/migration/V*__*.sql`.
- **Database-per-service**: không join/truy vấn chéo DB; giao tiếp qua REST, gRPC hoặc event.
- **Tiền tệ**: `BigDecimal`, ISO-8601 UTC, không dùng `double`.
- **Mobile**: Clean Architecture, state management + Liquid Glass theme; test trong `mobile/test/`.
- **Frontend**: React + TypeScript, component trong `src/components/`.
- **Test**: JUnit 5 + Mockito (backend), `flutter test`, E2E shell trong `scripts/e2e/`.
- Không commit `target/`, `build/`, `.dart_tool/`, `graphify-out/` (đã gitignore).

## 6. Quy tắc làm việc

- Trả lời/Implement dựa trên graph + source đã định vị; không đọc cả repo.
- Sửa code → chạy test liên quan → `graphify update .`.
- Giữ nguyên style, naming, comment tiếng Việt/Anh hiện có của file đang sửa.
- Không tự ý xóa file/thay đổi kiến trúc ngoài phạm vi yêu cầu.

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

When the user types `/graphify`, use the installed graphify skill or instructions before doing anything else.

Rules:
- When graphify-out/graph.json exists, run `graphify query "<question>"` before your first grep, search or source-file read for a codebase question, and put this rule in every subagent prompt that explores code. Read raw files only for lines the graph or an earlier read already located. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- Dirty graphify-out/ files are expected after hooks or incremental updates; dirty graph files are not a reason to skip graphify. Only skip graphify if the task is about stale or incorrect graph output, or the user explicitly says not to use it.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).
- A committed graphify-out/graph.json is rewritten whole on every build, so a large diff to it in a pull request is expected. Do not flag it as churn or suggest skipping the graph rebuild or its hooks.
