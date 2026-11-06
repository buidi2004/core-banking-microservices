#!/usr/bin/env bash
# ==============================================================================
# SEN HỒNG BANK - KHỞI ĐỘNG NHANH BACKEND & NGROK TUNNEL (RUN.BE)
# ==============================================================================
# Lệnh thực thi: ./run.be [start|status|stop|restart|logs]
# Chức năng:
#   1. Khởi động Cụm Hạ Tầng Docker (5 Postgres DBs, Redis, RabbitMQ, Kafka, Kafka UI)
#   2. Khởi động 6 Microservices (Gateway :8080, Identity :8081, Wallet :8082, 
#      Payment :8083, Ledger :8084, Notification :8085)
#   3. Khởi động Ngrok Tunnel (https://mutation-tubby-overstock.ngrok-free.dev -> :8080)
#   4. Kiểm tra sức khỏe tự động (Health check cổng nội bộ + Ngrok public URL)
# ==============================================================================

set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

# Màu hiển thị
BOLD='\033[1m'
NC='\033[0m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'

NGROK_DOMAIN="mutation-tubby-overstock.ngrok-free.dev"

# Tự động phát hiện môi trường: Native Host vs Flatpak Sandbox (VS Code)
if ! command -v docker >/dev/null 2>&1 && command -v flatpak-spawn >/dev/null 2>&1; then
    EXEC_CMD="flatpak-spawn --host"
else
    EXEC_CMD=""
fi

run_host() {
    if [ -n "$EXEC_CMD" ]; then
        $EXEC_CMD "$@"
    else
        "$@"
    fi
}

start_be() {
    echo -e "${CYAN}${BOLD}"
    echo "======================================================================"
    echo "  🚀 KHỞI ĐỘNG CỤM BACKEND & NGROK TUNNEL - SEN HỒNG BANK"
    echo -e "======================================================================${NC}"

    # 1. Khởi động cụm Docker Hạ tầng
    echo -e "\n${BLUE}🐳 [1/3] Khởi động Hạ tầng Docker (Databases & Message Brokers)...${NC}"
    run_host bash -c "cd '$ROOT_DIR' && docker compose up -d postgres-identity postgres-wallet postgres-payment postgres-ledger postgres-notification redis rabbitmq kafka kafka-ui"

    # 2. Khởi động cụm 6 Microservices
    echo -e "\n${BLUE}⚙️  [2/3] Khởi động 6 Backend Microservices...${NC}"
    run_host bash -c "cd '$ROOT_DIR' && docker compose up -d api-gateway identity-service wallet-service payment-service ledger-service notification-service"

    # 3. Khởi động Ngrok Tunnel
    echo -e "\n${BLUE}🌐 [3/3] Khởi động Ngrok Tunnel công khai...${NC}"
    run_host bash "$ROOT_DIR/scripts/start-ngrok.sh"

    # 4. Kiểm tra sẵn sàng (Health check)
    echo -e "\n${YELLOW}⏳ Đang kiểm tra trạng thái hoạt động (Health Check)...${NC}"
    
    # Chờ API Gateway nội bộ
    MAX_RETRY=15
    RETRY=0
    GATEWAY_READY=false
    while [ $RETRY -lt $MAX_RETRY ]; do
        STATUS=$(run_host curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/actuator/health 2>/dev/null || true)
        if [ "$STATUS" = "200" ]; then
            GATEWAY_READY=true
            break
        fi
        sleep 2
        RETRY=$((RETRY + 1))
        echo -ne "  • Đang chờ API Gateway khởi động ($RETRY/$MAX_RETRY)...\r"
    done
    echo ""

    if [ "$GATEWAY_READY" = true ]; then
        echo -e "  ${GREEN}✓ API Gateway nội bộ sẵn sàng (HTTP 200)!${NC}"
    else
        echo -e "  ${YELLOW}⚠️ API Gateway đang khởi động (sẽ sẵn sàng sau vài giây).${NC}"
    fi

    # Kiểm tra Ngrok tunnel
    NGROK_STATUS=$(run_host curl -s -o /dev/null -w "%{http_code}" "https://$NGROK_DOMAIN/actuator/health" 2>/dev/null || true)
    if [ "$NGROK_STATUS" = "200" ]; then
        echo -e "  ${GREEN}✓ Ngrok Tunnel kết nối thành công (HTTP 200)!${NC}"
    else
        echo -e "  ${YELLOW}⚠️ Ngrok đang hoàn tất kết nối tới Gateway.${NC}"
    fi

    # Hiển thị thông tin kết nối
    echo -e "\n${GREEN}${BOLD}🎉 HỆ THỐNG BACKEND & NGROK ĐÃ SẴN SÀNG TOÀN DIỆN!${NC}"
    echo -e "----------------------------------------------------------------------"
    echo -e "  🌐 Ngrok URL (Mobile App):  ${PURPLE}${BOLD}https://$NGROK_DOMAIN${NC}"
    echo -e "  📡 WebSocket Ngrok:         ${PURPLE}${BOLD}wss://$NGROK_DOMAIN/ws-native${NC}"
    echo -e "  🚪 Local API Gateway:       ${CYAN}http://localhost:8080${NC}"
    echo -e "  📊 Ngrok Web Dashboard:     ${BLUE}http://127.0.0.1:4040${NC}"
    echo -e "  🐰 RabbitMQ Management UI:  ${YELLOW}http://localhost:15672${NC} (wallet / wallet123)"
    echo -e "  📬 Kafka UI Dashboard:      ${YELLOW}http://localhost:8090${NC}"
    echo -e "----------------------------------------------------------------------"
    echo -e "👉 Mobile Flutter và Web Portal có thể kết nối ngay lập tức!\n"
}

stop_be() {
    echo -e "${RED}${BOLD}🛑 Đang dừng Ngrok Tunnel và Backend Microservices...${NC}"
    run_host bash "$ROOT_DIR/scripts/stop-ngrok.sh"
    run_host bash -c "cd '$ROOT_DIR' && docker compose stop api-gateway identity-service wallet-service payment-service ledger-service notification-service"
    echo -e "${GREEN}✓ Đã dừng Backend và Ngrok an toàn.${NC}"
}

check_status() {
    echo -e "${CYAN}${BOLD}🔍 TRẠNG THÁI HỆ THỐNG BACKEND & NGROK:${NC}\n"
    run_host bash -c "cd '$ROOT_DIR' && docker compose ps"
    echo ""
    if run_host systemctl --user is-active ngrok >/dev/null 2>&1 || run_host pgrep -f "ngrok start" >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓ Ngrok Service: ĐANG CHẠY${NC} (https://$NGROK_DOMAIN)"
    else
        echo -e "  ${RED}✗ Ngrok Service: ĐÃ DỪNG${NC}"
    fi
    echo ""
}

show_logs() {
    SERVICE="${1:-api-gateway}"
    echo -e "${CYAN}📄 Đang mở logs service: $SERVICE (Nhấn Ctrl+C để thoát)...${NC}"
    run_host bash -c "cd '$ROOT_DIR' && docker compose logs -f --tail 100 $SERVICE"
}

ACTION="${1:-start}"

case "$ACTION" in
    start|up|"")
        start_be
        ;;
    stop|down)
        stop_be
        ;;
    restart)
        stop_be
        sleep 2
        start_be
        ;;
    status)
        check_status
        ;;
    logs)
        show_logs "${2:-api-gateway}"
        ;;
    help|-h|--help)
        echo -e "${BOLD}CÁCH SỬ DỤNG ./run.be:${NC}"
        echo "  ./run.be            Khởi động toàn bộ Backend Docker & Ngrok Tunnel"
        echo "  ./run.be status     Xem trạng thái các container và Ngrok"
        echo "  ./run.be stop       Dừng Ngrok và các Microservices"
        echo "  ./run.be restart    Khởi động lại Backend & Ngrok"
        echo "  ./run.be logs [svc] Xem logs thời gian thực (vd: ./run.be logs payment-service)"
        ;;
    *)
        echo -e "${RED}Lựa chọn không hợp lệ: $ACTION${NC}"
        echo "Sử dụng: ./run.be [start|stop|restart|status|logs]"
        exit 1
        ;;
esac
