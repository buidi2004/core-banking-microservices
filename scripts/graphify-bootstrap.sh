#!/usr/bin/env bash
# Graphify bootstrap — cài CLI (nếu thiếu) và build/cập nhật knowledge graph.
#
#   bash scripts/graphify-bootstrap.sh          # build lần đầu hoặc update incremental
#   bash scripts/graphify-bootstrap.sh --full   # build lại toàn bộ (sau khi đổi .graphifyignore)
#
# Hoàn toàn offline: tree-sitter AST, không gọi LLM, không cần API key.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
export PATH="$HOME/.local/bin:$PATH"

FULL=0
[ "${1:-}" = "--full" ] && FULL=1

if ! command -v graphify >/dev/null 2>&1; then
  echo "→ Chưa có graphify, đang cài (PyPI: graphifyy[sql])..."
  if command -v uv >/dev/null 2>&1; then
    uv tool install "graphifyy[sql]"
  elif command -v pipx >/dev/null 2>&1; then
    pipx install "graphifyy[sql]"
  else
    python3 -m pip install --user "graphifyy[sql]"
  fi
  export PATH="$HOME/.local/bin:$PATH"
fi

echo "→ graphify $(graphify --version 2>/dev/null | awk '{print $2}')"

if [ "$FULL" -eq 1 ] || [ ! -f graphify-out/graph.json ]; then
  echo "→ Build graph (code-only, offline)..."
  graphify extract . --code-only --force
else
  echo "→ Cập nhật graph (incremental)..."
  graphify update .
fi
# Làm mới report + sidecar analysis (0 token; giữ label hub đã có)
graphify cluster-only .

# graph.html đầy đủ node-level (mặc định chỉ vẽ community khi >5000 node)
graphify export html --node-limit 12000

echo
echo "✔ Xong. Mở: graphify-out/graph.html"
echo "  Truy vấn: graphify query \"<câu hỏi>\" | graphify explain \"<Class>\""
