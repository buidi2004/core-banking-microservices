#!/usr/bin/env bash
# ==============================================================================
# 📱 MOBILE FLUTTER APP CONTROL CLI (mobile/run.sh)
# Ứng dụng Ví điện tử Sen Hồng Bank - Flutter / Clean Architecture / Liquid Glass
# ==============================================================================
# Chức năng:
#   1. Quản lý vòng đời phát triển ứng dụng Mobile (Khởi chạy trên Device/Emulator/Web)
#   2. Cài đặt Dependencies (flutter pub get)
#   3. Phân tích mã nguồn tĩnh (flutter analyze) & Chạy Unit/Widget Tests
#   4. Đóng gói Release APK / AppBundle cho Android & Web
#   5. Kiểm tra kết nối mạng tới Backend Gateway & WebSocket
# ==============================================================================

set -e

MOBILE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$MOBILE_DIR/.." && pwd)"

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
    echo "  ███╗   ███╗ ██████╗ ██████╗ ██╗██╗     ███████╗"
    echo "  ████╗ ████║██╔═══██╗██╔══██╗██║██║     ██╔════╝"
    echo "  ██╔████╔██║██║   ██║██████╔╝██║██║     █████╗  "
    echo "  ██║╚██╔╝██║██║   ██║██╔══██╗██║██║     ██╔══╝  "
    echo "  ██║ ╚═╝ ██║╚██████╔╝██████╔╝██║███████╗███████╗"
    echo "  ╚═╝     ╚═╝ ╚═════╝ ╚═════╝ ╚═╝╚══════╝╚══════╝"
    echo -e "${NC}"
    echo -e " ${BOLD}BỘ ĐIỀU KHIỂN MOBILE FLUTTER (SEN HỒNG BANK E-WALLET)${NC}"
    echo -e " Kiến trúc: ${BLUE}Clean Architecture (50 Screens) + Liquid Glass Widgets${NC}"
    echo -e " ----------------------------------------------------------------------------------------"
}

# Kiểm tra công cụ Flutter trong PATH
check_flutter() {
    if ! command -v flutter &>/dev/null; then
        echo -e "\n${YELLOW}⚠️  KHÔNG TÌM THẤY FLUTTER SDK TRONG PATH HỆ THỐNG.${NC}"
        echo -e "👉 Để chạy ứng dụng Mobile trên máy này, bạn vui lòng:"
        echo -e "   1. Tải và cài đặt Flutter SDK: ${CYAN}https://docs.flutter.dev/get-started/install${NC}"
        echo -e "   2. Thêm thư mục flutter/bin vào biến môi trường PATH."
        echo -e "   3. Chạy lại script: ${BOLD}./run.sh dev${NC}\n"
        return 1
    fi
    return 0
}

# 1. Cài đặt dependencies (pub get)
cmd_deps() {
    print_banner
    if check_flutter; then
        echo -e "${BLUE}📥 Đang tải các thư viện dependencies (flutter pub get)...${NC}\n"
        cd "$MOBILE_DIR"
        flutter pub get
        echo -e "\n${GREEN}✓ Tải dependencies thành công!${NC}"
    fi
}

# Tự động forward cổng 8080 cho các máy ảo / thiết bị Android cắm vào
auto_adb_reverse() {
    if command -v adb &>/dev/null; then
        local devices
        devices=$(adb devices 2>/dev/null | awk 'NR>1 && $2=="device" {print $1}')
        for dev in $devices; do
            adb -s "$dev" reverse tcp:8080 tcp:8080 2>/dev/null || true
        done
    fi
}

# 2. Khởi chạy ứng dụng (Run)
cmd_run() {
    print_banner
    auto_adb_reverse
    if check_flutter; then
        echo -e "${BLUE}🚀 Đang khởi chạy ứng dụng Sen Hồng Bank...${NC}"
        cd "$MOBILE_DIR"
        flutter run "$@"
    fi
}

# 3. Khởi chạy trên trình duyệt Chrome (Web Mode)
cmd_run_chrome() {
    cmd_run -d chrome
}

# 4. Liệt kê thiết bị & emulators sẵn sàng
cmd_devices() {
    print_banner
    if check_flutter; then
        echo -e "${BLUE}📱 Danh sách các thiết bị & Emulators khả dụng:${NC}\n"
        cd "$MOBILE_DIR"
        flutter devices
    fi
}

# 5. Phân tích mã nguồn tĩnh (Linter & Analysis)
cmd_analyze() {
    print_banner
    if check_flutter; then
        echo -e "${BLUE}🔍 Đang phân tích mã nguồn (flutter analyze)...${NC}\n"
        cd "$MOBILE_DIR"
        flutter analyze
        echo -e "\n${GREEN}✓ Phân tích mã nguồn hoàn tất!${NC}"
    fi
}

# 6. Chạy Unit & Widget Tests
cmd_test() {
    print_banner
    if check_flutter; then
        echo -e "${BLUE}🧪 Đang thực thi các kịch bản kiểm thử Flutter Tests...${NC}\n"
        cd "$MOBILE_DIR"
        flutter test
        echo -e "\n${GREEN}✓ Kiểm thử Mobile hoàn tất thành công!${NC}"
    fi
}

# 7. Đóng gói Release APK (Android)
cmd_build_apk() {
    print_banner
    if check_flutter; then
        echo -e "${BLUE}📦 Đang đóng gói Android Release APK (flutter build apk --release)...${NC}\n"
        cd "$MOBILE_DIR"
        flutter build apk --release
        echo -e "\n${GREEN}✓ Đóng gói APK thành công!${NC}"
        echo -e "👉 File APK: ${BOLD}${CYAN}mobile/build/app/outputs/flutter-apk/app-release.apk${NC}"
    fi
}

# 8. Đóng gói AppBundle (Google Play)
cmd_build_bundle() {
    print_banner
    if check_flutter; then
        echo -e "${BLUE}📦 Đang đóng gói Android AppBundle (flutter build appbundle --release)...${NC}\n"
        cd "$MOBILE_DIR"
        flutter build appbundle --release
        echo -e "\n${GREEN}✓ Đóng gói AppBundle thành công!${NC}"
    fi
}

# 9. Đóng gói Web Release
cmd_build_web() {
    print_banner
    if check_flutter; then
        echo -e "${BLUE}📦 Đang đóng gói Web Production (flutter build web --release)...${NC}\n"
        cd "$MOBILE_DIR"
        flutter build web --release
        echo -e "\n${GREEN}✓ Đóng gói Web thành công! Thư mục: mobile/build/web/${NC}"
    fi
}

# 10. Dọn dẹp build cache
cmd_clean() {
    print_banner
    if check_flutter; then
        echo -e "${YELLOW}🧹 Đang dọn dẹp Flutter build cache (flutter clean)...${NC}"
        cd "$MOBILE_DIR"
        flutter clean
        flutter pub get
        echo -e "${GREEN}✓ Dọn dẹp cache hoàn tất!${NC}"
    fi
}

# 11. Kiểm tra kết nối tới Backend Core
cmd_be_check() {
    echo -e "\n${BOLD}${BLUE}🌐 KIỂM TRA ĐƯỜNG KẾT NỐI TỪ MOBILE ĐẾN BACKEND CORE:${NC}"
    echo -e " ----------------------------------------------------------------------------------------"
    
    # 1. API Gateway REST
    printf "  %-38s [Port  8080] : " "API Gateway REST (/api/v1)"
    if curl -s -m 2 http://localhost:8080/api/v1/auth/login -X POST -H "Content-Type: application/json" -d '{}' &>/dev/null || nc -z localhost 8080 2>/dev/null; then
        echo -e "${GREEN}● ONLINE (Gateway sẵn sàng đón request từ Mobile)${NC}"
    else
        echo -e "${RED}○ OFFLINE (Chưa chạy Backend Gateway)${NC}"
    fi

    # 2. WebSocket Server
    printf "  %-38s [Port  8080] : " "WebSocket Native (/ws-native)"
    if nc -z localhost 8080 2>/dev/null; then
        echo -e "${GREEN}● ONLINE (Sẵn sàng nhận Push Notifications)${NC}"
    else
        echo -e "${RED}○ OFFLINE${NC}"
    fi

    # 3. Trạng thái ADB Reverse cho Android Devices / Emulators
    echo -e "\n  ${BOLD}📱 Trạng thái Android ADB Reverse (Bridge Port 8080):${NC}"
    if command -v adb &>/dev/null; then
        local devices
        devices=$(adb devices 2>/dev/null | awk 'NR>1 && $2=="device" {print $1}')
        if [ -n "$devices" ]; then
            for dev in $devices; do
                adb -s "$dev" reverse tcp:8080 tcp:8080 &>/dev/null || true
                local rev_status
                rev_status=$(adb -s "$dev" reverse --list 2>/dev/null | grep "8080" || true)
                if [ -n "$rev_status" ]; then
                    echo -e "    • Thiết bị ${CYAN}$dev${NC}: ${GREEN}✔ Kích hoạt thành công (Dùng http://localhost:8080/api/v1)${NC}"
                else
                    echo -e "    • Thiết bị ${CYAN}$dev${NC}: ${YELLOW}⚠ Không hỗ trợ adb reverse (Dùng http://10.0.2.2:8080/api/v1)${NC}"
                fi
            done
        else
            echo -e "    ${YELLOW}Chưa phát hiện thiết bị Android / máy ảo nào đang cắm.${NC}"
        fi
    fi

    # 4. Thông tin IP cho Emulators
    echo -e "\n${BOLD}💡 THIẾT LẬP MẠNG CHO THIẾT BỊ / MÁY ẢO:${NC}"
    echo -e "  • ${CYAN}Android Emulator (adb reverse):${NC} Sử dụng endpoint: ${BOLD}http://localhost:8080/api/v1${NC}"
    echo -e "  • ${CYAN}Android Emulator (mặc định):${NC}    Sử dụng endpoint: ${BOLD}http://10.0.2.2:8080/api/v1${NC}"
    echo -e "  • ${CYAN}iOS Simulator:${NC}                  Sử dụng endpoint: ${BOLD}http://localhost:8080/api/v1${NC}"
    echo -e "  • ${CYAN}Thiết bị thật (LAN):${NC}              Sử dụng IP mạng nội bộ của máy chủ phát Wi-Fi."
    echo -e "  • Đổi URL trực tiếp trên app tại: ${YELLOW}Cài đặt hệ thống (config_screen.dart)${NC}"
}

# 12. Flutter Doctor
cmd_doctor() {
    print_banner
    if check_flutter; then
        flutter doctor
    fi
}

# Menu CLI Tương Tác
interactive_menu() {
    while true; do
        print_banner
        echo -e "  ${BOLD}VUI LÒNG CHỌN MỘT THAO TÁC:${NC}"
        echo -e "  ${GREEN}1.${NC} 🚀 ${BOLD}Khởi Chạy Ứng Dụng E-Wallet${NC} (flutter run)"
        echo -e "  ${GREEN}2.${NC} 🌐 ${BOLD}Chạy Thử Nghiệm Trên Chrome${NC} (flutter run -d chrome)"
        echo -e "  ${GREEN}3.${NC} 🌐 ${BOLD}Kiểm Tra Kết Nối Tới Backend Gateway${NC} (Port 8080 & WS)"
        echo -e "  ${GREEN}4.${NC} 📱 ${BOLD}Xem Danh Sách Thiết Bị / Emulators${NC} (flutter devices)"
        echo -e "  ${GREEN}5.${NC} 📥 ${BOLD}Tải & Cập Nhật Thư Viện Dependencies${NC} (flutter pub get)"
        echo -e "  ${GREEN}6.${NC} 🔍 ${BOLD}Kiểm Tra & Phân Tích Mã Nguồn${NC} (flutter analyze)"
        echo -e "  ${GREEN}7.${NC} 🧪 ${BOLD}Thực Thi Kịch Bản Kiểm Thử Unit/Widget${NC} (flutter test)"
        echo -e "  ${GREEN}8.${NC} 📦 ${BOLD}Đóng Gói Android Release APK${NC} (flutter build apk)"
        echo -e "  ${GREEN}9.${NC} 🩺 ${BOLD}Chạy Chẩn Đoán Hệ Thống${NC} (flutter doctor)"
        echo -e "  ${YELLOW}10.${NC} 🧹 ${BOLD}Dọn Dẹp Build Cache${NC} (flutter clean)"
        echo -e "  ${YELLOW}0.${NC} 🚪 ${BOLD}Thoát Menu${NC}"
        echo -e " ----------------------------------------------------------------------------------------"
        read -rp "👉 Nhập lựa chọn của bạn [0-10]: " choice

        case "$choice" in
            1) cmd_run; read -rp "Ấn Enter để tiếp tục..." ;;
            2) cmd_run_chrome; read -rp "Ấn Enter để tiếp tục..." ;;
            3) cmd_be_check; read -rp "Ấn Enter để tiếp tục..." ;;
            4) cmd_devices; read -rp "Ấn Enter để tiếp tục..." ;;
            5) cmd_deps; read -rp "Ấn Enter để tiếp tục..." ;;
            6) cmd_analyze; read -rp "Ấn Enter để tiếp tục..." ;;
            7) cmd_test; read -rp "Ấn Enter để tiếp tục..." ;;
            8) cmd_build_apk; read -rp "Ấn Enter để tiếp tục..." ;;
            9) cmd_doctor; read -rp "Ấn Enter để tiếp tục..." ;;
            10) cmd_clean; read -rp "Ấn Enter để tiếp tục..." ;;
            0) echo -e "\n${GREEN}Tạm biệt!${NC}"; exit 0 ;;
            *) echo -e "${RED}Lựa chọn không hợp lệ!${NC}"; sleep 1 ;;
        esac
    done
}

# Xử lý tham số dòng lệnh
COMMAND="${1:-menu}"

case "$COMMAND" in
    run|dev)
        shift 2>/dev/null || true
        cmd_run "$@"
        ;;
    chrome|web)
        cmd_run_chrome
        ;;
    deps|get)
        cmd_deps
        ;;
    devices)
        cmd_devices
        ;;
    analyze|lint)
        cmd_analyze
        ;;
    test)
        cmd_test
        ;;
    build:apk|apk)
        cmd_build_apk
        ;;
    build:bundle|bundle)
        cmd_build_bundle
        ;;
    build:web)
        cmd_build_web
        ;;
    clean)
        cmd_clean
        ;;
    be:check|status)
        cmd_be_check
        ;;
    index|cbm)
        echo -e "${YELLOW}🧠 Đang index đồ thị mã nguồn Mobile (core-banking-mobile)...${NC}"
        /home/buidi/.local/bin/codebase-memory-mcp cli index_repository --repo-path "$MOBILE_DIR" --name core-banking-mobile --persistence true
        echo -e "${GREEN}✔ Đã index xong Mobile vào Codebase Memory MCP!${NC}"
        ;;
    doctor)
        cmd_doctor
        ;;
    menu)
        interactive_menu
        ;;
    help|-h|--help)
        echo -e "${BOLD}CÁCH SỬ DỤNG SCRIPT MOBILE:${NC}"
        echo "  ./run.sh                  Mở Menu CLI tương tác"
        echo "  ./run.sh run [flags]      Khởi chạy ứng dụng (truyền tham số tự do)"
        echo "  ./run.sh chrome           Khởi chạy nhanh trên Google Chrome"
        echo "  ./run.sh deps             Cài đặt dependencies (flutter pub get)"
        echo "  ./run.sh devices          Liệt kê các máy ảo & thiết bị đang cắm"
        echo "  ./run.sh analyze          Phân tích tĩnh cú pháp mã nguồn"
        echo "  ./run.sh test             Chạy toàn bộ unit và widget tests"
        echo "  ./run.sh apk              Đóng gói file cài đặt Android Release APK"
        echo "  ./run.sh be:check         Kiểm tra kết nối mạng tới Backend Gateway"
        echo "  ./run.sh clean            Xóa sạch build cache"
        echo "  ./run.sh doctor           Kiểm tra cấu hình môi trường Flutter"
        ;;
    *)
        echo -e "${RED}Lệnh không hợp lệ: $COMMAND${NC}"
        echo "Gõ './run.sh help' để xem danh sách lệnh hỗ trợ."
        exit 1
        ;;
esac

