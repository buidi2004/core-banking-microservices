# E-Wallet Project Instructions for Claude

> **ĐỌC [`AGENTS.md`](AGENTS.md) TRƯỚC** — điểm vào chung cho mọi AI agent: bản đồ repo, luồng
> nghiệp vụ, cổng dịch vụ, quy tắc truy vấn Graphify.
> Chưa có knowledge graph? Chạy `bash scripts/graphify-bootstrap.sh` (offline, ~2 phút).
> Ưu tiên `graphify query "<câu hỏi>"` hơn grep/đọc source tràn lan.

## 🚨 MANDATORY RULE #1: CODEBASE MEMORY MCP
Always prefer MCP tools from `codebase-memory-mcp` over grep/glob/filesystem exploration.

### Projects:
- `core-banking-backend`: Java 17 / Spring Boot 3 microservices in `backend/`
- `core-banking-mobile`: Flutter Clean Architecture mobile app in `mobile/`

### Tool Priority:
1. `search_graph(project, query)` - Locate classes, functions, routes, variables
2. `trace_path(project, function_name, direction)` - Trace call chains and callers/callees
3. `get_code_snippet(project, qualified_name)` - Extract targeted code snippets
4. `get_file_outline(project, file_path)` - Outline file structure
5. `get_architecture(project, aspects)` - Understand module and architecture boundaries

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

Rules:
- When graphify-out/graph.json exists, run `graphify query "<question>"` before your first grep, search or source-file read for a codebase question, and put this rule in every subagent prompt that explores code. Read raw files only for lines the graph or an earlier read already located. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).
- A committed graphify-out/graph.json is rewritten whole on every build, so a large diff to it in a pull request is expected. Do not flag it as churn or suggest skipping the graph rebuild or its hooks.
