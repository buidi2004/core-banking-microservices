# Đọc trước — Sen Hồng Core Banking (Roo Code)

> **ĐỌC `AGENTS.md` TRƯỚC** — điểm vào chung cho mọi AI agent: bản đồ repo, luồng nghiệp vụ,
> cổng dịch vụ, quy ước code.

- `graphify-out/graph.json` là knowledge graph cục bộ (tree-sitter AST, offline): chạy
  `graphify query "<câu hỏi>"` trước khi grep/đọc source.
- `graphify path "<A>" "<B>"` cho quan hệ, `graphify explain "<X>"` cho một khái niệm,
  `graphify affected "<X>"` để xem ảnh hưởng ngược.
- Chưa có graph: `bash scripts/graphify-bootstrap.sh` (offline, ~2 phút, 0 token).
- Sửa code xong: `graphify update .`.
- Chi tiết: `docs/GRAPHIFY.md`.
