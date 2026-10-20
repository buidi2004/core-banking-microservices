#!/usr/bin/env bash
# ==============================================================================
# ⚙️ BACKEND MICROSERVICES CONTROL CLI (backend/run.sh)
# Hệ thống Ví điện tử Core Banking - 6 Microservices + Common Library
# ==============================================================================
# Danh sách Dịch vụ:
#   1. api-gateway          (:8080) - Spring Cloud Gateway & Edge Security
#   2. identity-service     (:8081) - Auth, JWT Blacklist, eKYC, Users
#   3. wallet-service       (:8082, gRPC :9090) - Balance Custody & Khóa hàng
#   4. payment-service      (:8083) - Saga Orchestrator & Giao dịch nạp/chuyển
#   5. ledger-service       (:8084) - Double-Entry Ledger (Append-Only)
#   6. notification-service (:8085) - Push Notifications & WebSocket STOMP
#   7. common-library       - Shared Kernel (Protobuf, Events, DTOs)
# ==============================================================================

set -e

BACKEND_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$BACKEND_DIR/.." && pwd)"

# Bảng mã màu ANSI
BOLD='\033[1m'
NC='\033[0m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'

print_banner() {
    clear 2>/dev/null || true
    echo -e "${CYAN}${BOLD}"
    echo "  ██████╗  █████╗  ██████╗██╗  ██╗███████╗███╗   ██╗██████╗ "
    echo "  ██╔══██╗██╔══██╗██╔════╝██║ ██╔╝██╔════╝████╗  ██║██╔══██╗"
    echo "  ██████╔╝███████║██║     █████═╝ █████╗  ██╔██╗ ██║██║  ██║"
    echo "  ██╔══██╗██╔══██║██║     ██╔═██╗ ██╔══╝  ██║╚██╗██║██║  ██║"
    echo "  ██████╔╝██║  ██║╚██████╗██║ ╚██╗███████╗██║ ╚████║██████╔╝"
    echo "  ╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝╚═════╝ "
    echo -e "${NC}"
    echo -e " ${BOLD}BỘ ĐIỀU KHIỂN BACKEND MICROSERVICES (JAVA 17 / SPRING BOOT 3)${NC}"
    echo -e " Kiến trúc: ${BLUE}Database-per-Service (5 DBs) + Event-Driven (Kafka & RabbitMQ)${NC}"
    echo -e " ----------------------------------------------------------------------------------------"
}

# Kiểm tra công cụ Maven (Native hoặc Docker fallback)
run_mvn() {
    if command -v mvn &>/dev/null; then
        mvn -f "$BACKEND_DIR/pom.xml" "$@"
    else
        echo -e "${YELLOW}ℹ️ Sử dụng Maven container (Docker fallback)...${NC}"
        docker run --rm -v ~/.m2:/root/.m2 -v "$ROOT_DIR":/app -w /app/backend maven:3.9.6-eclipse-temurin-17-alpine mvn "$@"
    fi
}

# 1. Compile Backend
cmd_compile() {
    print_banner
    echo -e "${BLUE}🔨 Đang biên dịch toàn bộ Backend (Parent, Common-Library, 6 Microservices)...${NC}\n"
    run_mvn clean compile
    echo -e "\n${GREEN}✓ Biên dịch mã nguồn Backend thành công!${NC}"
}

# 2. Package JARs
cmd_package() {
    print_banner
    echo -e "${BLUE}📦 Đang đóng gói các file JAR microservices (skip tests)...${NC}\n"
    run_mvn clean package -DskipTests
    echo -e "\n${GREEN}✓ Đóng gói các file JAR Backend thành công!${NC}"
}

# 3. Chạy Kiểm Thử (Tests)
cmd_test() {
    local target="${1:-all}"
    print_banner
    if [ "$target" == "all" ]; then
        echo -e "${BLUE}🧪 Đang chạy toàn bộ Test Suites của Backend...${NC}\n"
        run_mvn test
    else
        echo -e "${BLUE}🧪 Đang chạy Tests cho module: services/$target...${NC}\n"
        run_mvn test -pl "services/$target" -am
    fi
    echo -e "\n${GREEN}✓ Kiểm thử Backend hoàn tất thành công!${NC}"
}

# 4. Khởi động Container Backend (Docker Compose)
cmd_start() {
    print_banner
    local svc="${1:-}"
    cd "$ROOT_DIR"
    if [ -n "$svc" ]; then
        echo -e "${BLUE}🚀 Đang khởi động service: $svc...${NC}"
        docker compose up -d "$svc"
    else
        echo -e "${BLUE}🚀 Đang khởi động toàn bộ cụm Backend Microservices & Databases...${NC}"
        docker compose up -d
    fi
    cd "$BACKEND_DIR"
    cmd_status
}

# 5. Dừng Container
cmd_stop() {
    print_banner
    local svc="${1:-}"
    cd "$ROOT_DIR"
    if [ -n "$svc" ]; then
        echo -e "${YELLOW}🛑 Đang dừng service: $svc...${NC}"
        docker compose stop "$svc"
    else
        echo -e "${YELLOW}🛑 Đang dừng toàn bộ Backend & Hạ tầng Docker...${NC}"
        docker compose stop
    fi
    cd "$BACKEND_DIR"
    echo -e "${GREEN}✓ Đã dừng hoàn tất!${NC}"
}

# 6. Khởi động lại (Restart)
cmd_restart() {
    local svc="${1:-}"
    cmd_stop "$svc"
    cmd_start "$svc"
}

# 7. Kiểm tra sức khỏe & Cổng toàn diện
cmd_status() {
    echo -e "\n${BOLD}${BLUE}🔍 KIỂM TRA TRẠNG THÁI 6 MICROSERVICES & HẠ TẦNG:${NC}"
    echo -e " ----------------------------------------------------------------------------------------"
    
    local services=(
        "ewallet-api-gateway:8080:API Gateway (Routing & JWT Filter)"
        "ewallet-identity-service:8081:Identity Service (Auth & Users)"
        "ewallet-wallet-service:8082:Wallet Core Service (Balance HTTP)"
        "ewallet-wallet-service:9090:Wallet Core Service (gRPC Custody)"
        "ewallet-payment-service:8083:Payment Service (Saga & Cash Desk)"
        "ewallet-ledger-service:8084:Ledger Service (Double-Entry Sổ cái)"
        "ewallet-notification-service:8085:Notification Service (FCM & STOMP)"
        "ewallet-postgres-identity:5433:Postgres Identity DB"
        "ewallet-postgres-wallet:5434:Postgres Wallet DB"
        "ewallet-postgres-payment:5435:Postgres Payment DB"
        "ewallet-postgres-ledger:5436:Postgres Ledger DB"
        "ewallet-postgres-notification:5437:Postgres Notification DB"
        "ewallet-kafka:9092:Kafka Broker"
        "ewallet-redis:6379:Redis Cluster"
        "ewallet-rabbitmq:5672:RabbitMQ Broker"
    )

    for item in "${services[@]}"; do
        IFS=":" read -r container port name <<< "$item"
        printf "  %-42s [Port %5s] : " "$name" "$port"
        if ss -tulpn 2>/dev/null | grep -q ":$port " || nc -z localhost "$port" 2>/dev/null; then
            echo -e "${GREEN}● ONLINE (Sẵn sàng)${NC}"
        else
            echo -e "${RED}○ OFFLINE (Chưa chạy)${NC}"
        fi
    done

    echo -e "\n${BOLD}🐳 TRẠNG THÁI DOCKER CONTAINERS:${NC}"
    cd "$ROOT_DIR"
    docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || true
    cd "$BACKEND_DIR"
}

# 8. Xem Logs
cmd_logs() {
    local svc="${1:-api-gateway}"
    echo -e "\n${CYAN}📄 Đang mở logs service: $svc... (Bấm Ctrl+C để thoát)${NC}"
    cd "$ROOT_DIR"
    docker compose logs -f "$svc"
    cd "$BACKEND_DIR"
}

# 9. Menu Tương tác
interactive_menu() {
    while true; do
        print_banner
        echo -e "  ${BOLD}VUI LÒNG CHỌN MỘT THAO TÁC:${NC}"
        echo -e "  ${GREEN}1.${NC} 🚀 ${BOLD}Khởi Động Toàn Bộ Backend${NC} (Docker Compose up -d)"
        echo -e "  ${GREEN}2.${NC} 🔍 ${BOLD}Kiểm Tra Sức Khỏe & Cổng Microservices${NC} (Health & Ports)"
        echo -e "  ${GREEN}3.${NC} 🔨 ${BOLD}Biên Dịch Mã Nguồn Backend${NC} (mvn clean compile)"
        echo -e "  ${GREEN}4.${NC} 📦 ${BOLD}Đóng Gói File JAR${NC} (mvn clean package -DskipTests)"
        echo -e "  ${GREEN}5.${NC} 🧪 ${BOLD}Chạy Toàn Bộ Unit/Integration Tests${NC} (mvn test)"
        echo -e "  ${GREEN}6.${NC} 📄 ${BOLD}Xem Logs API Gateway${NC} (:8080)"
        echo -e "  ${GREEN}7.${NC} 📄 ${BOLD}Xem Logs Payment Service${NC} (:8083)"
        echo -e "  ${GREEN}8.${NC} 📄 ${BOLD}Xem Logs Wallet Service${NC} (:8082)"
        echo -e "  ${YELLOW}9.${NC} 🔄 ${BOLD}Khởi Động Lại Toàn Bộ Backend${NC}"
        echo -e "  ${RED}10.${NC} 🛑 ${BOLD}Dừng Toàn Bộ Backend${NC}"
        echo -e "  ${YELLOW}0.${NC} 🚪 ${BOLD}Thoát Menu${NC}"
        echo -e " ----------------------------------------------------------------------------------------"
        read -rp "👉 Nhập lựa chọn của bạn [0-10]: " choice

        case "$choice" in
            1) cmd_start; read -rp "Ấn Enter để tiếp tục..." ;;
            2) cmd_status; read -rp "Ấn Enter để tiếp tục..." ;;
            3) cmd_compile; read -rp "Ấn Enter để tiếp tục..." ;;
            4) cmd_package; read -rp "Ấn Enter để tiếp tục..." ;;
            5) cmd_test all; read -rp "Ấn Enter để tiếp tục..." ;;
            6) cmd_logs api-gateway ;;
            7) cmd_logs payment-service ;;
            8) cmd_logs wallet-service ;;
            9) cmd_restart; read -rp "Ấn Enter để tiếp tục..." ;;
            10) cmd_stop; read -rp "Ấn Enter để tiếp tục..." ;;
            0) echo -e "\n${GREEN}Tạm biệt!${NC}"; exit 0 ;;
            *) echo -e "${RED}Lựa chọn không hợp lệ!${NC}"; sleep 1 ;;
        esac
    done
}

# Xử lý tham số dòng lệnh
COMMAND="${1:-menu}"

case "$COMMAND" in
    compile|build)
        cmd_compile
        ;;
    package|jar)
        cmd_package
        ;;
    test)
        cmd_test "${2:-all}"
        ;;
    up|start)
        cmd_start "${2:-}"
        ;;
    down|stop)
        cmd_stop "${2:-}"
        ;;
    restart)
        cmd_restart "${2:-}"
        ;;
    status|health)
        cmd_status
        ;;
    logs)
        cmd_logs "${2:-api-gateway}"
        ;;
    menu)
        interactive_menu
        ;;
    help|-h|--help)
        echo -e "${BOLD}CÁCH SỬ DỤNG SCRIPT BACKEND:${NC}"
        echo "  ./run.sh                  Mở Menu CLI tương tác"
        echo "  ./run.sh up [svc]         Khởi động toàn bộ hoặc 1 microservice cụ thể"
        echo "  ./run.sh down [svc]       Dừng toàn bộ hoặc 1 microservice cụ thể"
        echo "  ./run.sh restart [svc]    Khởi động lại toàn bộ hoặc 1 microservice cụ thể"
        echo "  ./run.sh compile          Biên dịch toàn bộ code Java Backend"
        echo "  ./run.sh package          Đóng gói các file JAR (target/*.jar)"
        echo "  ./run.sh test [module]    Chạy test toàn bộ hoặc test module riêng"
        echo "  ./run.sh status           Kiểm tra sức khỏe cổng 8080-8085 và containers"
        echo "  ./run.sh logs [svc]       Xem realtime logs của 1 service"
        ;;
    *)
        echo -e "${RED}Lệnh không hợp lệ: $COMMAND${NC}"
        echo "Gõ './run.sh help' để xem danh sách lệnh hỗ trợ."
        exit 1
        ;;
esac

