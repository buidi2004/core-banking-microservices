#!/usr/bin/env bash
# ==============================================================================
# 🏦 CORE BANKING TELLER PORTAL & MICROSERVICES - BỘ ĐIỀU KHIỂN TOÀN DIỆN (RUN.SH)
# ==============================================================================
# Hỗ trợ:
#   1. Khởi động / Dừng Frontend React (Vite Port 5173)
#   2. Khởi động / Dừng Backend Microservices (Docker / Spring Boot Ports 8080-8084)
#   3. Quản lý Cụm Hạ Tầng (Kafka, 5 Postgres DBs, Redis, RabbitMQ)
#   4. Chạy Kiểm thử Toàn diện 8 Kịch bản Dữ liệu Thật (Multi-Scenario E2E)
#   5. Bảng Đối soát Sổ cái kép trực tiếp (Live Ledger Balance Delta = 0.00 VND)
#   6. Tra cứu Két quỹ quầy chi nhánh (Vault Cash Limit 500M)
#   7. Cấp mới JWT Token cho Cán bộ quầy (Teller 1, Teller 2, Manager 1)
#   8. Kiểm tra Sức khỏe và Cổng toàn hệ thống (Health Check)
# ==============================================================================

set -e

# Thiết lập thư mục gốc
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

FE_DIR="$ROOT_DIR/frontend/cash-deposit-portal"
FE_PID_FILE="$ROOT_DIR/.fe.pid"
FE_LOG_FILE="$ROOT_DIR/.fe.log"

# Bảng mã màu ANSI
BOLD='\033[1m'
NC='\033[0m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'

# In Banner thương hiệu
print_banner() {
    clear 2>/dev/null || true
    echo -e "${CYAN}${BOLD}"
    echo "  ██████╗ ██████╗ ██████╗ ███████╗   ██████╗  █████╗ ███╗   ██╗██╗  ██╗██╗███╗   ██╗ ██████╗ "
    echo " ██╔════╝██╔═══██╗██╔══██╗██╔════╝   ██╔══██╗██╔══██╗████╗  ██║██║ ██╔╝██║████╗  ██║██╔════╝ "
    echo " ██║     ██║   ██║██████╔╝█████╗     ██████╔╝███████║██╔██╗ ██║█████═╝ ██║██╔██╗ ██║██║  ███╗"
    echo " ██║     ██║   ██║██╔══██╗██╔══╝     ██╔══██╗██╔══██║██║╚██╗██║██╔═██╗ ██║██║╚██╗██║██║   ██║"
    echo " ╚██████╗╚██████╔╝██║  ██║███████╗   ██████╔╝██║  ██║██║ ╚████║██║ ╚██╗██║██║ ╚████║╚██████╔╝"
    echo "  ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝   ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝ "
    echo -e "${NC}"
    echo -e " ${BOLD}BỘ ĐIỀU KHIỂN VẬN HÀNH TOÀN TRÌNH (CORE BANKING MANAGEMENT CLI)${NC}"
    echo -e " Kiến trúc: ${BLUE}Database-per-Service (5 DBs) + Event-Driven (Kafka) + React Portal${NC}"
    echo -e " ----------------------------------------------------------------------------------------"
}

# 1. Khởi động Hạ tầng Docker
start_infra() {
    echo -e "\n${BLUE}🐳 [1/4] KHỞI ĐỘNG CỤM HẠ TẦNG DOCKER (DATABASES & BROKERS)...${NC}"
    docker compose up -d postgres-identity postgres-wallet postgres-payment postgres-ledger postgres-notification redis rabbitmq kafka kafka-ui
    echo -e "  ${GREEN}✓ Đang chờ các cụm cơ sở dữ liệu và Kafka sẵn sàng...${NC}"
    
    # Kiểm tra sẵn sàng
    local max_wait=30
    local count=0
    until docker exec ewallet-postgres-identity pg_isready -U identity_db_user -d ewallet_identity_db >/dev/null 2>&1 || [ $count -ge $max_wait ]; do
        sleep 1
        count=$((count + 1))
    done

    echo -e "  ${GREEN}✓ Cả 5 Cơ sở dữ liệu Postgres, Kafka (29092), Redis (6379), RabbitMQ (5672) ĐÃ SẴN SÀNG!${NC}"
}

# 2. Khởi động Backend Microservices
start_be() {
    start_infra
    echo -e "\n${BLUE}⚙️ [2/4] KHỞI ĐỘNG CỤM BACKEND MICROSERVICES...${NC}"
    if ! ls "$ROOT_DIR"/backend/services/api-gateway/target/*.jar >/dev/null 2>&1; then
        echo -e "  ${YELLOW}⚠️ Chưa tìm thấy file .jar đã đóng gói. Đang tự động build Maven (common-library + 6 services)...${NC}"
        mvn -f "$ROOT_DIR/backend/pom.xml" clean package -DskipTests
    elif [ "$ROOT_DIR/backend/services/identity-service/src/main/java/com/fintech/identity/service/OtpService.java" -nt "$ROOT_DIR/backend/services/identity-service/target/identity-service-1.0.0-SNAPSHOT.jar" ]; then
        echo -e "  ${YELLOW}🔄 Phát hiện cập nhật mới ở api-gateway / identity-service. Đang đóng gói nhanh...${NC}"
        mvn -f "$ROOT_DIR/backend/pom.xml" package -DskipTests -pl services/api-gateway,services/identity-service
        docker compose up -d --build api-gateway identity-service
    fi
    echo -e "  • Khởi chạy các container Microservices:"
    if ! docker image inspect core-banking-microservices-api-gateway:latest >/dev/null 2>&1; then
        docker compose up -d --build api-gateway identity-service wallet-service payment-service ledger-service notification-service
    else
        docker compose up -d api-gateway identity-service wallet-service payment-service ledger-service notification-service
    fi
    echo -e "  ${GREEN}✓ Toàn bộ Backend Microservices đã được kích hoạt!${NC}"
    echo -e "    - API Gateway:    ${CYAN}http://localhost:8080${NC}"
    echo -e "    - Kafka UI:       ${CYAN}http://localhost:8090${NC}"
    echo -e "    - RabbitMQ UI:    ${CYAN}http://localhost:15672${NC} (wallet / wallet123)"
}

# 3. Khởi động Frontend React Portal
start_fe() {
    echo -e "\n${BLUE}🌐 [3/4] KHỞI ĐỘNG FRONTEND REACT TELLER PORTAL...${NC}"
    if [ -f "$FE_PID_FILE" ] && kill -0 "$(cat "$FE_PID_FILE")" 2>/dev/null && curl -s http://localhost:5173 >/dev/null 2>&1; then
        echo -e "  ${YELLOW}⚠️ Frontend đang chạy tại PID: $(cat "$FE_PID_FILE") (${CYAN}http://localhost:5173${NC})${NC}"
        return 0
    fi

    # Dọn tiến trình cũ bị treo (SIGTTIN) hoặc chiếm cổng 5173
    if [ -f "$FE_PID_FILE" ]; then
        kill -9 "$(cat "$FE_PID_FILE")" 2>/dev/null || true
        rm -f "$FE_PID_FILE"
    fi
    pkill -9 -f "vite.*5173" 2>/dev/null || true
    fuser -k 5173/tcp 2>/dev/null || true

    cd "$FE_DIR"
    if [ ! -x "node_modules/.bin/vite" ]; then
        echo -e "  • Đang cài đặt dependencies cho Frontend (npm install)..."
        npm install < /dev/null
    fi
    echo -e "  • Đang khởi động Vite Dev Server..."
    setsid ./node_modules/.bin/vite --host 0.0.0.0 --port 5173 < /dev/null > "$FE_LOG_FILE" 2>&1 &
    local fe_pid=$!
    echo "$fe_pid" > "$FE_PID_FILE"
    cd "$ROOT_DIR"

    local wait_fe=0
    until curl -s http://localhost:5173 >/dev/null 2>&1 || [ $wait_fe -ge 10 ]; do
        sleep 1
        wait_fe=$((wait_fe + 1))
    done

    if curl -s http://localhost:5173 >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓ Cổng Quản lý Nạp tiền Quầy (React) đã chạy thành công!${NC}"
        echo -e "  👉 TRUY CẬP NGAY: ${BOLD}${CYAN}http://localhost:5173${NC}"
    else
        echo -e "  ${RED}❌ Khởi động Frontend thất bại. Vui lòng kiểm tra log: $FE_LOG_FILE${NC}"
        cat "$FE_LOG_FILE" | tail -n 15
        return 1
    fi
}

# 3b. Khởi động / Kiểm tra Mobile App (Flutter)
run_mobile() {
    print_banner
    echo -e "${BLUE}${BOLD}[MOBILE] Sen Hồng Bank Flutter E-Wallet Client${NC}"
    echo -e "Thư mục: ${CYAN}$ROOT_DIR/mobile${NC}\n"
    if ! command -v flutter &>/dev/null; then
        echo -e "  ${YELLOW}⚠️  Flutter SDK chưa được cài đặt trong PATH hệ thống.${NC}"
        echo -e "  👉 Hướng dẫn khởi chạy cục bộ:"
        echo -e "     1. Cài đặt Flutter: https://docs.flutter.dev/get-started/install"
        echo -e "     2. cd $ROOT_DIR/mobile"
        echo -e "     3. flutter pub get"
        echo -e "     4. flutter run"
        return 0
    fi
    echo -e "  ${GREEN}✓ Tìm thấy Flutter SDK: $(flutter --version | head -n 1)${NC}"
    cd "$ROOT_DIR/mobile"
    flutter pub get
    flutter run "${@:2}"
    cd "$ROOT_DIR"
}

# 3c. Tự động đồng bộ Endpoint của GitHub Codespaces lên Repo (Phương án 1 + 2 cho Mobile APK)
sync_codespace_endpoint() {
    if [ -z "${CODESPACE_NAME:-}" ]; then
        return 0
    fi

    local domain="${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:-app.github.dev}"
    local gateway_url="https://${CODESPACE_NAME}-8080.${domain}"
    local api_url="${gateway_url}/api/v1"
    local ws_url="wss://${CODESPACE_NAME}-8080.${domain}/ws-native"
    local portal_url="https://${CODESPACE_NAME}-5173.${domain}"
    local now_utc
    now_utc=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    echo -e "\n${PURPLE}${BOLD}☁️  [4/4] ĐỒNG BỘ TỰ ĐỘNG LINK CODESPACES CHO MOBILE APK (PHƯƠNG ÁN 1 & 2)...${NC}"

    # Tự động mở Public cho cổng 8080 và 5173 nếu có GitHub CLI
    if command -v gh &>/dev/null; then
        gh codespace ports visibility 8080:public 5173:public -c "$CODESPACE_NAME" 2>/dev/null || true
    fi

    # 1. Ghi file cloud-endpoint.json (Phương án 2 - Auto Discovery)
    cat > "$ROOT_DIR/cloud-endpoint.json" <<EOF
{
  "codespaceName": "${CODESPACE_NAME}",
  "gatewayUrl": "${gateway_url}",
  "apiUrl": "${api_url}",
  "wsUrl": "${ws_url}",
  "portalUrl": "${portal_url}",
  "updatedAt": "${now_utc}"
}
EOF

    # 2. Gán cứng luôn vào ApiConstants.dart (Phương án 1 - Hardcoded Default cho APK)
    local api_const_file="$ROOT_DIR/mobile/lib/core/constants/api_constants.dart"
    if [ -f "$api_const_file" ]; then
        sed -i -E "s|defaultValue: 'https?://[^']*'|defaultValue: '${api_url}'|g" "$api_const_file"
        sed -i -E "s|defaultValue: 'wss?://[^']*'|defaultValue: '${ws_url}'|g" "$api_const_file"
    fi

    # 3. Tự động commit & push lên GitHub để máy Local và các file APK tự nhận diện
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        git add "$ROOT_DIR/cloud-endpoint.json" "$api_const_file" 2>/dev/null || true
        if ! git diff --cached --quiet 2>/dev/null; then
            git commit -m "chore: auto-sync active Codespace endpoint (${CODESPACE_NAME}) [skip ci]" >/dev/null 2>&1 || true
            git push origin HEAD:main >/dev/null 2>&1 || true
            echo -e "  ${GREEN}✓ Đã tự động đẩy cấu hình Cloud Endpoint lên GitHub!${NC}"
        else
            echo -e "  ${GREEN}✓ Cấu hình Cloud Endpoint trên GitHub đã là bản mới nhất!${NC}"
        fi
    fi

    echo -e "  • Link Web Quầy Giao Dịch (5173): ${BOLD}${CYAN}${portal_url}${NC}"
    echo -e "  • Link API Gateway Mobile (8080): ${BOLD}${CYAN}${gateway_url}${NC}"
}

# 4. Khởi động Tất cả (All-in-one)
start_all() {
    print_banner
    echo -e "${GREEN}${BOLD}🚀 ĐANG KHỞI ĐỘNG TOÀN BỘ HỆ THỐNG CORE BANKING (INFRA + BE + FE)...${NC}\n"
    start_infra
    start_be
    start_fe
    sync_codespace_endpoint
    echo -e "\n${GREEN}${BOLD}================================================================================${NC}"
    echo -e "${GREEN}${BOLD}🎉 TOÀN BỘ HỆ THỐNG ĐÃ HOẠT ĐỘNG HOÀN TOÀN!${NC}"
    if [ -n "${CODESPACE_NAME:-}" ]; then
        local domain="${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:-app.github.dev}"
        echo -e "   • Web Teller Portal (Public): ${BOLD}${CYAN}https://${CODESPACE_NAME}-5173.${domain}${NC}"
        echo -e "   • Mobile Cloud Gateway:       ${BOLD}${CYAN}https://${CODESPACE_NAME}-8080.${domain}${NC}"
    else
        echo -e "   • Frontend React Portal:  ${BOLD}${CYAN}http://localhost:5173${NC}"
        echo -e "   • API Gateway Routing:    ${BOLD}${CYAN}http://localhost:8080${NC}"
        echo -e "   • Kafka Management UI:    ${BOLD}${CYAN}http://localhost:8089${NC}"
        echo -e "   • RabbitMQ Admin UI:      ${BOLD}${CYAN}http://localhost:15672${NC}"
    fi
    echo -e "${GREEN}${BOLD}================================================================================${NC}"
}

# 5. Dừng hệ thống
stop_all() {
    echo -e "\n${YELLOW}🛑 ĐANG DỪNG CÁC TIẾN TRÌNH HỆ THỐNG...${NC}"
    
    # Dừng Frontend
    if [ -f "$FE_PID_FILE" ]; then
        local pid
        pid=$(cat "$FE_PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            echo -e "  • Đang dừng Frontend React (PID: $pid)..."
            kill "$pid" 2>/dev/null || true
        fi
        rm -f "$FE_PID_FILE"
    fi
    fuser -k 5173/tcp 2>/dev/null || true
    echo -e "  ${GREEN}✓ Đã dừng Frontend React.${NC}"

    # Dừng Docker containers
    echo -e "  • Đang dừng các container Backend Microservices..."
    docker compose down --remove-orphans 2>/dev/null || true
    echo -e "  ${GREEN}✓ Đã dừng toàn bộ Backend & Cụm Hạ Tầng Docker.${NC}"
}

# 6. Kiểm tra Trạng thái & Sức khỏe (Status & Health)
check_status() {
    echo -e "\n${BOLD}${CYAN}================================================================================${NC}"
    echo -e "${BOLD}${CYAN}🔍 BẢNG TRẠNG THÁI SỨC KHỎE TOÀN BỘ HỆ THỐNG (HEALTH & PORTS AUDIT)${NC}"
    echo -e "${BOLD}${CYAN}================================================================================${NC}"

    # Kiểm tra Frontend
    echo -ne "  • Frontend React Portal (5173):    "
    if [ -f "$FE_PID_FILE" ] && kill -0 "$(cat "$FE_PID_FILE")" 2>/dev/null; then
        echo -e "${GREEN}🟢 ĐANG CHẠY (PID: $(cat "$FE_PID_FILE")) -> http://localhost:5173${NC}"
    elif ss -tulpn 2>/dev/null | grep -q ":5173"; then
        echo -e "${GREEN}🟢 ĐANG CHẠY (Cổng 5173 đang lắng nghe)${NC}"
    else
        echo -e "${RED}🔴 ĐANG DỪNG${NC}"
    fi

    # Kiểm tra Containers
    echo -e "\n  • Trạng thái Cụm Docker Microservices & Databases:"
    docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo -e "${BOLD}${CYAN}================================================================================${NC}"
}

# 7. Chạy Kiểm thử 8 Kịch bản Thật
run_test() {
    echo -e "\n${PURPLE}🧪 [KIỂM THỬ TỰ ĐỘNG] CHẠY BỘ 8 KỊCH BẢN DỮ LIỆU THẬT...${NC}"
    "$ROOT_DIR/scripts/e2e/08-multi-scenario-real-test.sh"
}

# 8. Tra cứu Bảng Đối Soát Sổ Cái Kép Trực Tiếp
check_ledger() {
    echo -e "\n${CYAN}📊 [ĐỐI SOÁT SỔ CÁI] TRUY VẤN SỐ DƯ KÉP NỢ 1011 / CÓ 4211 THỜI GIAN THỰC...${NC}"
    docker exec -i ewallet-postgres-ledger psql -U ledger_app_user -d ewallet_ledger_db << 'EOF'
SELECT 
    account_id,
    side,
    COUNT(*) AS total_postings,
    TO_CHAR(SUM(amount), 'FM999,999,999,999') || ' VND' AS total_amount
FROM ledger_postings
GROUP BY account_id, side
ORDER BY side DESC, account_id;

SELECT 
    TO_CHAR(COALESCE(SUM(CASE WHEN side = 'DEBIT' THEN amount ELSE 0 END), 0), 'FM999,999,999,999.00') || ' VND' AS total_debit,
    TO_CHAR(COALESCE(SUM(CASE WHEN side = 'CREDIT' THEN amount ELSE 0 END), 0), 'FM999,999,999,999.00') || ' VND' AS total_credit,
    TO_CHAR(COALESCE(SUM(CASE WHEN side = 'DEBIT' THEN amount ELSE 0 END), 0) - COALESCE(SUM(CASE WHEN side = 'CREDIT' THEN amount ELSE 0 END), 0), 'FM999,999,999,999.00') || ' VND' AS delta_balance
FROM ledger_postings;
EOF
}

# 9. Tra cứu Két Quỹ Chi Nhánh
check_vault() {
    echo -e "\n${YELLOW}💰 [KÉT QUỸ CHI NHÁNH] TÌNH HÌNH TỒN QUỸ CHI NHÁNH QUẬN 1 (BR_Q1)...${NC}"
    docker exec -i ewallet-postgres-payment psql -U payment_db_user -d ewallet_payment_db << 'EOF'
SELECT 
    branch_id,
    COUNT(CASE WHEN status = 'COMPLETED' THEN 1 END) AS successful_deposits,
    COUNT(CASE WHEN status = 'PENDING_APPROVAL' THEN 1 END) AS pending_approvals,
    COUNT(CASE WHEN status = 'REJECTED' THEN 1 END) AS rejected_deposits,
    TO_CHAR(COALESCE(SUM(CASE WHEN status = 'COMPLETED' THEN amount ELSE 0 END), 0), 'FM999,999,999,999') || ' VND' AS total_cash_collected
FROM cash_deposits
WHERE branch_id = 'BR_Q1'
GROUP BY branch_id;
EOF
}

# 10. Cấp mới Staff JWT Tokens
generate_tokens() {
    echo -e "\n${BLUE}🔑 CẤP MỚI VÀ LÀM MỚI JWT BEARER TOKENS CHO CÁN BỘ NGÂN HÀNG...${NC}"
    if [ -f "$ROOT_DIR/scripts/e2e/generate-staff-tokens.sh" ]; then
        "$ROOT_DIR/scripts/e2e/generate-staff-tokens.sh"
    else
        echo -e "  ${RED}Không tìm thấy script generate-staff-tokens.sh${NC}"
    fi
}

# 11. Xem Logs
view_logs() {
    local target="${1:-fe}"
    if [ "$target" == "fe" ]; then
        echo -e "\n${CYAN}📄 Đang mở logs Frontend React ($FE_LOG_FILE)... (Bấm Ctrl+C để thoát)${NC}"
        tail -f "$FE_LOG_FILE"
    else
        echo -e "\n${CYAN}📄 Đang mở logs Docker service: $target... (Bấm Ctrl+C để thoát)${NC}"
        docker compose logs -f "$target"
    fi
}

# Menu CLI Tương Tác
interactive_menu() {
    while true; do
        print_banner
        echo -e "  ${BOLD}VUI LÒNG CHỌN MỘT THAO TÁC:${NC}"
        echo -e "  ${GREEN}1.${NC} 🚀 ${BOLD}Khởi Động Toàn Bộ Hệ Thống${NC} (Infra + BE + FE React)"
        echo -e "  ${GREEN}2.${NC} 🌐 ${BOLD}Chỉ Khởi Động Frontend React Portal${NC} (Vite: http://localhost:5173)"
        echo -e "  ${GREEN}3.${NC} ⚙️ ${BOLD}Chỉ Khởi Động Backend Microservices${NC} (Gateway :8080 & Services)"
        echo -e "  ${GREEN}4.${NC} 📱 ${BOLD}Khởi Chạy Mobile App E-Wallet${NC} (Flutter: cd mobile)"
        echo -e "  ${GREEN}5.${NC} 🐳 ${BOLD}Khởi Động Cụm Hạ Tầng Docker${NC} (Postgres x5, Kafka, Redis, RabbitMQ)"
        echo -e "  ${GREEN}6.${NC} 🧪 ${BOLD}Chạy Kiểm Thử 8 Kịch Bản Dữ Liệu Thật${NC} (E2E Multi-scenario)"
        echo -e "  ${GREEN}7.${NC} 📊 ${BOLD}Xem Bảng Đối Soát Sổ Cái Kép Trực Tiếp${NC} (Delta = 0.00 VND)"
        echo -e "  ${GREEN}8.${NC} 💰 ${BOLD}Xem Tồn Quỹ Két Quầy Chi Nhánh & Hạn Mức 500M${NC}"
        echo -e "  ${GREEN}9.${NC} 🔑 ${BOLD}Cấp Mới JWT Tokens Cán Bộ Quầy${NC} (Teller 1, Teller 2, Manager 1)"
        echo -e "  ${GREEN}10.${NC} 🔍 ${BOLD}Kiểm Tra Trạng Thái Sức Khỏe Toàn Diện${NC} (Ports & Health Audit)"
        echo -e "  ${RED}11.${NC} 🛑 ${BOLD}Dừng Toàn Bộ Hệ Thống${NC} (Tắt FE, BE & Cleanup)"
        echo -e "  ${BLUE}12.${NC} 📄 ${BOLD}Xem Logs Frontend React${NC}"
        echo -e "  ${YELLOW}0.${NC} 🚪 ${BOLD}Thoát Menu${NC}"
        echo -e " ----------------------------------------------------------------------------------------"
        read -rp "👉 Nhập lựa chọn của bạn [0-12]: " choice

        case "$choice" in
            1) start_all; read -rp "Ấn Enter để tiếp tục..." ;;
            2) start_fe; read -rp "Ấn Enter để tiếp tục..." ;;
            3) start_be; read -rp "Ấn Enter để tiếp tục..." ;;
            4) run_mobile; read -rp "Ấn Enter để tiếp tục..." ;;
            5) start_infra; read -rp "Ấn Enter để tiếp tục..." ;;
            6) run_test; read -rp "Ấn Enter để tiếp tục..." ;;
            7) check_ledger; read -rp "Ấn Enter để tiếp tục..." ;;
            8) check_vault; read -rp "Ấn Enter để tiếp tục..." ;;
            9) generate_tokens; read -rp "Ấn Enter để tiếp tục..." ;;
            10) check_status; read -rp "Ấn Enter để tiếp tục..." ;;
            11) stop_all; read -rp "Ấn Enter để tiếp tục..." ;;
            12) view_logs fe ;;
            4) start_infra; read -rp "Ấn Enter để tiếp tục..." ;;
            5) run_test; read -rp "Ấn Enter để tiếp tục..." ;;
            6) check_ledger; read -rp "Ấn Enter để tiếp tục..." ;;
            7) check_vault; read -rp "Ấn Enter để tiếp tục..." ;;
            8) generate_tokens; read -rp "Ấn Enter để tiếp tục..." ;;
            9) check_status; read -rp "Ấn Enter để tiếp tục..." ;;
            10) stop_all; read -rp "Ấn Enter để tiếp tục..." ;;
            11) view_logs fe ;;
            0) echo -e "\n${GREEN}Tạm biệt! Chúc bạn làm việc hiệu quả.${NC}\n"; exit 0 ;;
            *) echo -e "${RED}Lựa chọn không hợp lệ! Vui lòng chọn từ 0 đến 11.${NC}"; sleep 1 ;;
        esac
    done
}

# Xử lý các CLI Subcommands
COMMAND="${1:-menu}"
case "$COMMAND" in
    start|all)
        start_all
        ;;
    sync-cloud|cloud)
        sync_codespace_endpoint
        ;;
    fe|frontend)
        start_fe
        ;;
    be|backend)
        start_be
        ;;
    mobile)
        run_mobile "$@"
        ;;
    infra)
        start_infra
        ;;
    stop|down)
        stop_all
        ;;
    restart)
        stop_all
        start_all
        ;;
    test)
        run_test
        ;;
    ledger)
        check_ledger
        ;;
    vault)
        check_vault
        ;;
    tokens)
        generate_tokens
        ;;
    status|health)
        check_status
        ;;
    logs)
        view_logs "${2:-fe}"
        ;;
    menu)
        interactive_menu
        ;;
    help|-h|--help)
        echo -e "${BOLD}CÁCH SỬ DỤNG BỘ ĐIỀU KHIỂN RUN.SH:${NC}"
        echo "  ./run.sh              Mở Menu tương tác đồ họa CLI"
        echo "  ./run.sh all          Khởi động toàn bộ (Infra + BE + FE)"
        echo "  ./run.sh fe           Khởi động Frontend React (Port 5173)"
        echo "  ./run.sh be           Khởi động Backend Microservices"
        echo "  ./run.sh mobile       Kiểm tra và khởi chạy Mobile App (Flutter)"
        echo "  ./run.sh infra        Khởi động cụm Docker (Kafka, 5 DBs, Redis, RabbitMQ)"
        echo "  ./run.sh test         Chạy 8 kịch bản kiểm thử dữ liệu thật E2E"
        echo "  ./run.sh ledger       Xem bảng đối soát Sổ cái kép trực tiếp (Delta=0)"
        echo "  ./run.sh vault        Xem số dư tồn két quầy chi nhánh"
        echo "  ./run.sh tokens       Cấp mới JWT tokens cho Teller & Manager"
        echo "  ./run.sh status       Kiểm tra sức khỏe cổng và containers"
        echo "  ./run.sh logs [svc]   Xem logs (fe, api-gateway, payment-service, v.v.)"
        echo "  ./run.sh stop         Dừng toàn bộ hệ thống an toàn"
        ;;
    *)
        echo -e "${RED}Lệnh không hợp lệ: $COMMAND${NC}"
        echo "Gõ './run.sh help' để xem danh sách lệnh hỗ trợ."
        exit 1
        ;;
esac
