#!/usr/bin/env bash
# ==============================================================================
# 🔒 CHECK_BACKEND_GUARD.SH — KIỂM TRA BẤT BIẾN "KHÔNG SỬA BACKEND" (CHỈ ĐỌC)
# ==============================================================================
# Mục đích : Chứng minh rằng `backend/**`, `docker-compose.yml`, `deploy/**`
#            vẫn byte-for-byte giống baseline của dự án (AUDIT-MOB-BE-001).
# An toàn  : SCRIPT NÀY CHỈ ĐỌC. Không ghi file, không chạy git add/commit/
#            checkout/reset/clean. Tuyệt đối không tự ý "làm sạch" backend.
# Exit code: 0 = sạch (guard OK)
#            2 = VI PHẠM (backend đã bị sửa so với baseline)
#            1 = lỗi môi trường (không phải git repo / thiếu git)
# ------------------------------------------------------------------------------
# Baseline (commit 75bf273cd707571c13073a625390a78adfa320ce):
#   eb37871177838108be4df91e6498e40645f610eaff1ed308e1a587c09b0aa003
# ------------------------------------------------------------------------------
# Ví dụ dùng:
#   bash scripts/check_backend_guard.sh            # in báo cáo, exit 0/2
#   bash scripts/check_backend_guard.sh --quiet    # chỉ in dòng kết luận
#   bash scripts/check_backend_guard.sh --json     # xuất JSON cho CI/agent
# ------------------------------------------------------------------------------

set -Eeuo pipefail

readonly BASELINE_CHECKSUM="eb37871177838108be4df91e6498e40645f610eaff1ed308e1a587c09b0aa003"
readonly BASELINE_COMMIT="75bf273cd707571c13073a625390a78adfa320ce"
readonly GUARDED_PATHS=(backend docker-compose.yml deploy)

QUIET=0
JSON=0
for arg in "$@"; do
  case "$arg" in
    --quiet|-q) QUIET=1 ;;
    --json)    JSON=1 ;;
    --help|-h)
      sed -n '2,25p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "Tùy chọn không hợp lệ: $arg (dùng --help)" >&2
      exit 1
      ;;
  esac
done

# --- 1. Kiểm tra môi trường ---------------------------------------------------
if ! command -v git >/dev/null 2>&1; then
  echo "LỖI: không tìm thấy lệnh 'git'." >&2
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$REPO_ROOT" ]]; then
  echo "LỖI: thư mục hiện tại không nằm trong git repo." >&2
  exit 1
fi
cd "$REPO_ROOT"

# --- 2. Thu thập dữ liệu (CHỈ ĐỌC) -------------------------------------------
compute_checksum() {
  git ls-tree -r HEAD backend 2>/dev/null | awk '{print $3"  "$4}' | sort -k2 | sha256sum | awk '{print $1}'
}

CURRENT_CHECKSUM="$(compute_checksum)"
STATUS_OUT="$(git status --porcelain -- "${GUARDED_PATHS[@]}" 2>/dev/null || true)"
DIFF_OUT="$(git diff --name-only -- "${GUARDED_PATHS[@]}" 2>/dev/null || true)"
UNTRACKED_OUT="$(git ls-files --others --exclude-standard -- "${GUARDED_PATHS[@]}" 2>/dev/null || true)"
DRIFT_SINCE_BASE="$(git diff --name-status "$BASELINE_COMMIT" HEAD -- "${GUARDED_PATHS[@]}" 2>/dev/null || true)"

MODIFIED_COUNT="$(printf '%s\n' "$STATUS_OUT" | grep -c '^ M ' || true)"
UNTRACKED_COUNT="$(printf '%s\n' "$STATUS_OUT" | grep -c '^?? ' || true)"
OTHER_COUNT="$(printf '%s\n' "$STATUS_OUT" | grep -cvE '^( M |\?\? )' || true)"
TOTAL_DIRTY=$(( MODIFIED_COUNT + UNTRACKED_COUNT + OTHER_COUNT ))

if [[ "$CURRENT_CHECKSUM" == "$BASELINE_CHECKSUM" && "$TOTAL_DIRTY" -eq 0 ]]; then
  VIOLATION=0
else
  VIOLATION=1
fi

# --- 3. Xuất báo cáo ---------------------------------------------------------
if [[ "$JSON" -eq 1 ]]; then
  printf '{\n'
  printf '  "guard": "backend-readonly",\n'
  printf '  "violation": %s,\n' "$VIOLATION"
  printf '  "baseline_commit": "%s",\n' "$BASELINE_COMMIT"
  printf '  "baseline_checksum": "%s",\n' "$BASELINE_CHECKSUM"
  printf '  "current_checksum": "%s",\n' "$CURRENT_CHECKSUM"
  printf '  "checksum_match": %s,\n' "$([[ "$CURRENT_CHECKSUM" == "$BASELINE_CHECKSUM" ]] && echo true || echo false)"
  printf '  "modified_files": %s,\n' "$MODIFIED_COUNT"
  printf '  "untracked_files": %s,\n' "$UNTRACKED_COUNT"
  printf '  "guarded_paths": ["backend", "docker-compose.yml", "deploy"],\n'
  printf '  "dirty_entries": [\n'
  first=1
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    [[ $first -eq 1 ]] || printf ',\n'
    printf '    "%s"' "$line"
    first=0
  done <<< "$STATUS_OUT"
  printf '\n  ]\n}\n'
  exit $(( VIOLATION == 1 ? 2 : 0 ))
fi

if [[ "$QUIET" -eq 1 ]]; then
  if [[ "$VIOLATION" -eq 0 ]]; then
    echo "OK: backend guard sạch (checksum ${CURRENT_CHECKSUM})"
  else
    echo "VIOLATION: backend guard bị vi phạm (${TOTAL_DIRTY} mục, checksum ${CURRENT_CHECKSUM})"
  fi
  exit $(( VIOLATION == 1 ? 2 : 0 ))
fi

echo "=============================================================================="
echo " 🔒 BACKEND GUARD CHECK — chỉ đọc, không sửa gì"
echo "=============================================================================="
echo " Repo            : ${REPO_ROOT}"
echo " Baseline commit : ${BASELINE_COMMIT}"
echo " Baseline SHA256 : ${BASELINE_CHECKSUM}"
echo " Current  SHA256 : ${CURRENT_CHECKSUM}"
if [[ "$CURRENT_CHECKSUM" == "$BASELINE_CHECKSUM" ]]; then
  echo " Checksum        : ✅ KHỚP"
else
  echo " Checksum        : ❌ LỆCH (kỳ vọng ${BASELINE_CHECKSUM})"
fi
echo
echo "--- git status --porcelain -- backend docker-compose.yml deploy ---"
if [[ -z "$STATUS_OUT" ]]; then
  echo " (rỗng — sạch 100%)"
else
  printf '%s\n' "$STATUS_OUT"
fi
echo
echo "--- git diff --name-only (đã sửa, chưa commit) ---"
if [[ -z "$DIFF_OUT" ]]; then
  echo " (rỗng)"
else
  printf '%s\n' "$DIFF_OUT"
fi
echo
echo "--- file chưa track (mới tạo) ---"
if [[ -z "$UNTRACKED_OUT" ]]; then
  echo " (rỗng)"
else
  printf '%s\n' "$UNTRACKED_OUT"
fi
echo
echo "--- drift so với baseline commit (đã commit) ---"
if [[ -z "$DRIFT_SINCE_BASE" ]]; then
  echo " (rỗng)"
else
  printf '%s\n' "$DRIFT_SINCE_BASE"
fi
echo
echo " Tổng số mục bẩn : ${TOTAL_DIRTY} (modified=${MODIFIED_COUNT}, untracked=${UNTRACKED_COUNT}, khác=${OTHER_COUNT})"
echo "------------------------------------------------------------------------------"
if [[ "$VIOLATION" -eq 0 ]]; then
  echo " ✅ KẾT LUẬN: BACKEND GUARD SẠCH — không có file nào dưới backend/ bị đụng."
  echo "------------------------------------------------------------------------------"
  exit 0
fi

cat <<'EOT'
 ❌ KẾT LUẬN: BACKEND GUARD BỊ VI PHẠM — backend/ đã khác baseline.
 ------------------------------------------------------------------------------
 ⚠️  HÀNH ĐỘNG BẮT BUỘC CỦA CON 2 / CON 3 / CON 4:
      • DỪNG mọi thao tác ghi vào backend/**, docker-compose.yml, deploy/**
      • KHÔNG tự revert, KHÔNG chạy git checkout/reset/clean trên các path đó
      • BÁO CÁO ngay cho Con 1 (Lead) kèm output của script này
 ------------------------------------------------------------------------------
 🔧 CÁCH KHẮC PHỤC (quyết định thuộc về CHỦ REPO — KHÔNG tự thực hiện):
      Phương án A — Khôi phục baseline (khuyến nghị):
        git checkout 75bf273 -- backend docker-compose.yml deploy
        git clean -fd backend docker-compose.yml deploy
        git commit -m "revert: khoi phuc backend baseline"
        → kiểm tra lại: bash scripts/check_backend_guard.sh  (kỳ vọng exit 0)
      Phương án B — Chính thức hoá thay đổi backend:
        1) Chủ repo ký waiver .agents_workspace/backend_guard_waiver.json
           (approved_by, approved_at, commit, scope, expires_at)
        2) Chạy test backend (mvn) cho các service bị sửa
        3) Tích hợp mobile theo API mới + bật cờ capability tương ứng
        4) Cập nhật lại .agents_workspace/05_MOBILE_BE_AUDIT_FINAL.md
 ------------------------------------------------------------------------------
EOT
exit 2
