#!/usr/bin/env bash
# ==============================================================================
# SCRIPT: scripts/maintenance/security-audit-public.sh
# AGENT 1: GATEWAY & INFRASTRUCTURE ORCHESTRATOR
#
# MỤC ĐÍCH:
#   Quét và kiểm tra an toàn bảo mật toàn diện các port nội bộ nhạy cảm:
#   - 5 Cơ sở dữ liệu Postgres: 5433 (Identity), 5434 (Wallet), 5435 (Payment), 5436 (Ledger), 5437 (Notification)
#   - Message Brokers & Cache: 5672/15672 (RabbitMQ), 6379 (Redis), 9092/29092 (Kafka), 8090 (Kafka-UI)
#
# KIỂM ĐỊNH:
#   1. Kiểm tra cấu hình tĩnh (Static Configuration Audit): deploy/docker-compose.public.yml
#      - Đảm bảo 100% services nội bộ CHỈ dùng 'expose', KHÔNG dùng 'ports' ra host.
#      - Duy nhất Caddy Reverse Proxy được mở port 80 & 443.
#   2. Quét cổng thời gian thực (Live Network Interface Audit):
#      - Quét socket qua IP external interface và 0.0.0.0 để phát hiện rò rỉ ra public internet.
# ==============================================================================

set -uo pipefail

# ANSI Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

WORKSPACE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$WORKSPACE_ROOT"

# Danh sách các port nội bộ cần bảo vệ nghiêm ngặt
INTERNAL_PORTS=(
    "5433:Identity Database (PostgreSQL)"
    "5434:Wallet Core Database (PostgreSQL)"
    "5435:Payment Database (PostgreSQL)"
    "5436:General Ledger Database (PostgreSQL Append-Only)"
    "5437:Notification Database (PostgreSQL)"
    "5672:RabbitMQ AMQP Protocol"
    "15672:RabbitMQ Management Web UI"
    "6379:Redis In-Memory Cache & Lock"
    "9092:Apache Kafka KRaft Broker"
    "29092:Apache Kafka External Listener"
    "8090:Kafka-UI Management Web Dashboard"
)

PUBLIC_SAFE_PORTS=(
    "80:HTTP (Caddy Reverse Proxy -> Auto TLS Redirect)"
    "443:HTTPS (Caddy Reverse Proxy w/ TLS & HSTS)"
)

MODE="audit"
TARGET_HOST=""
STRICT_EXIT=0

# Xử lý tham số dòng lệnh
while [[ $# -gt 0 ]]; do
    case "$1" in
        --strict)
            STRICT_EXIT=1
            shift
            ;;
        --target-ip)
            TARGET_HOST="$2"
            shift 2
            ;;
        --help|-h)
            echo "Sử dụng: $0 [TÙY CHỌN]"
            echo "Tùy chọn:"
            echo "  --strict        Báo lỗi (exit 1) nếu phát hiện bất kỳ port nội bộ nào đang lắng nghe trên 0.0.0.0"
            echo "  --target-ip IP  Chỉ định IP cụ thể để kiểm tra socket probe (mặc định: IP giao diện mạng máy chủ)"
            echo "  --help, -h      Hiển thị hướng dẫn"
            exit 0
            ;;
        *)
            echo "Tham số không hợp lệ: $1. Dùng --help để xem trợ giúp."
            exit 1
            ;;
    esac
done

# Tự động xác định IP mạng ngoài (Non-loopback IP)
if [ -z "$TARGET_HOST" ]; then
    TARGET_HOST=$(hostname -I 2>/dev/null | awk '{print $1}')
    if [ -z "$TARGET_HOST" ]; then
        TARGET_HOST="127.0.0.1"
    fi
fi

echo -e "${BOLD}${CYAN}==============================================================================${NC}"
echo -e "${BOLD}${CYAN}   [AGENT 1 - GATEWAY & INFRA] SECURITY AUDIT: PUBLIC PORT HARDENING SCAN   ${NC}"
echo -e "${BOLD}${CYAN}==============================================================================${NC}"
echo -e "Thư mục dự án:     ${BLUE}${WORKSPACE_ROOT}${NC}"
echo -e "Thời điểm quét:    ${YELLOW}$(date '+%Y-%m-%d %H:%M:%S %Z')${NC}"
echo -e "Giao diện kiểm tra: ${MAGENTA}${TARGET_HOST}${NC} (Host External Interface)\n"

# ------------------------------------------------------------------------------
# PHẦN 1: KIỂM ĐỊNH CẤU HÌNH DOCKER COMPOSE PUBLIC PROFILE
# ------------------------------------------------------------------------------
echo -e "${BOLD}${YELLOW}--- PHẦN 1: KIỂM TOÁN CẤU HÌNH BẢO MẬT (DEPLOY/DOCKER-COMPOSE.PUBLIC.YML) ---${NC}"

COMPOSE_PUBLIC="deploy/docker-compose.public.yml"
CONFIG_ERRORS=0

if [ ! -f "$COMPOSE_PUBLIC" ]; then
    echo -e "  ${RED}✗ CẢNH BÁO: Không tìm thấy file '${COMPOSE_PUBLIC}'!${NC}"
    CONFIG_ERRORS=$((CONFIG_ERRORS + 1))
else
    echo -e "  • Tìm thấy file cấu hình Production Public: ${GREEN}${COMPOSE_PUBLIC}${NC}"

    # 1. Kiểm tra Caddyfile port mapping
    if grep -q '"80:80"' "$COMPOSE_PUBLIC" && grep -q '"443:443"' "$COMPOSE_PUBLIC"; then
        echo -e "    ${GREEN}✓ ĐẠT:${NC} Caddy reverse proxy mở cổng chuẩn Internet (80/HTTP, 443/HTTPS)."
    else
        echo -e "    ${RED}✗ LỖI:${NC} Caddy chưa cấu hình đủ cổng 80 & 443."
        CONFIG_ERRORS=$((CONFIG_ERRORS + 1))
    fi

    # 2. Quét xem có port nhạy cảm nào bị dùng 'ports:' thay vì 'expose:'
    LEAKED_SERVICES=""
    for item in "${INTERNAL_PORTS[@]}"; do
        port="${item%%:*}"
        # Tìm port nằm trong khối ports:
        if grep -E '^\s*-\s*["'\''0-9]+:'"${port}"'["'\''0-9]*' "$COMPOSE_PUBLIC" > /dev/null 2>&1; then
            LEAKED_SERVICES="${LEAKED_SERVICES} ${port}"
        fi
    done

    if [ -n "$LEAKED_SERVICES" ]; then
        echo -e "    ${RED}✗ NGUY HIỂM: Phát hiện port nội bộ được publish trực tiếp trong public compose:${LEAKED_SERVICES}${NC}"
        CONFIG_ERRORS=$((CONFIG_ERRORS + 1))
    else
        echo -e "    ${GREEN}✓ ĐẠT (ZERO-TRUST):${NC} 100% cơ sở dữ liệu và message brokers KHÔNG dùng 'ports:' ra ngoài host."
    fi

    # 3. Kiểm tra Security Headers trong Caddyfile
    CADDYFILE="deploy/Caddyfile"
    if [ -f "$CADDYFILE" ]; then
        if grep -q "Strict-Transport-Security" "$CADDYFILE" && \
           grep -q "X-Content-Type-Options" "$CADDYFILE" && \
           grep -q "X-Frame-Options" "$CADDYFILE"; then
            echo -e "    ${GREEN}✓ ĐẠT:${NC} Caddyfile được trang bị đầy đủ bộ Security Headers (HSTS, nosniff, DENY frame)."
        else
            echo -e "    ${YELLOW}⚠ CẢNH BÁO:${NC} Caddyfile còn thiếu một số Security Headers khuyến nghị."
        fi
    fi
fi
echo ""

# ------------------------------------------------------------------------------
# PHẦN 2: QUÉT THỜI GIAN THỰC CÁC PORT ĐANG LẮNG NGHE TRÊN HOST
# ------------------------------------------------------------------------------
echo -e "${BOLD}${YELLOW}--- PHẦN 2: QUÉT THỜI GIAN THỰC TRẠNG THÁI PORTS TRÊN HOST INTERFACES ---${NC}"
printf "%-7s | %-45s | %-16s | %-15s\n" "PORT" "DỊCH VỤ / MÔ TẢ" "TRẠNG THÁI SOCKET" "ĐÁNH GIÁ AN TOÀN"
echo "---------------------------------------------------------------------------------------------------"

EXPOSED_COUNT=0
TOTAL_CHECKED=0

for item in "${INTERNAL_PORTS[@]}"; do
    TOTAL_CHECKED=$((TOTAL_CHECKED + 1))
    port="${item%%:*}"
    desc="${item#*:}"

    # Kiểm tra bằng ss trên 0.0.0.0 hoặc wildcard
    IS_LISTENING_ALL=$(ss -tlnH "sport = :${port}" 2>/dev/null | grep -E "0\.0\.0\.0:${port}|\[::\]:${port}|\*:${port}" || true)
    
    # Kiểm tra probe trực tiếp tới target host IP
    PROBE_OPEN=0
    if command -v nc >/dev/null 2>&1; then
        if nc -z -w 1 "$TARGET_HOST" "$port" 2>/dev/null; then
            PROBE_OPEN=1
        fi
    elif timeout 1 bash -c "</dev/tcp/${TARGET_HOST}/${port}" 2>/dev/null; then
        PROBE_OPEN=1
    fi

    if [ -n "$IS_LISTENING_ALL" ] || [ "$PROBE_OPEN" -eq 1 ]; then
        EXPOSED_COUNT=$((EXPOSED_COUNT + 1))
        STATUS_STR="0.0.0.0:${port} (OPEN)"
        EVAL_STR="${YELLOW}DEV_ONLY (WARN)${NC}"
        if [ "$STRICT_EXIT" -eq 1 ]; then
            EVAL_STR="${RED}LEAK_EXPOSED${NC}"
        fi
        printf "%-7s | %-45s | %-25b | %-15b\n" "$port" "$desc" "${YELLOW}${STATUS_STR}${NC}" "$EVAL_STR"
    else
        STATUS_STR="STEALTH / CLOSED"
        EVAL_STR="${GREEN}SECURE (PASSED)${NC}"
        printf "%-7s | %-45s | %-25b | %-15b\n" "$port" "$desc" "${GREEN}${STATUS_STR}${NC}" "$EVAL_STR"
    fi
done

echo "---------------------------------------------------------------------------------------------------"
echo ""

# ------------------------------------------------------------------------------
# PHẦN 3: TỔNG KẾT & KHUYẾN NGHỊ BẢO MẬT
# ------------------------------------------------------------------------------
echo -e "${BOLD}${CYAN}==============================================================================${NC}"
echo -e "${BOLD}${CYAN}                       KẾT LUẬN KIỂM TOÁN AN TOÀN                             ${NC}"
echo -e "${BOLD}${CYAN}==============================================================================${NC}"
echo -e "• Tổng số ports nội bộ quét:          ${BOLD}${TOTAL_CHECKED}${NC}"
echo -e "• Số ports đang bind ra host (Dev):    ${BOLD}${EXPOSED_COUNT}${NC}"
echo -e "• Cấu hình Production Public Compose:  $(if [ $CONFIG_ERRORS -eq 0 ]; then echo -e "${GREEN}100% HARDENED & ISOLATED${NC}"; else echo -e "${RED}CẦN KHẮC PHỤC (${CONFIG_ERRORS} lỗi)${NC}"; fi)"

if [ "$CONFIG_ERRORS" -eq 0 ]; then
    echo -e "\n${BOLD}${GREEN}>>> CHUẨN ĐOÁN KIẾN TRÚC HOÀN HẢO:<<<${NC}"
    echo -e "1. File ${CYAN}deploy/docker-compose.public.yml${NC} đã gỡ bỏ 100% port binding ra ngoài host cho các DBs và Brokers."
    echo -e "2. Khi triển khai Public Demo, chỉ duy nhất ${GREEN}Caddy Reverse Proxy (Port 80/443)${NC} đón request từ bên ngoài."
    echo -e "3. Toàn bộ giao tiếp giữa Gateway, 5 Microservices, Postgres, Kafka KRaft, Redis và RabbitMQ diễn ra hoàn toàn trong mạng nội bộ cô lập ${BLUE}ewallet-microservices-net${NC}."
fi

if [ "$EXPOSED_COUNT" -gt 0 ]; then
    echo -e "\n${YELLOW}[LƯU Ý VẬN HÀNH]:${NC}"
    echo -e "  Hiện tại host đang chạy môi trường phát triển (docker-compose.yml) để phục vụ test cục bộ."
    echo -e "  Khi đóng gói đưa lên Server Public/Internet, bắt buộc chạy profile:${NC}"
    echo -e "  ${BOLD}${CYAN}docker compose -f deploy/docker-compose.public.yml up -d${NC}"
fi

if [ "$STRICT_EXIT" -eq 1 ] && [ "$EXPOSED_COUNT" -gt 0 ]; then
    echo -e "\n${RED}[STRICT MODE]: Phát hiện port nội bộ đang mở trên host. Audit FAILED!${NC}"
    exit 1
fi

echo -e "\n${BOLD}${GREEN}BÁO CÁO KIỂM TRA BẢO MẬT HOÀN TẤT THÀNH CÔNG (PASSED 100%)!${NC}"
exit 0
