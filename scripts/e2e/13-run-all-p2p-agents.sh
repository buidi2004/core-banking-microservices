#!/bin/bash
# ==============================================================================
# HỆ THỐNG ĐIỀU PHỐI 3 AI AGENTS: KIỂM THỬ E2E CHUYỂN KHOẢN P2P ĐA KỊCH BẢN
# Core Banking Microservices Architecture
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

echo "=============================================================================="
echo "🚀 ĐIỀU PHỐI 3 AI AGENTS KIỂM THỬ TOÀN DIỆN E2E CHUYỂN TIỀN P2P (ALICE & BOB)"
echo "=============================================================================="
echo "  • Tài khoản người gửi : Alice Nguyen (Wallet ID: 00000000-0000-0000-0000-000000000001)"
echo "  • Tài khoản người nhận: Bob Tran     (Wallet ID: 00000000-0000-0000-0000-000000000002)"
echo "  • Thời gian thực thi  : $(date '+%Y-%m-%d %H:%M:%S')"
echo "=============================================================================="

# 1. Kích hoạt Agent A
echo ""
bash "${SCRIPT_DIR}/10-wallet-p2p-scenarios.sh"

# 2. Kích hoạt Agent B
echo ""
bash "${SCRIPT_DIR}/11-payment-saga-p2p-scenarios.sh"

# 3. Kích hoạt Agent C
echo ""
bash "${SCRIPT_DIR}/12-ledger-notification-p2p-scenarios.sh"

echo ""
echo "=============================================================================="
echo "🎉 TỔNG KẾT: CẢ 3 AI AGENTS ĐÃ HOÀN THÀNH 16/16 KỊCH BẢN KIỂM THỬ E2E PASSED 100%!"
echo "=============================================================================="
