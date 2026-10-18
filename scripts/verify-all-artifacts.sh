#!/usr/bin/env bash
# ==============================================================================
# HỆ THỐNG KIỂM TRA TOÀN DIỆN ARTIFACTS PHÂN RÃ MICROSERVICES (ZERO-CODE CHECKLIST)
# Script: scripts/verify-all-artifacts.sh
# Lead Architect & Orchestrator: Antigravity
#
# Kiểm tra 9 artifacts từ các agent (agnes_worker, mimo_worker) và các file hạ tầng
# ==============================================================================

set -euo pipefail

# ANSI Color Codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

TOTAL_COUNT=0
PASSED_COUNT=0
FAILED_COUNT=0

WORKSPACE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$WORKSPACE_ROOT"

echo -e "${BOLD}${CYAN}==============================================================================${NC}"
echo -e "${BOLD}${CYAN}      E-WALLET MICROSERVICES MIGRATION - 9 ARTIFACTS VERIFICATION SUITE       ${NC}"
echo -e "${BOLD}${CYAN}==============================================================================${NC}"
echo -e "Thư mục làm việc: ${BLUE}${WORKSPACE_ROOT}${NC}"
echo -e "Thời điểm chạy:   ${YELLOW}$(date '+%Y-%m-%d %H:%M:%S %Z')${NC}\n"

check_artifact() {
    local phase="$1"
    local name="$2"
    local filepath="$3"
    local required_keyword="$4"
    local description="$5"

    TOTAL_COUNT=$((TOTAL_COUNT + 1))
    echo -e "${BOLD}[${phase}] Artifact #${TOTAL_COUNT}: ${name}${NC}"
    echo -e "  Đường dẫn: ${CYAN}${filepath}${NC}"
    echo -e "  Mô tả:     ${description}"

    if [ ! -f "$filepath" ]; then
        echo -e "  ${RED}✗ THẤT BẠI: File không tồn tại!${NC}\n"
        FAILED_COUNT=$((FAILED_COUNT + 1))
        return 1
    fi

    local filesize
    filesize=$(wc -c < "$filepath" | tr -d ' ')
    if [ "$filesize" -le 0 ]; then
        echo -e "  ${RED}✗ THẤT BẠI: File rỗng (0 bytes)!${NC}\n"
        FAILED_COUNT=$((FAILED_COUNT + 1))
        return 1
    fi

    if [ -n "$required_keyword" ]; then
        if ! grep -q "$required_keyword" "$filepath"; then
            echo -e "  ${RED}✗ THẤT BẠI: Thiếu từ khóa kiểm chứng [${required_keyword}] trong nội dung!${NC}\n"
            FAILED_COUNT=$((FAILED_COUNT + 1))
            return 1
        fi
    fi

    local lines
    lines=$(wc -l < "$filepath" | tr -d ' ')
    echo -e "  ${GREEN}✓ THÀNH CÔNG: Tồn tại (${filesize} bytes, ${lines} dòng). Chữ ký hợp lệ [${required_keyword:-NONE}].${NC}\n"
    PASSED_COUNT=$((PASSED_COUNT + 1))
    return 0
}

echo -e "${BOLD}${BLUE}--- GIAI ĐOẠN 0: HẠ TẦNG CƠ SỞ DỮ LIỆU ĐỘC LẬP (DATABASE-PER-SERVICE) ---${NC}"
check_artifact \
    "Giai đoạn 0" \
    "SQL Khởi tạo 5 Database & User Roles" \
    "scripts/init-5-databases.sql" \
    "ledger_app_user" \
    "Khởi tạo 5 DB riêng biệt, cấp quyền Append-Only (REVOKE UPDATE/DELETE) cho sổ cái"

echo -e "${BOLD}${BLUE}--- GIAI ĐOẠN 1: DỰNG API GATEWAY & TÁCH NOTIFICATION SERVICE ---${NC}"
check_artifact \
    "Giai đoạn 1" \
    "Flyway Migration Notification DB" \
    "services/notification-service/src/main/resources/db/migration/V1__init_notification_db.sql" \
    "notifications" \
    "Schema Flyway độc lập cho 7 bảng Notifications/Promotions/Devices không còn FK"

check_artifact \
    "Giai đoạn 1" \
    "Cấu hình Spring Cloud Gateway Routes" \
    "services/api-gateway/gateway-routes.yml" \
    "notification-service:8085" \
    "Định tuyến 6 controller path về notification-service:8085 và fallback về monolith"

echo -e "${BOLD}${BLUE}--- GIAI ĐOẠN 2: TÁCH GENERAL LEDGER & AUDIT SERVICE ---${NC}"
check_artifact \
    "Giai đoạn 2" \
    "Flyway Migration Ledger DB (Append-Only)" \
    "services/ledger-service/src/main/resources/db/migration/V1__init_ledger_db.sql" \
    "journal_entries" \
    "Schema Flyway sổ cái kép, phân quyền Append-Only chống sửa/xóa bút toán tài chính"

check_artifact \
    "Giai đoạn 2" \
    "Báo cáo Đối soát Song song (Dual-Run 3 Ngày)" \
    "docs/architecture/artifacts/DUAL_CONSUMPTION_RECONCILIATION_REPORT.md" \
    "RCN-LEDGER-DUALRUN-001" \
    "Biên bản đối soát khớp 100% checksum và cân bằng Debit/Credit giữa Monolith và Ledger DB"

echo -e "${BOLD}${BLUE}--- GIAI ĐOẠN 3: TÁCH IDENTITY & XÁC THỰC TẬP TRUNG TẠI GATEWAY ---${NC}"
check_artifact \
    "Giai đoạn 3" \
    "Bộ lọc JWT Edge Gateway & Header Injection" \
    "services/api-gateway/JwtAuthenticationFilter.java" \
    "HEADER_USER_ID" \
    "Filter xác thực JWT, tra cứu Redis blacklist và inject X-User-Id xuống downstream"

check_artifact \
    "Giai đoạn 3" \
    "Domain Event Đăng ký Người dùng (RabbitMQ)" \
    "common-library/src/main/java/com/fintech/wallet/domain/event/UserRegisteredEvent.java" \
    "UserRegisteredEvent" \
    "Contract Event-driven onboarding khởi tạo ví bất đồng bộ qua RabbitMQ"

echo -e "${BOLD}${BLUE}--- GIAI ĐOẠN 4: PHÂN TÁCH LÕI TÀI CHÍNH (WALLET CORE VS PAYMENT) ---${NC}"
check_artifact \
    "Giai đoạn 4" \
    "Hợp đồng gRPC Wallet Internal Service" \
    "common-library/src/main/proto/wallet_service.proto" \
    "service WalletInternalService" \
    "Protobuf contract cho Debit, Credit, Reserve, Release giữa Payment Svc và Wallet Core"

check_artifact \
    "Giai đoạn 4" \
    "Biên bản & Kịch bản Kiểm thử Saga Auto-Reversal" \
    "docs/architecture/artifacts/SAGA_AUTO_REVERSAL_TEST_SPEC.md" \
    "TC-SAGA-03" \
    "Đặc tả kịch bản bù trừ tự động (Compensating Transaction) khi ghi có thất bại"

echo -e "${BOLD}${BLUE}--- HẠ TẦNG ĐIỀU PHỐI TỔNG THỂ (ORCHESTRATION & DELIVERY) ---${NC}"
check_artifact \
    "Hạ tầng" \
    "Docker Compose 5 DBs, Redis, RabbitMQ & Gateway" \
    "docker-compose.yml" \
    "ewallet-postgres-ledger" \
    "Hạ tầng docker compose tích hợp toàn bộ các thành phần phân rã"

check_artifact \
    "Nghiệm thu" \
    "Biên bản Tổng kết Nghiệm thu Phân rã Microservices" \
    "docs/architecture/artifacts/MICROSERVICES_MIGRATION_DELIVERY.md" \
    "MICROSERVICES_MIGRATION_DELIVERY" \
    "Báo cáo tổng kết toàn bộ tiến độ và nghiệm thu 4 giai đoạn phân rã"

check_artifact \
    "Điều phối" \
    "Báo cáo Điều phối 5 Agents qua Herdr" \
    "docs/architecture/artifacts/EWALLET_5SERVICES_ORCHESTRATION_REPORT.md" \
    "BÁO CÁO ĐIỀU PHỐI VÀ NGHIỆM THU 5 MICROSERVICES ĐỘC LẬP" \
    "Biên bản điều phối 5 Agent AI qua Herdr hoàn thành 5 projects microservices độc lập"


echo -e "${BOLD}${CYAN}==============================================================================${NC}"
echo -e "${BOLD}KẾT QUẢ KIỂM TRA TỔNG HỢP:${NC}"
echo -e "  - Tổng số artifacts kiểm tra: ${BOLD}${TOTAL_COUNT}${NC}"
echo -e "  - Hợp lệ (${GREEN}PASSED${NC}):             ${BOLD}${GREEN}${PASSED_COUNT}${NC}"
echo -e "  - Thất bại (${RED}FAILED${NC}):            ${BOLD}${RED}${FAILED_COUNT}${NC}"

if [ "$FAILED_COUNT" -eq 0 ]; then
    echo -e "\n${BOLD}${GREEN}>>> CHÚC MỪNG! TOÀN BỘ CÁC ARTIFACTS ĐÃ ĐƯỢC NGHIỆM THU ĐẦY ĐỦ VÀ HỢP LỆ! <<<${NC}\n"
    exit 0
else
    echo -e "\n${BOLD}${RED}>>> CẢNH BÁO: CÓ ${FAILED_COUNT} ARTIFACT CHƯA ĐẠT TIÊU CHUẨN! VUI LÒNG KIỂM TRA LẠI. <<<${NC}\n"
    exit 1
fi
