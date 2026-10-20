# E-Wallet Project Instructions for Claude

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

