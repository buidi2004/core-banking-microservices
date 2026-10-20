#!/usr/bin/env bash
# ==============================================================================
# 🌐 FRONTEND WEB PORTAL CONTROL CLI (frontend/run.sh)
# Cổng Giao dịch Quầy (Cash Deposit Portal) - React 18 / TypeScript / Vite
# ==============================================================================
# Chức năng:
#   1. Quản lý vòng đời Dev Server (Port 5173)
#   2. Đóng gói Production Build (Vite + TypeScript)
#   3. Xem trước bản dựng Production (Preview)
#   4. Cài đặt Dependencies & Dọn dẹp cache
#   5. Hỗ trợ tự động fallback qua Docker Node.js nếu máy chưa cài Node/NPM
# ==============================================================================

set -e

FRONTEND_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$FRONTEND_DIR/.." && pwd)"
APP_DIR="$FRONTEND_DIR/cash-deposit-portal"
PID_FILE="$FRONTEND_DIR/.fe.pid"
LOG_FILE="$FRONTEND_DIR/.fe.log"

# Bảng mã màu ANSI
BOLD='\033[1m'
NC='\033[0m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'

print_banner() {
    clear 2>/dev/null || true
    echo -e "${CYAN}${BOLD}"
    echo "  ███████╗██████╗  ██████╗ ███╗   ██╗████████╗███████╗███╗   ██╗██████╗ "
    echo "  ██╔════╝██╔══██╗██╔═══██╗████╗  ██║╚══██╔══╝██╔════╝████╗  ██║██╔══██╗"
    echo "  █████╗  ██████╔╝██║   ██║██╔██╗ ██║   ██║   █████╗  ██╔██╗ ██║██║  ██║"
    echo "  ██╔══╝  ██╔══██╗██║   ██║██║╚██╗██║   ██║   ██╔══╝  ██║╚██╗██║██║  ██║"
    echo "  ██║     ██║  ██║╚██████╔╝██║ ╚████║   ██║   ███████╗██║ ╚████║██████╔╝"
    echo "  ╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═══╝╚═════╝ "
    echo -e "${NC}"
    echo -e " ${BOLD}BỘ ĐIỀU KHIỂN FRONTEND REACT VITE (TELLER PORTAL)${NC}"
    echo -e " Cổng Dịch Vụ: ${CYAN}http://localhost:5173${NC} | Kết nối Gateway: ${CYAN}http://localhost:8080${NC}"
    echo -e " ----------------------------------------------------------------------------------------"
}

# Chạy lệnh npm (Hỗ trợ Node native hoặc Docker node:18-alpine fallback)
run_npm() {
    if command -v npm &>/dev/null; then
        (cd "$APP_DIR" && npm "$@")
    else
        echo -e "${YELLOW}ℹ️ Không tìm thấy Node/NPM cục bộ. Sử dụng container node:18-alpine...${NC}"
        docker run --rm \
            -v "$APP_DIR":/app \
            -w /app \
            -p 5173:5173 \
            node:18-alpine npm "$@"
    fi
}

# 1. Khởi động Dev Server chạy nền (Background)
cmd_start_bg() {
    print_banner
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo -e "  ${YELLOW}⚠️ Frontend đang chạy tại PID: $(cat "$PID_FILE")${NC}"
        echo -e "  👉 Truy cập: ${BOLD}${CYAN}http://localhost:5173${NC}"
        return 0
    fi

    # Giải phóng port 5173 nếu có tiến trình chiếm dụng
    if ss -tulpn 2>/dev/null | grep -q ":5173 "; then
        echo -e "  ${YELLOW}⚠️ Port 5173 đang bị chiếm dụng. Đang giải phóng...${NC}"
        fuser -k 5173/tcp 2>/dev/null || true
        sleep 1
    fi

    echo -e "${BLUE}🚀 Đang khởi động Vite Dev Server trên cổng 5173...${NC}"
    if command -v npm &>/dev/null; then
        cd "$APP_DIR"
        nohup npm run dev -- --host 0.0.0.0 --port 5173 > "$LOG_FILE" 2>&1 &
        local pid=$!
        echo "$pid" > "$PID_FILE"
        cd "$FRONTEND_DIR"
    else
        # Khởi chạy qua Docker Container chạy nền
        docker rm -f ewallet-frontend-dev 2>/dev/null || true
        docker run -d --name ewallet-frontend-dev \
            -v "$APP_DIR":/app \
            -w /app \
            -p 5173:5173 \
            node:18-alpine npm run dev -- --host 0.0.0.0 --port 5173
    fi

    sleep 2
    cmd_status
}

# 2. Khởi động Dev Server trực tiếp (Foreground)
cmd_dev() {
    print_banner
    echo -e "${BLUE}🚀 Khởi chạy Vite Dev Server ở chế độ tương tác trực tiếp...${NC}"
    echo -e "👉 Bấm ${BOLD}Ctrl + C${NC} để dừng server.\n"
    run_npm run dev -- --host 0.0.0.0 --port 5173
}

# 3. Dừng Dev Server
cmd_stop() {
    print_banner
    echo -e "${YELLOW}🛑 Đang dừng Frontend Dev Server...${NC}"
    if [ -f "$PID_FILE" ]; then
        local pid
        pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null || true
            sleep 1
            kill -9 "$pid" 2>/dev/null || true
        fi
        rm -f "$PID_FILE"
    fi
    docker rm -f ewallet-frontend-dev 2>/dev/null || true
    fuser -k 5173/tcp 2>/dev/null || true
    echo -e "${GREEN}✓ Đã dừng Frontend thành công!${NC}"
}

# 4. Đóng gói Production Build
cmd_build() {
    print_banner
    echo -e "${BLUE}🔨 Đang kiểm tra TypeScript và đóng gói Production (dist/)...${NC}\n"
    run_npm run build
    echo -e "\n${GREEN}✓ Build thành công! Thư mục đầu ra: frontend/cash-deposit-portal/dist/${NC}"
}

# 5. Xem trước bản dựng Production (Preview)
cmd_preview() {
    print_banner
    echo -e "${BLUE}👁️ Đang mở Vite Preview cho bản dựng Production...${NC}\n"
    run_npm run preview -- --host 0.0.0.0 --port 4173
}

# 6. Cài đặt Dependencies
cmd_install() {
    print_banner
    echo -e "${BLUE}📥 Đang cài đặt thư viện dependencies (npm install)...${NC}\n"
    run_npm install
    echo -e "\n${GREEN}✓ Cài đặt thư viện Frontend thành công!${NC}"
}

# 7. Dọn dẹp Cache và Build artifacts
cmd_clean() {
    print_banner
    echo -e "${YELLOW}🧹 Đang dọn dẹp thư mục dist/ và build cache...${NC}"
    rm -rf "$APP_DIR/dist" "$APP_DIR/.vite" "$PID_FILE" "$LOG_FILE"
    echo -e "${GREEN}✓ Dọn dẹp hoàn tất!${NC}"
}

# 8. Kiểm tra trạng thái Frontend
cmd_status() {
    echo -e "\n${BOLD}${BLUE}🔍 TRẠNG THÁI FRONTEND CASH DEPOSIT PORTAL:${NC}"
    echo -e " ----------------------------------------------------------------------------------------"
    printf "  %-38s [Port  5173] : " "Vite Dev Server"
    if ss -tulpn 2>/dev/null | grep -q ":5173 "; then
        echo -e "${GREEN}● ONLINE (Đang chạy)${NC}"
        echo -e "  👉 TRUY CẬP NGAY: ${BOLD}${CYAN}http://localhost:5173${NC}"
    else
        echo -e "${RED}○ OFFLINE (Chưa chạy)${NC}"
    fi

    # Kiểm tra kết nối API Gateway
    printf "  %-38s [Port  8080] : " "API Gateway Downstream"
    if nc -z localhost 8080 2>/dev/null || curl -s -m 2 http://localhost:8080/actuator/health &>/dev/null; then
        echo -e "${GREEN}● SẴN SÀNG (Đã kết nối Backend)${NC}"
    else
        echo -e "${YELLOW}⚠️ CHƯA SẴN SÀNG (Vui lòng khởi động Backend trước)${NC}"
    fi
}

# 9. Xem logs
cmd_logs() {
    if [ -f "$LOG_FILE" ]; then
        echo -e "\n${CYAN}📄 Đang mở logs Frontend ($LOG_FILE)... (Bấm Ctrl+C để thoát)${NC}"
        tail -f "$LOG_FILE"
    elif docker ps -a | grep -q ewallet-frontend-dev; then
        echo -e "\n${CYAN}📄 Đang mở logs Docker container ewallet-frontend-dev... (Bấm Ctrl+C để thoát)${NC}"
        docker logs -f ewallet-frontend-dev
    else
        echo -e "${YELLOW}⚠️ Chưa có file log hoặc server chưa được khởi chạy ngầm.${NC}"
    fi
}

# Menu CLI Tương Tác
interactive_menu() {
    while true; do
        print_banner
        echo -e "  ${BOLD}VUI LÒNG CHỌN MỘT THAO TÁC:${NC}"
        echo -e "  ${GREEN}1.${NC} 🚀 ${BOLD}Khởi Động Dev Server Chạy Nền${NC} (Port 5173)"
        echo -e "  ${GREEN}2.${NC} 💻 ${BOLD}Khởi Chạy Dev Server Trực Tiếp${NC} (npm run dev tương tác)"
        echo -e "  ${GREEN}3.${NC} 🔍 ${BOLD}Kiểm Tra Trạng Thái Sức Khỏe & Cổng${NC} (Port 5173 & Gateway)"
        echo -e "  ${GREEN}4.${NC} 🔨 ${BOLD}Đóng Gói Bản Dựng Production${NC} (npm run build)"
        echo -e "  ${GREEN}5.${NC} 👁️ ${BOLD}Xem Trước Bản Dựng Production${NC} (npm run preview)"
        echo -e "  ${GREEN}6.${NC} 📥 ${BOLD}Cài Đặt Lại Dependencies${NC} (npm install)"
        echo -e "  ${BLUE}7.${NC} 📄 ${BOLD}Xem Logs Frontend Server${NC}"
        echo -e "  ${YELLOW}8.${NC} 🧹 ${BOLD}Dọn Dẹp Build Cache & Dist${NC}"
        echo -e "  ${RED}9.${NC} 🛑 ${BOLD}Dừng Frontend Server${NC}"
        echo -e "  ${YELLOW}0.${NC} 🚪 ${BOLD}Thoát Menu${NC}"
        echo -e " ----------------------------------------------------------------------------------------"
        read -rp "👉 Nhập lựa chọn của bạn [0-9]: " choice

        case "$choice" in
            1) cmd_start_bg; read -rp "Ấn Enter để tiếp tục..." ;;
            2) cmd_dev ;;
            3) cmd_status; read -rp "Ấn Enter để tiếp tục..." ;;
            4) cmd_build; read -rp "Ấn Enter để tiếp tục..." ;;
            5) cmd_preview; read -rp "Ấn Enter để tiếp tục..." ;;
            6) cmd_install; read -rp "Ấn Enter để tiếp tục..." ;;
            7) cmd_logs ;;
            8) cmd_clean; read -rp "Ấn Enter để tiếp tục..." ;;
            9) cmd_stop; read -rp "Ấn Enter để tiếp tục..." ;;
            0) echo -e "\n${GREEN}Tạm biệt!${NC}"; exit 0 ;;
            *) echo -e "${RED}Lựa chọn không hợp lệ!${NC}"; sleep 1 ;;
        esac
    done
}

# Xử lý tham số dòng lệnh
COMMAND="${1:-menu}"

case "$COMMAND" in
    dev)
        cmd_dev
        ;;
    start|up)
        cmd_start_bg
        ;;
    stop|down)
        cmd_stop
        ;;
    build)
        cmd_build
        ;;
    preview)
        cmd_preview
        ;;
    install|i)
        cmd_install
        ;;
    clean)
        cmd_clean
        ;;
    status|health)
        cmd_status
        ;;
    logs)
        cmd_logs
        ;;
    menu)
        interactive_menu
        ;;
    help|-h|--help)
        echo -e "${BOLD}CÁCH SỬ DỤNG SCRIPT FRONTEND:${NC}"
        echo "  ./run.sh                  Mở Menu CLI tương tác"
        echo "  ./run.sh start            Khởi động Vite Dev Server chạy nền (Background)"
        echo "  ./run.sh dev              Khởi động Dev Server tương tác trực tiếp"
        echo "  ./run.sh stop             Dừng Dev Server"
        echo "  ./run.sh status           Kiểm tra trạng thái cổng 5173 và kết nối Gateway"
        echo "  ./run.sh build            Biên dịch kiểm tra Type và đóng gói dist/"
        echo "  ./run.sh preview          Xem trước bản build production trên port 4173"
        echo "  ./run.sh install          Cài đặt thư viện dependencies (npm install)"
        echo "  ./run.sh clean            Dọn dẹp thư mục dist/ và cache .vite"
        echo "  ./run.sh logs             Xem realtime logs của dev server"
        ;;
    *)
        echo -e "${RED}Lệnh không hợp lệ: $COMMAND${NC}"
        echo "Gõ './run.sh help' để xem danh sách lệnh hỗ trợ."
        exit 1
        ;;
esac

