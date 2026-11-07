"""Cấu hình trung tâm cho ekyc-ai-service.

Tất cả giá trị đọc từ biến môi trường (khớp docker-compose), có mặc định an toàn
cho môi trường dev. Model path trỏ tới thư mục models/ trong service.
"""
from __future__ import annotations

import os
from functools import lru_cache
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

# ---------------------------------------------------------------------------
# ONNX / GPU
# ---------------------------------------------------------------------------

# CUDAExecutionProvider ưu tiên; rơi về CPU nếu GPU lỗi (log cảnh báo rõ ràng).
ONNX_PROVIDERS: list[str] = [
    p.strip()
    for p in os.getenv("EKYC_ONNX_PROVIDERS", "CUDAExecutionProvider,CPUExecutionProvider").split(",")
    if p.strip()
]

MODEL_DIR = Path(os.getenv("EKYC_MODEL_DIR", BASE_DIR / "models"))
DETECT_MODEL = os.getenv("EKYC_DETECT_MODEL", "det_10g.onnx")          # SCRFD-10G
RECOG_MODEL = os.getenv("EKYC_RECOG_MODEL", "w600k_r50.onnx")          # ArcFace r50 (512-d)
LIVENESS_MODEL = os.getenv("EKYC_LIVENESS_MODEL", "minifasnet_v2.onnx")  # MiniFASNetV2 anti-spoofing

# Ngưỡng so khớp cosine khởi điểm (tuần 8 tinh chỉnh từ log thực tế)
FACE_MATCH_THRESHOLD = float(os.getenv("EKYC_FACE_MATCH_THRESHOLD", "0.68"))
LIVENESS_THRESHOLD = float(os.getenv("EKYC_LIVENESS_THRESHOLD", "0.60"))

# ---------------------------------------------------------------------------
# Phiên & bảo mật
# ---------------------------------------------------------------------------

# TTL phiên eKYC: đủ ngắn chống replay, đủ dài cho luồng NFC + chụp ảnh
SESSION_TTL_SECONDS = int(os.getenv("EKYC_SESSION_TTL", "240"))  # 4 phút

REDIS_URL = os.getenv("EKYC_REDIS_URL", "redis://localhost:6379/2")

# Khóa RSA-OAEP 2048 để wrap khóa AES phiên (hybrid encryption).
# Private key chỉ tồn tại phía server; public key đóng gói vào mobile SDK.
RSA_PRIVATE_KEY_PATH = Path(os.getenv("EKYC_RSA_PRIVATE_KEY", BASE_DIR / "certs" / "ekyc_private.pem"))
RSA_PUBLIC_KEY_PATH = Path(os.getenv("EKYC_RSA_PUBLIC_KEY", BASE_DIR / "certs" / "ekyc_public.pem"))

# Giới hạn dung lượng payload giải mã (chống bomb): ảnh JPEG chân dung ~ tối đa 8MB
MAX_DECRYPTED_BYTES = int(os.getenv("EKYC_MAX_PAYLOAD_BYTES", str(8 * 1024 * 1024)))

# ---------------------------------------------------------------------------
# HTTP server
# ---------------------------------------------------------------------------

SERVICE_PORT = int(os.getenv("EKYC_PORT", "8900"))
LOG_LEVEL = os.getenv("EKYC_LOG_LEVEL", "INFO")

# Tích hợp Identity Service Webhook / Callback
IDENTITY_SERVICE_URL = os.getenv("IDENTITY_SERVICE_URL", "http://identity-service:8081")
INTERNAL_API_KEY = os.getenv("INTERNAL_API_KEY", "senhong-internal-ekyc-key-2026")


@lru_cache(maxsize=1)
def model_paths() -> tuple[Path, Path, Path]:
    """Đường dẫn tuyệt đối tới model detect, nhận dạng và anti-spoofing."""
    det = MODEL_DIR / DETECT_MODEL
    rec = MODEL_DIR / RECOG_MODEL
    liv = MODEL_DIR / LIVENESS_MODEL
    missing = [str(p) for p in (det, rec, liv) if not p.exists()]
    if missing:
        raise FileNotFoundError(f"Thiếu model ONNX: {missing}.")
    return det, rec, liv
