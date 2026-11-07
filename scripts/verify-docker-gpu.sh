#!/usr/bin/env bash
# ==============================================================================
# Sen Hong Bank - Script kiểm tra và xác thực Docker GPU (NVIDIA GTX 1650)
# ==============================================================================
set -euo pipefail

BOLD="\033[1m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
CYAN="\033[0;36m"
RED="\033[0;31m"
RESET="\033[0m"

echo -e "${BOLD}${CYAN}==============================================================================${RESET}"
echo -e "${BOLD}${CYAN}   SEN HONG BANK — DOCKER GPU (GTX 1650 / CUDA) VERIFICATION SUITE            ${RESET}"
echo -e "${BOLD}${CYAN}==============================================================================${RESET}\n"

# 1. Kiểm tra driver NVIDIA trên máy chủ
echo -e "${BOLD}[1/5] Kiểm tra NVIDIA Driver trên Host...${RESET}"
if command -v nvidia-smi &> /dev/null; then
    DRIVER_INFO=$(nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader)
    echo -e "  ${GREEN}✔ [PASS]${RESET} Phát hiện GPU: ${BOLD}${DRIVER_INFO}${RESET}"
else
    echo -e "  ${RED}✘ [FAIL]${RESET} Không tìm thấy lệnh 'nvidia-smi' trên host."
    exit 1
fi

# 2. Kiểm tra Docker NVIDIA Container Toolkit
echo -e "\n${BOLD}[2/5] Kiểm tra NVIDIA Container Toolkit trong Docker...${RESET}"
if docker info 2>/dev/null | grep -iq "nvidia"; then
    echo -e "  ${GREEN}✔ [PASS]${RESET} Docker Runtime hỗ trợ NVIDIA Toolkit thành công"
else
    echo -e "  ${YELLOW}⚠ [WARN]${RESET} Runtime 'nvidia' chưa xuất hiện rõ ràng trong 'docker info', kiểm tra tiếp trong container..."
fi

# 3. Kiểm tra Container ewallet-ekyc-ai-service
echo -e "\n${BOLD}[3/5] Kiểm tra Container ewallet-ekyc-ai-service...${RESET}"
if docker ps --format '{{.Names}}' | grep -q "^ewallet-ekyc-ai-service$"; then
    STATUS=$(docker inspect --format='{{.State.Status}}' ewallet-ekyc-ai-service)
    echo -e "  ${GREEN}✔ [PASS]${RESET} Container đang hoạt động: ${BOLD}${STATUS}${RESET}"
else
    echo -e "  ${RED}✘ [FAIL]${RESET} Container ewallet-ekyc-ai-service chưa chạy. Đang khởi động qua docker compose..."
    docker compose up -d ekyc-ai-service
fi

# 4. Kiểm tra GPU passthrough bên trong Container
echo -e "\n${BOLD}[4/5] Kiểm tra GPU Passthrough bên trong Docker Container...${RESET}"
CONTAINER_GPU=$(docker exec ewallet-ekyc-ai-service nvidia-smi --query-gpu=name,memory.used,memory.total --format=csv,noheader 2>/dev/null || true)
if [ -n "$CONTAINER_GPU" ]; then
    echo -e "  ${GREEN}✔ [PASS]${RESET} Container truy cập GPU trực tiếp: ${BOLD}${CONTAINER_GPU}${RESET}"
else
    echo -e "  ${RED}✘ [FAIL]${RESET} Container không nhận diện được GPU qua nvidia-smi."
    exit 1
fi

# 5. Kiểm tra Health & CUDAExecutionProvider từ Endpoint API
echo -e "\n${BOLD}[5/5] Kiểm tra API Health & CUDAExecutionProvider của AI Service...${RESET}"
HEALTH_JSON=$(curl -s http://localhost:8900/api/v1/ekyc/ai/health || true)
echo -e "  ${CYAN}Response:${RESET} ${HEALTH_JSON}"

if echo "$HEALTH_JSON" | grep -q "CUDAExecutionProvider"; then
    echo -e "  ${GREEN}✔ [PASS]${RESET} ${BOLD}ONNX Runtime đang chạy trên NVIDIA GPU với CUDAExecutionProvider thành công!${RESET}"
else
    echo -e "  ${RED}✘ [FAIL]${RESET} AI Service chưa chuyển sang CUDAExecutionProvider."
    exit 1
fi

echo -e "\n${BOLD}${GREEN}==============================================================================${RESET}"
echo -e "${BOLD}${GREEN}  DOCKER GPU (GTX 1650) ĐÃ ĐƯỢC THIẾT LẬP VÀ HOẠT ĐỘNG HOÀN HẢO!             ${RESET}"
echo -e "${BOLD}${GREEN}==============================================================================${RESET}\n"
