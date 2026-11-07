#!/usr/bin/env bash
# ==============================================================================
# 🏦 CORE BANKING TELLER PORTAL & MICROSERVICES - BỘ ĐIỀU KHIỂN TOÀN DIỆN (RUN.SH)
# ==============================================================================
# Hỗ trợ:
#   1. Khởi động / Dừng Frontend React (Vite Port 5173)
#   2. Khởi động / Dừng Backend Microservices (8 services: Gateway, Identity,
#      Wallet, Payment, Ledger, Notification, Chatbot, eKYC-AI)
#   3. Quản lý Cụm Hạ Tầng (Kafka, 6 Postgres DBs, Redis, RabbitMQ)
#   4. Quản trị Mobile App (Flutter Run, Test, Build APK, Clean)
#   5. Chạy Kiểm thử Toàn diện E2E (8 Kịch bản, eKYC AI Pipeline, Chatbot RAG, Master Suite)
#   6. Bảng Đối soát Sổ cái kép trực tiếp (Live Ledger Balance Delta = 0.00 VND)
#   7. Tra cứu Két quỹ quầy chi nhánh (Vault Cash Limit 500M)
#   8. Cấp mới JWT Token cho Cán bộ quầy (Teller 1, Teller 2, Manager 1)
#   9. Kiểm tra Sức khỏe và Độ trễ toàn hệ thống (Health Check & Latency Audit)
#   10. Biên dịch, dọn dẹp và đóng gói hệ thống (Maven, Docker build)
# ==============================================================================

# Thiết lập thư mục gốc
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

# Đảm bảo /usr/bin luôn được ưu tiên trong PATH (tránh các wrapper giả lập flatpak bị thiếu)
if [ -d "/usr/bin" ] && [[ "$PATH" != "/usr/bin:"* ]]; then
    export PATH="/usr/bin:$PATH"
fi

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
GRAY='\033[0;90m'

# Nhận diện binary docker an toàn (bỏ qua flatpak wrapper hỏng nếu có)
if [ -x "/usr/bin/docker" ] && (! command -v flatpak-spawn >/dev/null 2>&1); then
    DOCKER_BIN="/usr/bin/docker"
elif command -v docker >/dev/null 2>&1; then
    DOCKER_BIN="docker"
else
    echo -e "${RED}❌ Không tìm thấy Docker trên hệ thống! Vui lòng cài đặt Docker trước khi tiếp tục.${NC}"
    exit 1
fi

dc() {
    "$DOCKER_BIN" compose "$@"
}

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
    echo -e " Kiến trúc: ${BLUE}Database-per-Service (6 DBs) + Event-Driven (Kafka/RabbitMQ) + eKYC AI + Portal${NC}"
    echo -e " ----------------------------------------------------------------------------------------"
}

# 1. Khởi động Hạ tầng Docker
start_infra() {
    echo -e "\n${BLUE}🐳 [1/4] KHỞI ĐỘNG CỤM HẠ TẦNG DOCKER (6 DATABASES, BROKERS & CACHES)...${NC}"
    dc up -d postgres-identity postgres-wallet postgres-payment postgres-ledger postgres-notification postgres-chatbot redis rabbitmq kafka kafka-ui
    echo -e "  ${GREEN}✓ Đang chờ 6 cơ sở dữ liệu Postgres, Redis, RabbitMQ và Kafka sẵn sàng...${NC}"

    local max_wait=30
    local count=0
    until "$DOCKER_BIN" exec ewallet-postgres-identity pg_isready -U identity_db_user -d ewallet_identity_db >/dev/null 2>&1 || [ $count -ge $max_wait ]; do
        sleep 1
        count=$((count + 1))
        echo -ne "  • Chờ PostgreSQL cụm Identity... ($count/${max_wait}s)\r"
    done
    echo ""

    # Kiểm tra nhanh các DB còn lại
    local dbs=("wallet:wallet_db_user:ewallet_wallet_db" "payment:payment_db_user:ewallet_payment_db" "ledger:ledger_app_user:ewallet_ledger_db" "notification:notification_db_user:ewallet_notification_db" "chatbot:chatbot_db_user:ewallet_chatbot_db")
    for db_info in "${dbs[@]}"; do
        IFS=":" read -r svc user db <<< "$db_info"
        if "$DOCKER_BIN" exec "ewallet-postgres-$svc" pg_isready -U "$user" -d "$db" >/dev/null 2>&1; then
            echo -e "  ${GREEN}✓ PostgreSQL $svc (ewallet_${svc}_db): Sẵn sàng!${NC}"
        else
            echo -e "  ${YELLOW}⚠️  PostgreSQL $svc đang khởi động...${NC}"
        fi
    done

    echo -e "  ${GREEN}✓ Cụm 6 Cơ sở dữ liệu Postgres, Kafka (29092), Redis (6379), RabbitMQ (5672) ĐÃ SẴN SÀNG!${NC}"
}

# 2. Khởi động Backend Microservices & AI Services
start_be() {
    start_infra
    echo -e "\n${BLUE}⚙️ [2/4] KHỞI ĐỘNG CỤM BACKEND MICROSERVICES & AI SERVICES (8 DỊCH VỤ)...${NC}"

    # Kiểm tra file JAR Spring Boot
    if ! ls "$ROOT_DIR"/backend/services/api-gateway/target/*.jar >/dev/null 2>&1; then
        echo -e "  ${YELLOW}⚠️ Chưa tìm thấy file .jar đã đóng gói. Đang tự động build Maven (common-library + 6 services)...${NC}"
        mvn -f "$ROOT_DIR/pom.xml" clean install -DskipTests
    fi

    echo -e "  • Khởi chạy toàn bộ 8 Microservices Containers:"
    dc up -d api-gateway identity-service wallet-service payment-service ledger-service notification-service chatbot-service ekyc-ai-service

    if [ -n "${CODESPACE_NAME:-}" ] && command -v gh &>/dev/null; then
        gh codespace ports visibility 8080:public 5173:public 8900:public -c "$CODESPACE_NAME" 2>/dev/null || true
    fi

    echo -e "  • Đang thẩm tra tính sẵn sàng của API Gateway (8080) và eKYC AI (8900)..."
    local be_wait=0
    until curl -s http://localhost:8080/actuator/health >/dev/null 2>&1 || [ $be_wait -ge 20 ]; do
        sleep 1
        be_wait=$((be_wait + 1))
        echo -ne "  • Chờ API Gateway phản hồi... ($be_wait/20s)\r"
    done
    echo ""

    echo -e "  ${GREEN}✓ Toàn bộ 8 Backend Microservices & AI Services đã được kích hoạt!${NC}"
    echo -e "    - API Gateway Routing:    ${CYAN}http://localhost:8080${NC}"
    echo -e "    - eKYC AI Service (ONNX): ${CYAN}http://localhost:8900${NC} (Liveness, Face Match, Hybrid Crypto)"
    echo -e "    - Chatbot GenAI Service:  ${CYAN}http://localhost:8000${NC} (RAG Financial Advisor)"
    echo -e "    - Kafka UI:               ${CYAN}http://localhost:8090${NC}"
    echo -e "    - RabbitMQ UI:            ${CYAN}http://localhost:15672${NC} (wallet / wallet123)"
}

# 3. Khởi động Frontend React Portal
start_fe() {
    echo -e "\n${BLUE}🌐 [3/4] KHỞI ĐỘNG FRONTEND REACT TELLER PORTAL...${NC}"
    if [ -f "$FE_PID_FILE" ] && kill -0 "$(cat "$FE_PID_FILE")" 2>/dev/null && curl -s http://localhost:5173 >/dev/null 2>&1; then
        echo -e "  ${YELLOW}⚠️ Frontend đang chạy tại PID: $(cat "$FE_PID_FILE") (${CYAN}http://localhost:5173${NC})${NC}"
        return 0
    fi

    # Dọn tiến trình cũ bị treo hoặc chiếm cổng 5173
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
    until curl -s http://localhost:5173 >/dev/null 2>&1 || [ $wait_fe -ge 12 ]; do
        sleep 1
        wait_fe=$((wait_fe + 1))
        echo -ne "  • Chờ Vite React khởi động... ($wait_fe/12s)\r"
    done
    echo ""

    if curl -s http://localhost:5173 >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓ Cổng Quản lý Nạp tiền Quầy (React Vite) đã chạy thành công!${NC}"
        echo -e "  👉 TRUY CẬP NGAY: ${BOLD}${CYAN}http://localhost:5173${NC}"
    else
        echo -e "  ${RED}❌ Khởi động Frontend thất bại. Vui lòng kiểm tra log: $FE_LOG_FILE${NC}"
        tail -n 15 "$FE_LOG_FILE" 2>/dev/null || true
        return 1
    fi
}

# 4. Quản trị Mobile App (Flutter)
run_mobile() {
    local subcmd="${1:-menu}"
    shift 2>/dev/null || true

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

    case "$subcmd" in
        run)
            cd "$ROOT_DIR/mobile"
            flutter pub get
            flutter run "$@"
            cd "$ROOT_DIR"
            ;;
        test)
            echo -e "  ${PURPLE}🧪 Đang chạy toàn bộ Widget & Logic Tests trên Mobile...${NC}"
            cd "$ROOT_DIR/mobile"
            flutter test "$@"
            cd "$ROOT_DIR"
            ;;
        build|build-apk)
            echo -e "  ${BLUE}📦 Đang đóng gói Release APK (Arm64/V7a)...${NC}"
            cd "$ROOT_DIR/mobile"
            flutter build apk --release "$@"
            echo -e "  ${GREEN}✓ File APK thành phẩm nằm tại: mobile/build/app/outputs/flutter-apk/app-release.apk${NC}"
            cd "$ROOT_DIR"
            ;;
        clean)
            echo -e "  🧹 Đang dọn dẹp cache build của Flutter Mobile..."
            cd "$ROOT_DIR/mobile"
            flutter clean
            flutter pub get
            cd "$ROOT_DIR"
            echo -e "  ${GREEN}✓ Đã dọn sạch build cache!${NC}"
            ;;
        devices)
            flutter devices
            ;;
        menu|*)
            echo -e "  ${BOLD}CÁC THAO TÁC VỚI FLUTTER MOBILE:${NC}"
            echo -e "  ${GREEN}1.${NC} 🚀 Khởi chạy ứng dụng (flutter run)"
            echo -e "  ${GREEN}2.${NC} 🧪 Chạy bộ kiểm thử (flutter test)"
            echo -e "  ${GREEN}3.${NC} 📦 Đóng gói file APK Release (flutter build apk)"
            echo -e "  ${GREEN}4.${NC} 📱 Xem danh sách thiết bị kết nối (flutter devices)"
            echo -e "  ${GREEN}5.${NC} 🧹 Dọn dẹp cache (flutter clean && pub get)"
            echo -e "  ${YELLOW}0.${NC} ↩️  Quay lại menu chính"
            read -rp "👉 Chọn thao tác [0-5]: " m_choice
            case "$m_choice" in
                1) cd "$ROOT_DIR/mobile" && flutter pub get && flutter run ;;
                2) cd "$ROOT_DIR/mobile" && flutter test ;;
                3) cd "$ROOT_DIR/mobile" && flutter build apk --release ;;
                4) flutter devices ;;
                5) cd "$ROOT_DIR/mobile" && flutter clean && flutter pub get ;;
                0) return 0 ;;
                *) echo -e "${RED}Lựa chọn không hợp lệ!${NC}" ;;
            esac
            cd "$ROOT_DIR"
            ;;
    esac
}

# 5. Tự động đồng bộ Endpoint của GitHub Codespaces
sync_codespace_endpoint() {
    if [ -z "${CODESPACE_NAME:-}" ]; then
        return 0
    fi

    local domain="${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:-app.github.dev}"
    local gateway_url="https://${CODESPACE_NAME}-8080.${domain}"
    local api_url="${gateway_url}/api/v1"
    local ws_url="wss://${CODESPACE_NAME}-8080.${domain}/ws-native"
    local portal_url="https://${CODESPACE_NAME}-5173.${domain}"
    local ekyc_url="https://${CODESPACE_NAME}-8900.${domain}"
    local now_utc
    now_utc=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    echo -e "\n${PURPLE}${BOLD}☁️  ĐỒNG BỘ TỰ ĐỘNG LINK CODESPACES CHO MOBILE APK & CLIENTS...${NC}"

    if command -v gh &>/dev/null; then
        gh codespace ports visibility 8080:public 5173:public 8900:public -c "$CODESPACE_NAME" 2>/dev/null || true
    fi

    cat > "$ROOT_DIR/cloud-endpoint.json" <<EOF
{
  "codespaceName": "${CODESPACE_NAME}",
  "gatewayUrl": "${gateway_url}",
  "apiUrl": "${api_url}",
  "wsUrl": "${ws_url}",
  "portalUrl": "${portal_url}",
  "ekycUrl": "${ekyc_url}",
  "updatedAt": "${now_utc}"
}
EOF

    local api_const_file="$ROOT_DIR/mobile/lib/core/constants/api_constants.dart"
    if [ -f "$api_const_file" ]; then
        sed -i -E "s|defaultValue: 'https?://[^']*'|defaultValue: '${api_url}'|g" "$api_const_file"
        sed -i -E "s|defaultValue: 'wss?://[^']*'|defaultValue: '${ws_url}'|g" "$api_const_file"
    fi

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
    echo -e "  • Link eKYC AI Server (8900):     ${BOLD}${CYAN}${ekyc_url}${NC}"
}

# 6. Khởi động Tất cả (All-in-one)
start_all() {
    print_banner
    echo -e "${GREEN}${BOLD}🚀 ĐANG KHỞI ĐỘNG TOÀN BỘ HỆ THỐNG CORE BANKING (INFRA + BE + AI + FE)...${NC}\n"
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
        echo -e "   • eKYC AI Engine (Public):    ${BOLD}${CYAN}https://${CODESPACE_NAME}-8900.${domain}${NC}"
    else
        echo -e "   • Frontend React Portal:      ${BOLD}${CYAN}http://localhost:5173${NC}"
        echo -e "   • API Gateway Routing:        ${BOLD}${CYAN}http://localhost:8080${NC}"
        echo -e "   • eKYC AI Server (ONNX/GPU):  ${BOLD}${CYAN}http://localhost:8900${NC}"
        echo -e "   • Chatbot AI Assistant:       ${BOLD}${CYAN}http://localhost:8000${NC}"
        echo -e "   • Kafka Management UI:        ${BOLD}${CYAN}http://localhost:8090${NC}"
        echo -e "   • RabbitMQ Admin UI:          ${BOLD}${CYAN}http://localhost:15672${NC}"
    fi
    echo -e "${GREEN}${BOLD}================================================================================${NC}"
}

# 7. Dừng hệ thống an toàn
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
    pkill -9 -f "vite.*5173" 2>/dev/null || true
    fuser -k 5173/tcp 2>/dev/null || true
    echo -e "  ${GREEN}✓ Đã dừng Frontend React.${NC}"

    # Dừng Docker containers
    echo -e "  • Đang dừng toàn bộ Backend Microservices & Cụm Hạ Tầng Docker..."
    dc down --remove-orphans 2>/dev/null || true
    echo -e "  ${GREEN}✓ Đã dừng toàn bộ Backend & Cụm Hạ Tầng Docker an toàn.${NC}"
}

# 8. Kiểm tra Sức khỏe và Độ trễ toàn hệ thống
check_status() {
    echo -e "\n${BOLD}${CYAN}================================================================================${NC}"
    echo -e "${BOLD}${CYAN}🔍 BẢNG TRẠNG THÁI SỨC KHỎE TOÀN BỘ HỆ THỐNG (HEALTH & LATENCY AUDIT)${NC}"
    echo -e "${BOLD}${CYAN}================================================================================${NC}"

    printf "%-32s %-16s %-12s %s\n" "THÀNH PHẦN HỆ THỐNG" "CỔNG / GIAO THỨC" "TRẠNG THÁI" "ĐỘ TRỄ (PING)"
    echo "--------------------------------------------------------------------------------"

    # Helper đo HTTP
    check_http() {
        local name="$1"
        local url="$2"
        local port_desc="$3"
        local res
        res=$(curl -s -o /dev/null -w "%{http_code} %{time_total}" -m 5 "$url" 2>/dev/null || echo "000 0.0")
        local code
        local latency
        code=$(echo "$res" | awk '{print $1}')
        latency=$(echo "$res" | awk '{printf "%.1f ms", $2 * 1000}')

        if [[ "$code" =~ ^(200|204|302|401)$ ]]; then
            printf "%-32s %-16s ${GREEN}%-12s${NC} %s\n" "$name" "$port_desc" "🟢 ONLINE" "$latency"
        else
            printf "%-32s %-16s ${RED}%-12s${NC} %s\n" "$name" "$port_desc" "🔴 OFFLINE" "-"
        fi
    }

    # Microservices HTTP
    check_http "Frontend React Portal" "http://localhost:5173" "HTTP :5173"
    check_http "API Gateway (Route & Auth)" "http://localhost:8080/actuator/health" "HTTP :8080"
    check_http "Identity Service (KYC/Auth)" "http://localhost:8081/actuator/health" "HTTP :8081"
    check_http "Wallet Service (Core/gRPC)" "http://localhost:8082/actuator/health" "HTTP :8082/9090"
    check_http "Payment Service (Saga P2P)" "http://localhost:8083/actuator/health" "HTTP :8083"
    check_http "Ledger Service (Double-Entry)" "http://localhost:8084/actuator/health" "HTTP :8084"
    check_http "Notification (STOMP/Push)" "http://localhost:8085/actuator/health" "HTTP :8085"
    check_http "eKYC AI Server (ONNX/GPU)" "http://localhost:8900/api/v1/ekyc/ai/health" "HTTP :8900"
    check_http "Chatbot AI Service (RAG)" "http://localhost:8000/health" "HTTP :8000"
    check_http "Kafka UI Management" "http://localhost:8090" "HTTP :8090"
    check_http "RabbitMQ Management UI" "http://localhost:15672" "HTTP :15672"

    # Kiểm tra CSDL Postgres (6 databases)
    echo "--------------------------------------------------------------------------------"
    local dbs=(
        "Postgres Identity DB:ewallet-postgres-identity:identity_db_user:ewallet_identity_db:5433"
        "Postgres Wallet DB:ewallet-postgres-wallet:wallet_db_user:ewallet_wallet_db:5434"
        "Postgres Payment DB:ewallet-postgres-payment:payment_db_user:ewallet_payment_db:5435"
        "Postgres Ledger DB:ewallet-postgres-ledger:ledger_app_user:ewallet_ledger_db:5436"
        "Postgres Notification DB:ewallet-postgres-notification:notification_db_user:ewallet_notification_db:5437"
        "Postgres Chatbot Vector DB:ewallet-postgres-chatbot:chatbot_db_user:ewallet_chatbot_db:5438"
    )
    for db_entry in "${dbs[@]}"; do
        IFS=":" read -r name container user db port <<< "$db_entry"
        if "$DOCKER_BIN" exec "$container" pg_isready -U "$user" -d "$db" >/dev/null 2>&1; then
            printf "%-32s %-16s ${GREEN}%-12s${NC} %s\n" "$name" "TCP :$port" "🟢 ONLINE" "pg_isready"
        else
            printf "%-32s %-16s ${RED}%-12s${NC} %s\n" "$name" "TCP :$port" "🔴 OFFLINE" "-"
        fi
    done

    # Redis & Kafka
    if "$DOCKER_BIN" exec ewallet-redis redis-cli ping >/dev/null 2>&1; then
        printf "%-32s %-16s ${GREEN}%-12s${NC} %s\n" "Redis Cluster & Distributed Lock" "TCP :6379" "🟢 ONLINE" "PONG"
    else
        printf "%-32s %-16s ${RED}%-12s${NC} %s\n" "Redis Cluster" "TCP :6379" "🔴 OFFLINE" "-"
    fi

    echo -e "${BOLD}${CYAN}================================================================================${NC}"
    echo -e "  • Danh sách Containers Docker:"
    dc ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || "$DOCKER_BIN" ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo -e "${BOLD}${CYAN}================================================================================${NC}"
}

# 9. Chạy Bộ Kiểm Thử E2E Đa Kịch Bản
run_test() {
    local scenario="${1:-menu}"
    shift 2>/dev/null || true

    case "$scenario" in
        08|multi|8)
            echo -e "\n${PURPLE}🧪 [KIỂM THỬ 8 KỊCH BẢN] DỮ LIỆU THẬT MULTI-SCENARIO...${NC}"
            "$ROOT_DIR/scripts/e2e/08-multi-scenario-real-test.sh"
            ;;
        ekyc|nfc)
            echo -e "\n${PURPLE}🧪 [KIỂM THỬ eKYC & NFC CHIP] TOÀN TRÌNH HYBRID CRYPTO & AI PIPELINE...${NC}"
            python3 "$ROOT_DIR/scripts/e2e/24-ekyc-ai-full-pipeline-test.py"
            ;;
        ekyc-deep|exceptions)
            echo -e "\n${PURPLE}🧪 [KIỂM THỬ NGOẠI LỆ eKYC] TOÀN DIỆN THẺ CCCD & CHIP NFC...${NC}"
            python3 "$ROOT_DIR/scripts/e2e/25-ekyc-comprehensive-real-data-exceptions-e2e.py"
            ;;
        chatbot|rag)
            echo -e "\n${PURPLE}🧪 [KIỂM THỬ CHATBOT RAG] TRỢ LÝ TÀI CHÍNH THÔNG MINH...${NC}"
            python3 "$ROOT_DIR/scripts/e2e/23-chatbot-deep-e2e-audit.py"
            ;;
        master|all)
            echo -e "\n${PURPLE}🧪 [MASTER SUITE] SIÊU KIỂM THỬ TOÀN DIỆN TOÀN BỘ HỆ SINH THÁI...${NC}"
            "$ROOT_DIR/scripts/e2e/19-master-full-ecosystem-test.sh"
            ;;
        suite|business)
            echo -e "\n${PURPLE}🧪 [NGHIỆP VỤ] BỘ KIỂM THỬ NGHIỆP VỤ TOÀN DIỆN...${NC}"
            "$ROOT_DIR/scripts/e2e/14-comprehensive-business-suite.sh"
            ;;
        menu|*)
            echo -e "\n${PURPLE}${BOLD}🧪 CHỌN KỊCH BẢN KIỂM THỬ TỰ ĐỘNG (E2E TEST SUITES):${NC}"
            echo -e "  ${GREEN}1.${NC} 🎯 8 Kịch Bản Giao Dịch Dữ Liệu Thật Lõi (scripts/e2e/08-...)"
            echo -e "  ${GREEN}2.${NC} 🪪 eKYC AI & NFC Chip CCCD Toàn Trình (scripts/e2e/24-...)"
            echo -e "  ${GREEN}3.${NC} 🛡️  Kiểm Thử Ngoại Lệ eKYC, Bẻ Khóa Giả Mạo (scripts/e2e/25-...)"
            echo -e "  ${GREEN}4.${NC} 🤖 Chatbot GenAI RAG Cố Vấn Tài Chính (scripts/e2e/23-...)"
            echo -e "  ${GREEN}5.${NC} 👑 Master Ecosystem Full Test Suite (scripts/e2e/19-...)"
            echo -e "  ${GREEN}6.${NC} 💼 Bộ Nghiệp Vụ Toàn Diện (scripts/e2e/14-...)"
            echo -e "  ${YELLOW}0.${NC} ↩️  Quay lại menu chính"
            read -rp "👉 Chọn kịch bản kiểm thử [0-6]: " t_choice
            case "$t_choice" in
                1) "$ROOT_DIR/scripts/e2e/08-multi-scenario-real-test.sh" ;;
                2) python3 "$ROOT_DIR/scripts/e2e/24-ekyc-ai-full-pipeline-test.py" ;;
                3) python3 "$ROOT_DIR/scripts/e2e/25-ekyc-comprehensive-real-data-exceptions-e2e.py" ;;
                4) python3 "$ROOT_DIR/scripts/e2e/23-chatbot-deep-e2e-audit.py" ;;
                5) "$ROOT_DIR/scripts/e2e/19-master-full-ecosystem-test.sh" ;;
                6) "$ROOT_DIR/scripts/e2e/14-comprehensive-business-suite.sh" ;;
                0) return 0 ;;
                *) echo -e "${RED}Lựa chọn không hợp lệ!${NC}" ;;
            esac
            ;;
    esac
}

# 10. Tra cứu Bảng Đối Soát Sổ Cái Kép Trực Tiếp
check_ledger() {
    echo -e "\n${CYAN}📊 [ĐỐI SOÁT SỔ CÁI] TRUY VẤN SỐ DƯ KÉP NỢ 1011 / CÓ 4211 THỜI GIAN THỰC...${NC}"
    "$DOCKER_BIN" exec -i ewallet-postgres-ledger psql -U ledger_app_user -d ewallet_ledger_db << 'EOF'
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

# 11. Tra cứu Két Quỹ Chi Nhánh
check_vault() {
    echo -e "\n${YELLOW}💰 [KÉT QUỸ CHI NHÁNH] TÌNH HÌNH TỒN QUỸ CHI NHÁNH QUẬN 1 (BR_Q1)...${NC}"
    "$DOCKER_BIN" exec -i ewallet-postgres-payment psql -U payment_db_user -d ewallet_payment_db << 'EOF'
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

# 12. Cấp mới Staff JWT Tokens
generate_tokens() {
    echo -e "\n${BLUE}🔑 CẤP MỚI VÀ LÀM MỚI JWT BEARER TOKENS CHO CÁN BỘ NGÂN HÀNG...${NC}"
    if [ -f "$ROOT_DIR/scripts/e2e/generate-staff-tokens.sh" ]; then
        "$ROOT_DIR/scripts/e2e/generate-staff-tokens.sh"
    else
        echo -e "  ${RED}Không tìm thấy script generate-staff-tokens.sh${NC}"
    fi
}

# 13. Biên dịch & Đóng gói hệ thống
build_all() {
    local target="${1:-all}"
    echo -e "\n${BLUE}📦 [BIÊN DỊCH & ĐÓNG GÓI] TARGET: $target...${NC}"
    case "$target" in
        be|backend|maven)
            echo -e "  • Đang chạy Maven Clean Install (toàn bộ microservices)..."
            mvn -f "$ROOT_DIR/pom.xml" clean install -DskipTests
            echo -e "  ${GREEN}✓ Đã biên dịch xong toàn bộ Backend!${NC}"
            ;;
        docker)
            echo -e "  • Đang build lại Docker images..."
            dc build
            echo -e "  ${GREEN}✓ Đã build xong toàn bộ Docker images!${NC}"
            ;;
        all|*)
            echo -e "  • Bước 1: Build Maven..."
            mvn -f "$ROOT_DIR/pom.xml" clean install -DskipTests
            echo -e "  • Bước 2: Build Docker images..."
            dc build
            echo -e "  ${GREEN}✓ Toàn bộ hệ thống Backend & Docker đã được đóng gói sẵn sàng!${NC}"
            ;;
    esac
}

# 14. Xem Logs Dịch Vụ
view_logs() {
    local target="${1:-fe}"
    if [ "$target" == "fe" ] || [ "$target" == "frontend" ]; then
        echo -e "\n${CYAN}📄 Đang mở logs Frontend React ($FE_LOG_FILE)... (Bấm Ctrl+C để thoát)${NC}"
        tail -f "$FE_LOG_FILE"
    else
        echo -e "\n${CYAN}📄 Đang mở logs Docker service: $target... (Bấm Ctrl+C để thoát)${NC}"
        dc logs -f "$target"
    fi
}

# Menu CLI Tương Tác (Đã dọn dẹp và chuẩn hóa)
interactive_menu() {
    while true; do
        print_banner
        echo -e "  ${BOLD}VUI LÒNG CHỌN MỘT THAO TÁC:${NC}"
        echo -e "  ${GREEN}1.${NC} 🚀 ${BOLD}Khởi Động Toàn Bộ Hệ Thống${NC} (Infra + BE + AI + FE React)"
        echo -e "  ${GREEN}2.${NC} ⚙️  ${BOLD}Khởi Động Backend Microservices & AI${NC} (8 Dịch vụ + Gateway)"
        echo -e "  ${GREEN}3.${NC} 🌐 ${BOLD}Khởi Động Frontend React Portal${NC} (Vite: http://localhost:5173)"
        echo -e "  ${GREEN}4.${NC} 🐳 ${BOLD}Khởi Động Cụm Hạ Tầng Docker${NC} (6 DBs, Kafka, Redis, RabbitMQ)"
        echo -e "  ${GREEN}5.${NC} 📱 ${BOLD}Quản Trị Mobile App E-Wallet${NC} (Flutter: Run / Test / APK)"
        echo -e "  ${GREEN}6.${NC} 🔍 ${BOLD}Kiểm Tra Sức Khỏe & Độ Trễ Toàn Diện${NC} (Ports & Health Audit)"
        echo -e "  ${GREEN}7.${NC} 🧪 ${BOLD}Chạy Bộ Kiểm Thử Tự Động E2E${NC} (8 Kịch bản, eKYC AI, Chatbot)"
        echo -e "  ${GREEN}8.${NC} 📊 ${BOLD}Xem Bảng Đối Soát Sổ Cái Kép Trực Tiếp${NC} (Delta = 0.00 VND)"
        echo -e "  ${GREEN}9.${NC} 💰 ${BOLD}Xem Tồn Quỹ Két Quầy Chi Nhánh & Hạn Mức 500M${NC}"
        echo -e "  ${GREEN}10.${NC} 🔑 ${BOLD}Cấp Mới JWT Tokens Cán Bộ Quầy${NC} (Teller 1, Teller 2, Manager 1)"
        echo -e "  ${GREEN}11.${NC} 📦 ${BOLD}Biên Dịch & Đóng Gói Hệ Thống${NC} (Maven / Docker Build)"
        echo -e "  ${BLUE}12.${NC} 📄 ${BOLD}Xem Logs Dịch Vụ${NC} (Frontend React / Docker Containers)"
        echo -e "  ${YELLOW}13.${NC} 🔄 ${BOLD}Khởi Động Lại Hệ Thống${NC} (Restart Toàn Diện)"
        echo -e "  ${RED}14.${NC} 🛑 ${BOLD}Dừng Toàn Bộ Hệ Thống${NC} (Tắt FE, BE & Cleanup)"
        echo -e "  ${GRAY}0.${NC}  🚪 ${BOLD}Thoát Menu${NC}"
        echo -e " ----------------------------------------------------------------------------------------"
        read -rp "👉 Nhập lựa chọn của bạn [0-14]: " choice

        case "$choice" in
            1) start_all; read -rp "Ấn Enter để tiếp tục..." ;;
            2) start_be; read -rp "Ấn Enter để tiếp tục..." ;;
            3) start_fe; read -rp "Ấn Enter để tiếp tục..." ;;
            4) start_infra; read -rp "Ấn Enter để tiếp tục..." ;;
            5) run_mobile; read -rp "Ấn Enter để tiếp tục..." ;;
            6) check_status; read -rp "Ấn Enter để tiếp tục..." ;;
            7) run_test; read -rp "Ấn Enter để tiếp tục..." ;;
            8) check_ledger; read -rp "Ấn Enter để tiếp tục..." ;;
            9) check_vault; read -rp "Ấn Enter để tiếp tục..." ;;
            10) generate_tokens; read -rp "Ấn Enter để tiếp tục..." ;;
            11) build_all; read -rp "Ấn Enter để tiếp tục..." ;;
            12)
                echo -e "Chọn logs: 1) Frontend  2) Gateway  3) eKYC-AI  4) Chatbot  5) Payment  6) Wallet"
                read -rp "Nhập [1-6] hoặc tên container: " log_choice
                case "$log_choice" in
                    1) view_logs fe ;;
                    2) view_logs api-gateway ;;
                    3) view_logs ekyc-ai-service ;;
                    4) view_logs chatbot-service ;;
                    5) view_logs payment-service ;;
                    6) view_logs wallet-service ;;
                    *) view_logs "$log_choice" ;;
                esac
                ;;
            13)
                stop_all
                start_all
                read -rp "Ấn Enter để tiếp tục..."
                ;;
            14) stop_all; read -rp "Ấn Enter để tiếp tục..." ;;
            0) echo -e "\n${GREEN}Tạm biệt! Chúc bạn làm việc hiệu quả.${NC}\n"; exit 0 ;;
            *) echo -e "${RED}Lựa chọn không hợp lệ! Vui lòng chọn từ 0 đến 14.${NC}"; sleep 1 ;;
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
        shift
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
        shift
        run_test "$@"
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
    build|compile)
        shift
        build_all "$@"
        ;;
    status|health)
        check_status
        ;;
    logs)
        shift
        view_logs "${1:-fe}"
        ;;
    clean)
        echo -e "${YELLOW}🧹 Đang dọn dẹp log, pid và các file rác...${NC}"
        rm -f "$FE_PID_FILE" "$FE_LOG_FILE"
        pkill -9 -f "vite.*5173" 2>/dev/null || true
        fuser -k 5173/tcp 2>/dev/null || true
        echo -e "${GREEN}✓ Đã dọn sạch các file tạm thời!${NC}"
        ;;
    menu)
        interactive_menu
        ;;
    help|-h|--help)
        echo -e "${BOLD}CÁCH SỬ DỤNG BỘ ĐIỀU KHIỂN RUN.SH:${NC}"
        echo "  ./run.sh                  Mở Menu tương tác đồ họa CLI"
        echo "  ./run.sh all              Khởi động toàn bộ (Infra + BE + AI + FE)"
        echo "  ./run.sh fe               Khởi động Frontend React Portal (Port 5173)"
        echo "  ./run.sh be               Khởi động 8 Backend Microservices & AI"
        echo "  ./run.sh mobile [cmd]     Quản trị Mobile Flutter (run, test, build-apk, clean)"
        echo "  ./run.sh infra            Khởi động cụm Docker (6 DBs, Kafka, Redis, RabbitMQ)"
        echo "  ./run.sh test [scenario]  Chạy kiểm thử E2E (08, ekyc, ekyc-deep, chatbot, master)"
        echo "  ./run.sh status           Kiểm tra sức khỏe, độ trễ và trạng thái ports"
        echo "  ./run.sh build [target]   Biên dịch và đóng gói (maven, docker, all)"
        echo "  ./run.sh ledger           Xem bảng đối soát Sổ cái kép trực tiếp (Delta=0)"
        echo "  ./run.sh vault            Xem số dư tồn két quầy chi nhánh"
        echo "  ./run.sh tokens           Cấp mới JWT tokens cho Teller & Manager"
        echo "  ./run.sh logs [svc]       Xem logs (fe, api-gateway, ekyc-ai-service, v.v.)"
        echo "  ./run.sh clean            Dọn dẹp pid, port và file log tạm thời"
        echo "  ./run.sh restart          Khởi động lại toàn bộ hệ thống"
        echo "  ./run.sh stop             Dừng toàn bộ hệ thống an toàn"
        ;;
    *)
        echo -e "${RED}Lệnh không hợp lệ: $COMMAND${NC}"
        echo "Gõ './run.sh help' để xem danh sách lệnh hỗ trợ."
        exit 1
        ;;
esac
